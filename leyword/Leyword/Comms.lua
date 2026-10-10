-- Guild transport. Score and colored grid only. Guessed words are never sent.
-- Messages stay under the 255 byte addon cap and are queued at one every 1.5s
-- so a sync cannot trip the client throttle.
Leyword = Leyword or {}

local PREFIX = "LEYWORD"
local queue = {}
local timerArmed = false

local ADDON_RESULT = {
  [0] = "addon channel accepted it",
  [1] = "addon prefix was rejected",
  [2] = "addon message was rejected",
  [3] = "addon channel is throttled",
  [4] = "addon channel was rejected",
  [10] = "the client says you are not in a guild",
  [11] = "addon chat is blocked in this zone",
  [12] = "that guildmate is offline",
}

local function RememberStatus(text)
  Leyword.syncStatus = text
  if Leyword.Refresh then
    Leyword.Refresh()
  end
end

local function PostChat(text)
  if type(text) ~= "string" or not IsInGuild() then
    return false
  end
  local now = time()
  if text == Leyword._lastChat and (now - (Leyword._lastChatAt or 0)) < 8 then
    return false
  end
  Leyword._lastChat = text
  Leyword._lastChatAt = now
  local ok, err
  if C_ChatInfo and C_ChatInfo.SendChatMessage then
    ok, err = pcall(C_ChatInfo.SendChatMessage, text, "GUILD")
  elseif SendChatMessage then
    ok, err = pcall(SendChatMessage, text, "GUILD")
  else
    RememberStatus("No guild chat function on this client.")
    return false
  end
  if not ok then
    RememberStatus("Guild chat could not send: " .. tostring(err))
    return false
  end
  RememberStatus("Said Leyword sync in guild chat.")
  return true
end

local function PingAddon(msg)
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
  elseif RegisterAddonMessagePrefix then
    RegisterAddonMessagePrefix(PREFIX)
  end
  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    RememberStatus("This client has no SendAddonMessage.")
    return false
  end
  local ok, result = pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "GUILD")
  local note
  if not ok then
    note = "SendAddonMessage error: " .. tostring(result)
  elseif type(result) == "number" and result ~= 0 then
    note = "SendAddonMessage: " .. (ADDON_RESULT[result] or ("code " .. tostring(result)))
    if C_ChatInfo.SendAddonMessageLogged then
      local ok2, result2 = pcall(C_ChatInfo.SendAddonMessageLogged, PREFIX, msg, "GUILD")
      if ok2 and (result2 == nil or result2 == 0) then
        note = note .. ". Logged addon channel accepted it."
      end
    end
  else
    note = "SendAddonMessage accepted. Your guildmate needs to press Sync too."
  end
  RememberStatus(note)
  return ok and (type(result) ~= "number" or result == 0)
end

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
      if item.chat == "GUILD" and (item.msg:sub(1, 4) == "1;V;" or item.msg:sub(1, 4) == "1|V|") then
        local note
        if not ok then
          note = "addon channel error"
        elseif type(result) == "number" and result ~= 0 then
          note = ADDON_RESULT[result] or ("addon channel code " .. tostring(result))
        else
          note = ADDON_RESULT[0]
        end
        RememberStatus((Leyword.syncStatus or "Sent on guild chat.") .. " " .. note .. ".")
      end
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

