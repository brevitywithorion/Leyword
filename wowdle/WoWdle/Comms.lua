-- Guild transport. Score and colored grid only. Guessed words are never sent.
-- Messages stay under the 255 byte addon cap and are queued at one every 1.5s
-- so a sync cannot trip the client throttle.
WoWdle = WoWdle or {}

local PREFIX = "WOWDLE"
local queue = {}
local timerArmed = false

local function Arm(delay)
  if timerArmed then
    return
  end
  timerArmed = true
  C_Timer.After(delay, function()
    timerArmed = false
    local item = table.remove(queue, 1)
    if not item then
      return
    end
    local nextDelay = 1.5
    local drop = item.chat == "GUILD" and not IsInGuild()
    if not drop then
      local ok, result = pcall(C_ChatInfo.SendAddonMessage, PREFIX, item.msg, item.chat, item.target)
      local throttled = ok
        and Enum
        and Enum.SendAddonMessageResult
        and result == Enum.SendAddonMessageResult.AddonMessageThrottle
      if throttled and item.tries < 4 then
        item.tries = item.tries + 1
        table.insert(queue, 1, item)
        nextDelay = 2.5
      end
    end
    if #queue > 0 then
      Arm(nextDelay)
    end
  end)
end

function WoWdle.Enqueue(msg, chat, target)
  if type(msg) ~= "string" or #msg > 250 or #queue >= 30 then
    return false
  end
  queue[#queue + 1] = { msg = msg, chat = chat, target = target, tries = 0 }
  Arm(0.1)
  return true
end

local function MyName()
  local name, realm = UnitFullName("player")
  if not realm or realm == "" then
    realm = GetRealmName()
  end
  return (name or "") .. "-" .. (realm or "")
end

function WoWdle.IsSelf(sender)
  local full = MyName()
  if sender == full then
    return true
  end
  local short = sender:match("^[^-]+")
  local mine = full:match("^[^-]+")
  local myRealm = full:match("^[^%-]+%-(.+)$")
  local theirRealm = sender:match("^[^%-]+%-(.+)$")
  if short and short == mine and (not theirRealm or theirRealm == myRealm) then
    return true
  end
  return false
end

function WoWdle.PruneGuild()
  if type(WoWdleDB) ~= "table" or type(WoWdleDB.guild) ~= "table" then
    return
  end
  local ok, y, m, d = pcall(WoWdle.Today)
  if not ok or not y or not d then
    return
  end
  local today = WoWdle.Rdn(y, m, d)
  for key in pairs(WoWdleDB.guild) do
    local yy, mm, dd = tostring(key):match("^(%d%d%d%d)(%d%d)(%d%d)$")
    if not yy then
      WoWdleDB.guild[key] = nil
    else
      local age = today - WoWdle.Rdn(tonumber(yy), tonumber(mm), tonumber(dd))
      if age > 14 or age < -1 then
        WoWdleDB.guild[key] = nil
      end
    end
  end
end

local function ResultMessage(cur)
  local won = cur.done == "win" and "1" or "0"
  local score = cur.done == "win" and tostring(#cur.guesses) or "0"
  return string.format("1|R|%s|%s|%s|%s", cur.date, score, won, table.concat(cur.states))
end

function WoWdle.BroadcastResult()
  local cur = WoWdleDB.current
  if not cur or cur.done == "play" or not IsInGuild() then
    return
  end
  local msg = ResultMessage(cur)
  if WoWdle.Enqueue(msg, "GUILD") then
    cur.shared = true
  end
end

function WoWdle.RequestSync()
  if not IsInGuild() then
    return
  end
  local now = time()
  if (now - (WoWdleDB.lastQuery or 0)) >= 300 then
    WoWdleDB.lastQuery = now
    local cur = WoWdle.EnsureToday()
    WoWdle.Enqueue("1|Q|" .. cur.date, "GUILD")
  end
  local cur = WoWdleDB.current
  if cur and cur.done ~= "play" and not cur.shared then
    WoWdle.BroadcastResult()
  end
end

local function StoreResult(sender, ymd, score, won, pattern)
  local scoreNum = tonumber(score)
  if won ~= "0" and won ~= "1" then
    return
  end
  if type(pattern) ~= "string" or not pattern:match("^([GYB][GYB][GYB][GYB][GYB])+$") then
    return
  end
  local rows = #pattern / 5
  if rows ~= math.floor(rows) or rows < 1 or rows > 6 then
    return
  end
  local wonBit = won == "1"
  if wonBit then
    if scoreNum ~= rows or scoreNum < 1 or scoreNum > 6 then
      return
    end
    if pattern:sub(-5) ~= "GGGGG" then
      return
    end
  elseif scoreNum ~= 0 or rows ~= 6 or pattern:sub(-5) == "GGGGG" then
    return
  end
  local py, pm, pd = WoWdle.ParseKey(ymd)
  if not py then
    return
  end
  local ok, ty, tm, td = pcall(WoWdle.Today)
  if ok and ty then
    local age = WoWdle.Rdn(ty, tm, td) - WoWdle.Rdn(py, pm, pd)
    if age > 14 or age < -1 then
      return
    end
  end
  WoWdleDB.guild[ymd] = WoWdleDB.guild[ymd] or {}
  local bucket = WoWdleDB.guild[ymd]
  if not bucket[sender] then
    local n = 0
    for _ in pairs(bucket) do
      n = n + 1
    end
    if n >= 80 then
      return
    end
  end
  bucket[sender] = {
    score = wonBit and scoreNum or 0,
    won = wonBit,
    pattern = pattern,
    t = time(),
  }
  if WoWdle.Refresh then
    WoWdle.Refresh()
  end
end

local function ReplyTo(sender, ymd)
  if WoWdle.IsSelf(sender) then
    return
  end
  local cur = WoWdleDB.current
  if not cur or cur.date ~= ymd or cur.done == "play" then
    return
  end
  WoWdle._replied = WoWdle._replied or {}
  local key = sender .. ":" .. ymd
  if WoWdle._replied[key] then
    return
  end
  WoWdle._replied[key] = true
  WoWdle.Enqueue(ResultMessage(cur), "WHISPER", sender)
end

local function OnAddonMessage(_, message, distribution, sender)
  if distribution ~= "GUILD" and distribution ~= "WHISPER" then
    return
  end
  if type(message) ~= "string" or type(sender) ~= "string" or sender == "" then
    return
  end
  if sender:find("|", 1, true) then
    return
  end
  local ver, kind, ymd, a, b, pattern = strsplit("|", message)
  if ver ~= "1" or type(ymd) ~= "string" or not ymd:match("^%d%d%d%d%d%d%d%d$") then
    return
  end
  if kind == "Q" and distribution == "GUILD" then
    ReplyTo(sender, ymd)
  elseif kind == "R" then
    StoreResult(sender, ymd, a, b, pattern)
  end
end

local listener = CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:SetScript("OnEvent", function(_, _, prefix, message, distribution, sender)
  if prefix ~= PREFIX then
    return
  end
  OnAddonMessage(prefix, message, distribution, sender)
end)
