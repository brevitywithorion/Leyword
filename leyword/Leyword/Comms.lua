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
  if Leyword.PublishNote then
    Leyword.PublishNote()
  end
end

function Leyword.RequestSync()
  if not IsInGuild() then
    return
  end
  local now = time()
  if (now - (LeywordDB.lastQuery or 0)) >= 20 then
    LeywordDB.lastQuery = now
    local cur = Leyword.EnsureToday()
    Leyword.Enqueue("1|Q|" .. cur.date, "GUILD")
    if cur.done ~= "play" then
      local msg = ResultMessage(cur)
      Leyword.Enqueue(msg, "GUILD")
      cur.shared = true
    end
  end
  if Leyword.ReadRosterNotes then
    Leyword.ReadRosterNotes()
  end
  if Leyword.PublishNote then
    Leyword.PublishNote()
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

local ALPH = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

local function AlphIndex(char)
  local index = ALPH:find(char, 1, true)
  if not index then
    return nil
  end
  return index - 1
end

local function EncodeRow(state)
  local value = 0
  for i = 1, 5 do
    local mark = state:sub(i, i)
    local n = mark == "G" and 0 or (mark == "Y" and 1 or 2)
    value = value * 3 + n
  end
  return ALPH:sub(math.floor(value / 62) + 1, math.floor(value / 62) + 1) .. ALPH:sub((value % 62) + 1, (value % 62) + 1)
end

local function DecodeRow(text)
  local hi = AlphIndex(text:sub(1, 1))
  local lo = AlphIndex(text:sub(2, 2))
  if not hi or not lo then
    return nil
  end
  local value = hi * 62 + lo
  if value > 242 then
    return nil
  end
  local marks = {}
  for _, place in ipairs({ 81, 27, 9, 3, 1 }) do
    local n = math.floor(value / place)
    value = value % place
    marks[#marks + 1] = n == 0 and "G" or (n == 1 and "Y" or "B")
  end
  return table.concat(marks)
end

local function NoteFor(cur)
  local _, number = Leyword.AnswerFor(cur.y, cur.m, cur.d)
  local packed = {}
  for i = 1, #cur.states do
    if #cur.states[i] ~= 5 then
      return nil
    end
    packed[#packed + 1] = EncodeRow(cur.states[i])
  end
  local score = cur.done == "win" and tostring(#cur.guesses) or "0"
  return string.format("LW%d:%s:%s", number, score, table.concat(packed))
end

local function AskRoster()
  if C_GuildInfo and C_GuildInfo.GuildRoster then
    pcall(C_GuildInfo.GuildRoster)
  elseif GuildRoster then
    pcall(GuildRoster)
  end
end

local function WritePublicNote(index, note)
  if GuildRosterSetPublicNote and pcall(GuildRosterSetPublicNote, index, note) then
    return true
  end
  if C_GuildInfo and C_GuildInfo.SetNote then
    local guid = UnitGUID("player")
    if guid and pcall(C_GuildInfo.SetNote, guid, note, true) then
      return true
    end
    if pcall(C_GuildInfo.SetNote, index, note, true) then
      return true
    end
  end
  return false
end

function Leyword.PublishNote()
  if not IsInGuild() or not GetNumGuildMembers or not GetGuildRosterInfo then
    return
  end
  local cur = LeywordDB.current
  if not cur or cur.done == "play" then
    return
  end
  local note = NoteFor(cur)
  if not note or #note > 31 then
    return
  end
  local count = GetNumGuildMembers()
  for i = 1, count do
    local name, _, _, _, _, _, publicNote = GetGuildRosterInfo(i)
    if name and Leyword.IsSelf(name) then
      if publicNote == note then
        return
      end
      if type(publicNote) == "string" and publicNote ~= "" and not publicNote:match("^LW%d+:%d:[0-9A-Za-z]+$") then
        return
      end
      WritePublicNote(i, note)
      return
    end
  end
end

function Leyword.ReadRosterNotes()
  if not IsInGuild() or not GetNumGuildMembers or not GetGuildRosterInfo or not Leyword.YmdFromNumber then
    return
  end
  local count = GetNumGuildMembers()
  for i = 1, count do
    local name, _, _, _, _, _, publicNote = GetGuildRosterInfo(i)
    if name and type(publicNote) == "string" then
      local number, score, packed = publicNote:match("^LW(%d+):(%d):([0-9A-Za-z]+)$")
      if number and packed and #packed % 2 == 0 and #packed >= 2 and #packed <= 12 then
        local pattern = {}
        local valid = true
        for pos = 1, #packed, 2 do
          local row = DecodeRow(packed:sub(pos, pos + 1))
          if not row then
            valid = false
            break
          end
          pattern[#pattern + 1] = row
        end
        if valid then
          local y, m, d = Leyword.YmdFromNumber(tonumber(number))
          if y then
            local won = score == "0" and "0" or "1"
            StoreResult(name, Leyword.DateKey(y, m, d), score, won, table.concat(pattern))
          end
        end
      end
    end
  end
end

local listener = CreateFrame("Frame")
local rosterWait = false
listener:RegisterEvent("CHAT_MSG_ADDON")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("GUILD_ROSTER_UPDATE")
listener:SetScript("OnEvent", function(_, event, prefix, message, distribution, sender)
  if event == "CHAT_MSG_ADDON" then
    if prefix ~= PREFIX then
      return
    end
    OnAddonMessage(prefix, message, distribution, sender)
    return
  end
  if event == "PLAYER_LOGIN" then
    AskRoster()
    C_Timer.After(3, function()
      if Leyword.RequestSync then
        Leyword.RequestSync()
      end
    end)
    return
  end
  if rosterWait then
    return
  end
  rosterWait = true
  C_Timer.After(1.5, function()
    rosterWait = false
    if Leyword.ReadRosterNotes then
      Leyword.ReadRosterNotes()
    end
    if Leyword.PublishNote then
      Leyword.PublishNote()
    end
  end)
end)