function Leyword.NameKey(sender)
  sender = tostring(sender or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  sender = sender:match("^%s*(.-)%s*$") or ""
  local spaced, _realm = sender:match("^(.- .*)%-([^ ]+)$")
  if spaced and spaced ~= "" then
    return spaced
  end
  local first, second = sender:match("^([^ ]+)%-([^ ]+)$")
  if first and second then
    local myRealm = GetRealmName()
    if myRealm and second:lower() == myRealm:lower() then
      return first
    end
    return first .. " " .. second
  end
  return sender
end

function Leyword.IsSelf(sender)
  local key = Leyword.NameKey(sender)
  if key == "" then
    return false
  end
  local function Same(other)
    if not other or other == "" then
      return false
    end
    other = Leyword.NameKey(other)
    if other:lower() == key:lower() then
      return true
    end
    local short = key:match("^(%S+)$")
    local long = other:match("^(%S+) ")
    if short and long and short:lower() == long:lower() then
      return true
    end
    return false
  end
  if Same(UnitName("player")) or Same(UnitFullName("player")) or Same(MyName()) then
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
  return string.format("1;R;%s;%s;%s;%s;%s", cur.date, score, won, table.concat(cur.states), Leyword.AddonVersion())
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

local function ScoreChat(cur)
  local rows = {}
  for i = 1, #cur.states do
    local row = (cur.states[i] or ""):gsub("[^GYB]", "")
    if #row == 5 then
      rows[#rows + 1] = row
    end
  end
  local expect = (cur.done == "win" and #cur.guesses or 6) * 5
  if #table.concat(rows) ~= expect then
    return nil
  end
  local label = cur.done == "win" and (#cur.guesses .. "/6") or "X/6"
  local _, number = Leyword.AnswerFor(cur.y, cur.m, cur.d)
  if number then
    return string.format("Leyword %d %s %s", number, label, table.concat(rows, " "))
  end
  return "Leyword " .. label .. " " .. table.concat(rows, " ")
end

local function AskChat(ymd)
  return "Leyword checking scores [LW1:1:Q:" .. ymd .. ":" .. Leyword.AddonVersion() .. "]"
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
  local line = ScoreChat(cur)
  if line then
    PostChat(line)
  end
end

function Leyword.SyncGuild(force)
  if not IsInGuild() then
    return
  end
  local now = time()
  if not force and (now - (LeywordDB.lastQuery or 0)) < 20 then
    return
  end
  LeywordDB.lastQuery = now
  local ok, y, m, d = pcall(Leyword.Today)
  if not ok or not y then
    return
  end
  local todayKey = Leyword.DateKey(y, m, d)
  local todayEntry = FinishedFor(todayKey)
  local cur = LeywordDB.current
  if (not todayEntry) and cur and not cur.extra and cur.done ~= "play" and cur.date == todayKey then
    todayEntry = cur
  end
  local ping = todayEntry and ResultMessage(todayEntry) or ("1;Q;" .. todayKey .. ";" .. Leyword.AddonVersion())
  PingAddon(ping)
  if force and todayEntry then
    local line = ScoreChat(todayEntry)
    if line then
      PostChat(line)
    end
  end
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
  if type(pattern) ~= "string" then
    RememberStatus(Leyword.NameKey(sender) .. " score dropped: bad grid")
    return
  end
  local letters = pattern:upper():gsub("[^GYB]", "")
  local keep = math.floor(#letters / 5) * 5
  if keep < 5 or keep > 30 then
    RememberStatus(Leyword.NameKey(sender) .. " score dropped: bad grid " .. pattern:sub(1, 24))
    return
  end
  pattern = letters:sub(1, keep)
  local rows = #pattern / 5
  if rows ~= math.floor(rows) or rows < 1 or rows > 6 then
    return
  end
  local wonBit = won == "1"
  if wonBit and (not scoreNum or scoreNum < 1 or scoreNum > 6) then
    scoreNum = rows
  end
  if not wonBit and rows < 1 then
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
  local key = Leyword.NameKey(sender)
  if key == "" then
    RememberStatus("Score arrived with no name.")
    return
  end
  local info = {
    score = wonBit and scoreNum or 0,
    won = wonBit,
    pattern = pattern,
    t = time(),
  }
  local function Write(bucketKey)
    LeywordDB.guild[bucketKey] = LeywordDB.guild[bucketKey] or {}
    local bucket = LeywordDB.guild[bucketKey]
    if not bucket[key] then
      local n = 0
      for _ in pairs(bucket) do
        n = n + 1
      end
      if n >= 80 then
        return
      end
    end
    bucket[key] = info
  end
  Write(ymd)
  if ok and ty then
    local age = Leyword.Rdn(ty, tm, td) - Leyword.Rdn(py, pm, pd)
    if age >= -1 and age <= 1 then
      Write(Leyword.DateKey(ty, tm, td))
    end
  end
  RememberStatus("Saved " .. key .. " " .. (wonBit and ((scoreNum or rows) .. "/6") or "X/6"))
  if Leyword.RefreshGuild then
    Leyword.RefreshGuild()
  end
end

local function ReplyTo(sender, ymd)
  if Leyword.IsSelf(sender) then
    return
  end
  local entry = FinishedFor(ymd)
  local cur = LeywordDB.current
  if (not entry) and cur and not cur.extra and cur.done ~= "play" and cur.date == ymd then
    entry = cur
  end
  if not entry then
    return
  end
  Leyword.Enqueue(ResultMessage(entry), "WHISPER", sender)
end

local function OnAddonMessage(_, message, distribution, sender)
  if type(message) ~= "string" or type(sender) ~= "string" or sender == "" then
    return
  end
  if sender:find("|", 1, true) then
    return
  end
  local who = Leyword.NameKey(sender)
  local sep = message:find(";", 1, true) and ";" or "|"
  local proto, kind, ymd, a, b, pattern, remoteVer = strsplit(sep, message)
  if proto ~= "1" then
    RememberStatus(who .. " sent an unknown addon message.")
    return
  end
  if kind == "V" then
    Leyword.NoteRemoteVersion(ymd)
    RememberStatus(who .. " is on " .. tostring(ymd))
    return
  end
  if type(ymd) ~= "string" or not ymd:match("^%d%d%d%d%d%d%d%d$") then
    RememberStatus(who .. " sent a message with no date.")
    return
  end
  if kind == "Q" then
    Leyword.NoteRemoteVersion(a)
    RememberStatus(who .. " asked for scores, but sent none.")
    ReplyTo(sender, ymd)
  elseif kind == "R" then
    Leyword.NoteRemoteVersion(remoteVer)
    StoreResult(sender, ymd, a, b, pattern)
  else
    RememberStatus(who .. " sent " .. tostring(kind))
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
    if Leyword.spy then
      print("|cffd4a85aLeyword spy|r " .. tostring(prefix) .. " " .. tostring(message) .. " via " .. tostring(distribution) .. " from " .. tostring(sender))
    end
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

local function ColoredRows(pattern)
  local palette = (Leyword.Palette and Leyword.Palette()) or (Leyword.Colors and Leyword.Colors.normal) or {
    G = { 0.247, 0.420, 0.271 },
    Y = { 0.651, 0.518, 0.184 },
    B = { 0.431, 0.369, 0.306 },
  }
  local lines = {}
  for i = 1, #pattern, 5 do
    local bits = {}
    for p = 0, 4 do
      local color = palette[pattern:sub(i + p, i + p)]
      if color then
        bits[#bits + 1] = string.format(
          "|TInterface\\Buttons\\WHITE8X8:8:8:1:0:8:8:0:8:0:8:%d:%d:%d|t",
          math.floor(color[1] * 255 + 0.5),
          math.floor(color[2] * 255 + 0.5),
          math.floor(color[3] * 255 + 0.5)
        )
      end
    end
    lines[#lines + 1] = table.concat(bits)
  end
  return table.concat(lines, " ")
end

local function IngestGuildLine(msg, sender)
  if type(msg) ~= "string" or msg:sub(1, 8) ~= "Leyword " then
    return nil
  end
  local number, label, rest = msg:match("^Leyword (%d+) ([%dX]/6)%s+([GYB ]+)$")
  if not label then
    label, rest = msg:match("^Leyword ([%dX]/6)%s+([GYB ]+)$")
  end
  if not label or not rest then
    return nil
  end
  local rows = {}
  for token in rest:gmatch("[GYB]+") do
    if #token == 5 then
      rows[#rows + 1] = token
    end
  end
  if #rows < 1 then
    return nil
  end
  local pattern = table.concat(rows)
  local scoreNum = tonumber(label:match("^(%d)/6$"))
  local won = scoreNum and "1" or "0"
  local score = scoreNum and tostring(scoreNum) or "0"
  local ymd
  if number and Leyword.YmdFromNumber then
    local y, m, d = Leyword.YmdFromNumber(tonumber(number))
    if y then
      ymd = Leyword.DateKey(y, m, d)
    end
  end
  if not ymd then
    local ok, y, m, d = pcall(Leyword.Today)
    if ok and y then
      ymd = Leyword.DateKey(y, m, d)
    end
  end
  if ymd and type(sender) == "string" and sender ~= "" and not sender:find("|", 1, true) then
    StoreResult(sender, ymd, score, won, pattern)
  end
  local head = number and ("Leyword " .. number .. " " .. label) or ("Leyword " .. label)
  return head .. " " .. ColoredRows(pattern)
end

function Leyword.PingDebug()
  local function report(label, ok, result)
    if not ok then
      print("|cffd4a85aLeyword ping|r " .. label .. " error: " .. tostring(result))
    else
      print("|cffd4a85aLeyword ping|r " .. label .. " result " .. tostring(result))
    end
  end
  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then
    print("|cffd4a85aLeyword ping|r no SendAddonMessage on this client.")
    return
  end
  if C_ChatInfo.RegisterAddonMessagePrefix then
    print("|cffd4a85aLeyword ping|r register " .. tostring(C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)))
  end
  local msg = "1;V;" .. Leyword.AddonVersion()
  report("GUILD", pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "GUILD"))
  report("WHISPER self", pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "WHISPER", UnitName("player")))
  local id = GetChannelName and GetChannelName("leyword")
  if type(id) == "number" and id > 0 then
    report("CHANNEL", pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "CHANNEL", id))
  else
    print("|cffd4a85aLeyword ping|r CHANNEL skipped. /join leyword then /lw ping again.")
  end
end

if ChatFrame_AddMessageEventFilter then
  ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", function(_, _, msg, sender, ...)
    local colored = IngestGuildLine(msg, sender)
    if not colored then
      return false
    end
    return false, colored, sender, ...
  end)
end

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
  C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
elseif RegisterAddonMessagePrefix then
  RegisterAddonMessagePrefix(PREFIX)
end
