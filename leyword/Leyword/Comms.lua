-- Guild transport. Score and colored grid only. Guessed words are never sent.
-- Messages stay under the 255 byte addon cap and are queued at one every 1.5s
-- so a sync cannot trip the client throttle.
Leyword = Leyword or {}

local PREFIX = "LEYWORD"
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

function Leyword.Enqueue(msg, chat, target)
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

function Leyword.IsSelf(sender)
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

function Leyword.PruneGuild()
  if type(LeywordDB) ~= "table" or type(LeywordDB.guild) ~= "table" then
    return
  end
  local ok, y, m, d = pcall(Leyword.Today)
  if not ok or not y or not d then
    return
  end
  local today = Leyword.Rdn(y, m, d)
  for key in pairs(LeywordDB.guild) do
    local yy, mm, dd = tostring(key):match("^(%d%d%d%d)(%d%d)(%d%d)$")
    if not yy then
      LeywordDB.guild[key] = nil
    else
      local age = today - Leyword.Rdn(tonumber(yy), tonumber(mm), tonumber(dd))
      if age > 14 or age < -1 then
        LeywordDB.guild[key] = nil
      end
    end
  end
end

local function ResultMessage(cur)
  local won = cur.done == "win" and "1" or "0"
  local score = cur.done == "win" and tostring(#cur.guesses) or "0"
  return string.format("1|R|%s|%s|%s|%s", cur.date, score, won, table.concat(cur.states))
end

function Leyword.BroadcastResult()
  local cur = LeywordDB.current
  if not cur or cur.done == "play" or not IsInGuild() then
    return
  end
  local msg = ResultMessage(cur)
  if Leyword.Enqueue(msg, "GUILD") then
    cur.shared = true
  end
end

function Leyword.RequestSync()
  if not IsInGuild() then
    return
  end
  local now = time()
  if (now - (LeywordDB.lastQuery or 0)) >= 300 then
    LeywordDB.lastQuery = now
    local cur = Leyword.EnsureToday()
    Leyword.Enqueue("1|Q|" .. cur.date, "GUILD")
  end
  local cur = LeywordDB.current
  if cur and cur.done ~= "play" and not cur.shared then
    Leyword.BroadcastResult()
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
  local py, pm, pd = Leyword.ParseKey(ymd)
  if not py then
    return
  end
  local ok, ty, tm, td = pcall(Leyword.Today)
  if ok and ty then
    local age = Leyword.Rdn(ty, tm, td) - Leyword.Rdn(py, pm, pd)
    if age > 14 or age < -1 then
      return
    end
  end
  LeywordDB.guild[ymd] = LeywordDB.guild[ymd] or {}
  local bucket = LeywordDB.guild[ymd]
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
  if Leyword.Refresh then
    Leyword.Refresh()
  end
end

local function ReplyTo(sender, ymd)
  if Leyword.IsSelf(sender) then
    return
  end
  local cur = LeywordDB.current
  if not cur or cur.date ~= ymd or cur.done == "play" then
    return
  end
  Leyword._replied = Leyword._replied or {}
  local key = sender .. ":" .. ymd
  if Leyword._replied[key] then
    return
  end
  Leyword._replied[key] = true
  Leyword.Enqueue(ResultMessage(cur), "WHISPER", sender)
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
