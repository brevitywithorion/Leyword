-- Guild transport. Score and colored grid only. Guessed words are never sent.
-- Messages stay under the 255 byte addon cap and are queued at one every 1.5s
-- so a sync cannot trip the client throttle.
Leyword = Leyword or {}

local PREFIX = "LEYWORD"
local queue = {}
local timerArmed = false

local function Transmit(msg, chatType, target)
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
  elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(PREFIX)
  end
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then
    if target then
      return C_ChatInfo.SendAddonMessage(PREFIX, msg, chatType, target)
    end
    return C_ChatInfo.SendAddonMessage(PREFIX, msg, chatType)
  end
  if SendAddonMessage then
    if target then
      return SendAddonMessage(PREFIX, msg, chatType, target)
    end
    return SendAddonMessage(PREFIX, msg, chatType)
  end
end

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
      local ok, result = pcall(Transmit, item.msg, item.chat, item.target)
      local failed = (not ok) or (type(result) == "number" and result ~= 0)
      if failed and item.tries < 6 then
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
  if type(msg) ~= "string" or #msg > 250 or #queue >= 60 then
    return false
  end
  queue[#queue + 1] = { msg = msg, chat = chat, target = target, tries = 0 }
  Arm(0.1)
  return true
end

function Leyword.AddonVersion()
  local version
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    version = C_AddOns.GetAddOnMetadata("Leyword", "Version")
  elseif GetAddOnMetadata then
    version = GetAddOnMetadata("Leyword", "Version")
  end
  if type(version) ~= "string" or version == "" then
    return "0"
  end
  return version
end

local function VersionParts(version)
  local major, minor, patch = tostring(version):match("^(%d+)%.(%d+)%.(%d+)")
  return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
end

function Leyword.NoteRemoteVersion(remote)
  if type(remote) ~= "string" then
    return
  end
  local a, b, c = VersionParts(remote)
  local x, y, z = VersionParts(Leyword.AddonVersion())
  local newer = a > x or (a == x and b > y) or (a == x and b == y and c > z)
  if not newer then
    return
  end
  local first = not Leyword.outdated
  Leyword.outdated = remote
  if first and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37Leyword|r is out of date. A guildmate has " .. remote .. ". Update on CurseForge.")
  end
  if Leyword.Refresh then
    Leyword.Refresh()
  end
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
  return string.format("1|R|%s|%s|%s|%s|%s", cur.date, score, won, table.concat(cur.states), Leyword.AddonVersion())
end

local function FinishedFor(ymd)
  local cur = LeywordDB.current
  if cur and cur.date == ymd and not cur.extra and cur.done ~= "play" then
    return cur
  end
  local history = LeywordDB.history
  if type(history) ~= "table" then
    return nil
  end
  for i = 1, #history do
    local entry = history[i]
    if entry and entry.date == ymd and not entry.extra and entry.done ~= "play" then
      return entry
    end
  end
  return nil
end

function Leyword.BroadcastResult()
  if not IsInGuild() then
    return
  end
  local cur = LeywordDB.current
  if not cur or cur.extra or cur.done == "play" then
    return
  end
  if Leyword.Enqueue(ResultMessage(cur), "GUILD") then
    cur.shared = true
  end
end

function Leyword.SyncGuild()
  if not IsInGuild() then
    return
  end
  local now = time()
  if (now - (LeywordDB.lastQuery or 0)) < 20 then
    return
  end
  LeywordDB.lastQuery = now
  Leyword.Enqueue("1|V|" .. Leyword.AddonVersion(), "GUILD")
  local ok, y, m, d = pcall(Leyword.Today)
  if not ok or not y then
    return
  end
  local todayKey = Leyword.DateKey(y, m, d)
  local todayEntry = FinishedFor(todayKey)
  if todayEntry then
    Leyword.Enqueue(ResultMessage(todayEntry), "GUILD")
  end
  Leyword.Enqueue("1|Q|" .. todayKey .. "|" .. Leyword.AddonVersion(), "GUILD")
  local _, number = Leyword.AnswerFor(y, m, d)
  for age = 1, 14 do
    local py, pm, pd = Leyword.YmdFromNumber(number - age)
    if py then
      local entry = FinishedFor(Leyword.DateKey(py, pm, pd))
      if entry then
        Leyword.Enqueue(ResultMessage(entry), "GUILD")
      end
    end
  end
  if todayEntry and GetNumGuildMembers and GetGuildRosterInfo then
    local count = GetNumGuildMembers()
    for i = 1, count do
      local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
      if type(name) == "string" and isOnline and not Leyword.IsSelf(name) then
        Leyword.Enqueue(ResultMessage(todayEntry), "WHISPER", name)
      end
    end
  end
end

function Leyword.RequestSync()
  Leyword.SyncGuild()
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
  local entry = FinishedFor(ymd)
  if not entry then
    return
  end
  Leyword.Enqueue(ResultMessage(entry), "WHISPER", sender)
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
  local proto, kind, ymd, a, b, pattern, remoteVer = strsplit("|", message)
  if proto ~= "1" then
    return
  end
  if kind == "V" then
    Leyword.NoteRemoteVersion(ymd)
    return
  end
  if type(ymd) ~= "string" or not ymd:match("^%d%d%d%d%d%d%d%d$") then
    return
  end
  if kind == "Q" then
    Leyword.NoteRemoteVersion(a)
    ReplyTo(sender, ymd)
  elseif kind == "R" then
    Leyword.NoteRemoteVersion(remoteVer)
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
  return
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
local knownOnline
local memberSync
local function NoteArrivals()
  if not IsInGuild() or not GetNumGuildMembers or not GetGuildRosterInfo then
    return false
  end
  local count = GetNumGuildMembers()
  if count < 1 then
    return false
  end
  local nowOnline = {}
  local arrived = false
  for i = 1, count do
    local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
    if name and isOnline then
      nowOnline[name] = true
      if knownOnline and not knownOnline[name] and not Leyword.IsSelf(name) then
        arrived = true
      end
    end
  end
  knownOnline = nowOnline
  return arrived
end
local function ScheduleSync()
  if memberSync then
    return
  end
  memberSync = true
  C_Timer.After(2, function()
    memberSync = false
    LeywordDB.lastQuery = 0
    if Leyword.SyncGuild then
      Leyword.SyncGuild()
    end
  end)
end
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
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
      C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    elseif RegisterAddonMessagePrefix then
      RegisterAddonMessagePrefix(PREFIX)
    end
    AskRoster()
    C_Timer.After(3, ScheduleSync)
    C_Timer.After(20, ScheduleSync)
    C_Timer.After(60, ScheduleSync)
    C_Timer.NewTicker(900, function()
      AskRoster()
      ScheduleSync()
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
    if NoteArrivals() then
      ScheduleSync()
    end
  end)
end)
