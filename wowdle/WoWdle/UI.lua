WoWdle = WoWdle or {}

WoWdle.Colors = {
  normal = {
    G = { 0.247, 0.420, 0.271 },
    Y = { 0.651, 0.518, 0.184 },
    B = { 0.431, 0.369, 0.306 },
  },
  colorblind = {
    G = { 0.176, 0.369, 0.722 },
    Y = { 0.784, 0.482, 0.133 },
    B = { 0.431, 0.369, 0.306 },
  },
}

function WoWdle.Palette()
  if WoWdleDB and WoWdleDB.settings and WoWdleDB.settings.colorblind then
    return WoWdle.Colors.colorblind
  end
  return WoWdle.Colors.normal
end

local function Hex(c)
  return string.format("%02x%02x%02x", math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

function WoWdle.ApplyTile(tile, letter, mark)
  tile.letter:SetText(letter or "")
  local color = mark and WoWdle.Palette()[mark]
  if color then
    tile:SetBackdropColor(color[1], color[2], color[3], 1)
    tile:SetBackdropBorderColor(color[1] * 0.55, color[2] * 0.55, color[3] * 0.55, 1)
    tile.letter:SetTextColor(0.96, 0.94, 0.88)
  else
    tile:SetBackdropColor(0.18, 0.13, 0.08, 0.55)
    tile:SetBackdropBorderColor(0.45, 0.36, 0.22, 1)
    tile.letter:SetTextColor(0.28, 0.2, 0.12)
  end
end

function WoWdle.ApplyKey(button, mark)
  local tex = button:GetNormalTexture()
  local label = button:GetFontString()
  if mark then
    local color = WoWdle.Palette()[mark]
    if tex then
      tex:SetVertexColor(color[1] + 0.35, color[2] + 0.35, color[3] + 0.35)
    end
    if label then
      label:SetTextColor(0.16, 0.11, 0.07)
    end
  else
    if tex then
      tex:SetVertexColor(1, 1, 1)
    end
    if label then
      label:SetFontObject(GameFontNormalSmall)
    end
  end
end

local function Swatch(mark)
  local color = WoWdle.Palette()[mark]
  if not color then
    return ""
  end
  return string.format(
    "|TInterface\\Buttons\\WHITE8X8:8:8:1:0:8:8:0:8:0:8:%d:%d:%d|t",
    math.floor(color[1] * 255 + 0.5),
    math.floor(color[2] * 255 + 0.5),
    math.floor(color[3] * 255 + 0.5)
  )
end

local function GridText(pattern)
  local lines = {}
  for i = 1, #pattern, 5 do
    local bits = {}
    for p = 0, 4 do
      bits[#bits + 1] = Swatch(pattern:sub(i + p, i + p))
    end
    lines[#lines + 1] = table.concat(bits)
  end
  return table.concat(lines, "\n")
end

local function ShortName(sender)
  sender = tostring(sender or ""):gsub("|", "")
  if Ambiguate then
    return Ambiguate(sender, "short")
  end
  return sender:match("^[^-]+") or sender
end

local function CheckText(button, text)
  local font = button.Text or (button.GetName and _G[button:GetName() .. "Text"])
  if font then
    font:SetText(text)
    font:SetFontObject(GameFontNormal)
  end
end

local function AddEscape(name)
  for i = 1, #UISpecialFrames do
    if UISpecialFrames[i] == name then
      return
    end
  end
  UISpecialFrames[#UISpecialFrames + 1] = name
end

function WoWdle.ShareLines()
  local cur = WoWdleDB.current
  if not cur or cur.done ~= "win" then
    return nil
  end
  local _, number = WoWdle.AnswerFor(cur.y, cur.m, cur.d)
  local pal = WoWdle.Palette()
  local lines = { string.format("Leyword %d %d/6", number, #cur.guesses) }
  local chunk = {}
  for i = 1, #cur.states do
    local bits = {}
    for p = 1, 5 do
      local mark = cur.states[i]:sub(p, p)
      bits[p] = "|cff" .. Hex(pal[mark]) .. mark .. "|r"
    end
    chunk[#chunk + 1] = table.concat(bits)
    if #chunk == 3 or i == #cur.states then
      lines[#lines + 1] = table.concat(chunk, " ")
      chunk = {}
    end
  end
  lines[#lines + 1] = "Don't have Leyword? Install the addon to play today's word."
  return lines
end

local shareQueue = {}
local sharePumping = false

local function PumpShare()
  sharePumping = false
  local item = table.remove(shareQueue, 1)
  if not item then
    return
  end
  SendChatMessage(item.text, item.kind, nil, item.target)
  if #shareQueue > 0 and C_Timer and C_Timer.After then
    sharePumping = true
    C_Timer.After(0.35, PumpShare)
  else
    for i = 1, #shareQueue do
      local nextItem = shareQueue[i]
      SendChatMessage(nextItem.text, nextItem.kind, nil, nextItem.target)
    end
    wipe(shareQueue)
  end
end

function WoWdle.ShareTo(kind)
  local lines = WoWdle.ShareLines()
  if not lines then
    return "Solve today's word first."
  end
  local target
  if kind == "WHISPER" then
    if not UnitExists("target") or not UnitIsPlayer("target") then
      return "Target a player to whisper."
    end
    if UnitIsUnit("player", "target") then
      return "Target someone else to whisper."
    end
    target = GetUnitName("target", true)
    if not target or target == "" then
      return "Target a player to whisper."
    end
  elseif kind == "PARTY" then
    if IsInRaid() then
      return "Use Raid while you are in a raid."
    end
    if not IsInGroup() then
      return "You are not in a party."
    end
  elseif kind == "RAID" then
    if not IsInRaid() then
      return "You are not in a raid."
    end
  elseif kind == "GUILD" then
    if not IsInGuild() then
      return "You are not in a guild."
    end
  elseif kind ~= "SAY" and kind ~= "YELL" then
    return "Solve today's word first."
  end
  for i = 1, #lines do
    shareQueue[#shareQueue + 1] = { text = lines[i], kind = kind, target = target }
  end
  if not sharePumping then
    sharePumping = true
    PumpShare()
  end
  return nil
end

function WoWdle.Refresh()
  local frames = WoWdle.frames
  if not frames or not frames.main:IsShown() then
    return
  end
  local cur = WoWdle.EnsureToday()
  local _, number = WoWdle.AnswerFor(cur.y, cur.m, cur.d)
  frames.number:SetText("No. " .. number)
  local draft = cur.done == "play" and string.lower(WoWdle.draft or "") or ""
  local active = #cur.guesses + 1
  for row = 1, 6 do
    local guess = cur.guesses[row]
    local state = cur.states[row]
    for col = 1, 5 do
      local letter, mark
      if guess then
        letter = guess:sub(col, col):upper()
        mark = state:sub(col, col)
      elseif row == active then
        letter = draft:sub(col, col):upper()
      end
      WoWdle.ApplyTile(frames.tiles[row][col], letter, mark)
    end
  end
  local best = {}
  local rank = { B = 1, Y = 2, G = 3 }
  for i = 1, #cur.guesses do
    local guess = cur.guesses[i]
    local state = cur.states[i]
    for col = 1, 5 do
      local ch = guess:sub(col, col):upper()
      local mark = state:sub(col, col)
      if not best[ch] or rank[mark] > rank[best[ch]] then
        best[ch] = mark
      end
    end
  end
  for letter, button in pairs(frames.keys) do
    WoWdle.ApplyKey(button, best[letter])
  end
  local locked = #cur.guesses > 0
  frames.hardMode:SetEnabled(not locked)
  frames.hardMode:SetChecked(locked and cur.hardMode or WoWdleDB.settings.hardMode)
  frames.colorblind:SetChecked(WoWdleDB.settings.colorblind)
  if cur.done == "win" then
    frames.result:SetText("Solved in " .. #cur.guesses .. ".")
    frames.share:Enable()
  else
    if frames.shareMenu then
      frames.shareMenu:Hide()
    end
    if cur.done == "loss" then
      local word = WoWdle.AnswerFor(cur.y, cur.m, cur.d)
      frames.result:SetText("The word was " .. word:upper() .. ".")
    else
      frames.result:SetText("")
    end
    frames.share:Disable()
  end
  local stats = WoWdleDB.stats
  local played = stats.played or 0
  local rate = played > 0 and math.floor((stats.wins / played) * 100 + 0.5) or 0
  frames.stats:SetText(string.format("Played %d    Win %d%%    Streak %d    Max %d", played, rate, stats.streak or 0, stats.maxStreak or 0))
  WoWdle.RefreshGuild()
end

function WoWdle.RefreshGuild()
  local frames = WoWdle.frames
  if not frames then
    return
  end
  local cur = WoWdleDB.current
  local rows = {}
  local seen = {}
  if cur and cur.done ~= "play" and cur.character then
    local pattern = table.concat(cur.states)
    rows[#rows + 1] = {
      name = ShortName(cur.character),
      sort = cur.character,
      score = cur.done == "win" and #cur.guesses or 99,
      label = cur.done == "win" and (#cur.guesses .. "/6") or "X/6",
      pattern = pattern,
    }
    seen[cur.character] = true
  end
  local bucket = cur and WoWdleDB.guild[cur.date]
  if bucket then
    for sender, info in pairs(bucket) do
      if not seen[sender] and not WoWdle.IsSelf(sender) then
        rows[#rows + 1] = {
          name = ShortName(sender),
          sort = sender,
          score = info.won and info.score or 99,
          label = info.won and (info.score .. "/6") or "X/6",
          pattern = info.pattern,
        }
      end
    end
  end
  table.sort(rows, function(a, b)
    if a.score ~= b.score then
      return a.score < b.score
    end
    return a.sort < b.sort
  end)
  if not IsInGuild() then
    frames.guildEmpty:SetText("Join a guild to compare today's score and grid.")
  elseif #rows == 0 then
    frames.guildEmpty:SetText("No guild results yet. Finish the puzzle and anyone with Leyword in your guild will see the grid, not the words.")
  else
    frames.guildEmpty:SetText("")
  end
  for i = 1, #frames.guildRows do
    local row = frames.guildRows[i]
    local info = rows[i]
    if info then
      row.name:SetText(info.name)
      row.score:SetText(info.label)
      row.grid:SetText(GridText(info.pattern))
      row:Show()
    else
      row:Hide()
    end
  end
  frames.guildContent:SetHeight(math.max(40, #rows * 54))
end

local function Build()
  local frame = CreateFrame("Frame", "WoWdleFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(440, 600)
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    WoWdleDB.settings.point = { point, relativePoint, x, y }
  end)
  local saved = WoWdleDB.settings.point
  if type(saved) == "table" and saved[1] and saved[2] then
    frame:ClearAllPoints()
    frame:SetPoint(saved[1], UIParent, saved[2], saved[3] or 0, saved[4] or 0)
  else
    frame:SetPoint("CENTER")
  end
  if frame.TitleText then
    frame.TitleText:SetText("Leyword")
    if not frame.TitleText:SetFont("Fonts\\MORPHEUS.TTF", 16, "") then
      frame.TitleText:SetFont("Fonts\\MORPHEUS.ttf", 16, "")
    end
  end
  AddEscape("WoWdleFrame")
  local anchor = frame.Inset or frame
  local puzzleTab = CreateFrame("Button", "WoWdlePuzzleTab", anchor, "UIPanelButtonTemplate")
  puzzleTab:SetSize(90, 22)
  puzzleTab:SetPoint("TOPLEFT", anchor, "TOPLEFT", 12, -8)
  puzzleTab:SetText("Puzzle")
  local guildTab = CreateFrame("Button", "WoWdleGuildTab", anchor, "UIPanelButtonTemplate")
  guildTab:SetSize(90, 22)
  guildTab:SetPoint("LEFT", puzzleTab, "RIGHT", 6, 0)
  guildTab:SetText("Guild")

  local board = CreateFrame("Frame", nil, anchor)
  board:SetPoint("TOPLEFT", anchor, "TOPLEFT", 12, -36)
  board:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -10, 10)
  local guild = CreateFrame("Frame", nil, anchor)
  guild:SetPoint("TOPLEFT", board, "TOPLEFT")
  guild:SetPoint("BOTTOMRIGHT", board, "BOTTOMRIGHT")
  guild:Hide()

  local number = board:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  number:SetPoint("TOP", 0, -2)
  local tiles = {}
  for row = 1, 6 do
    tiles[row] = {}
    for col = 1, 5 do
      local tile = CreateFrame("Frame", "WoWdleTile_" .. row .. "_" .. col, board, "BackdropTemplate")
      tile:SetSize(36, 36)
      tile:SetPoint("TOPLEFT", board, "TOP", -98 + (col - 1) * 40, -26 - (row - 1) * 40)
      tile:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
      })
      tile.letter = tile:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      tile.letter:SetPoint("CENTER", 0, 1)
      tiles[row][col] = tile
    end
  end

  local status = board:CreateFontString(nil, "OVERLAY", "GameFontRed")
  status:SetPoint("TOP", board, "TOP", 0, -272)
  status:SetWidth(320)
  local result = board:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  result:SetPoint("TOP", status, "BOTTOM", 0, -1)

  local box = CreateFrame("EditBox", "WoWdleGuessBox", board, "InputBoxTemplate")
  box:SetSize(110, 22)
  box:SetPoint("TOP", board, "TOP", -96, -296)
  box:SetAutoFocus(false)
  box:SetMaxLetters(5)
  box:SetFontObject(GameFontHighlight)
  local back = CreateFrame("Button", "WoWdleBackButton", board, "UIPanelButtonTemplate")
  back:SetSize(50, 22)
  back:SetPoint("LEFT", box, "RIGHT", 6, 0)
  back:SetText("Back")
  local submit = CreateFrame("Button", "WoWdleSubmitButton", board, "UIPanelButtonTemplate")
  submit:SetSize(58, 22)
  submit:SetPoint("LEFT", back, "RIGHT", 4, 0)
  submit:SetText("Enter")
  local share = CreateFrame("Button", "WoWdleShareButton", board, "UIPanelButtonTemplate")
  share:SetSize(58, 22)
  share:SetPoint("LEFT", submit, "RIGHT", 4, 0)
  share:SetText("Share")
  share:Disable()
  local menu = CreateFrame("Frame", "WoWdleShareMenu", frame, "BackdropTemplate")
  menu:SetSize(196, 58)
  menu:SetPoint("TOP", share, "BOTTOM", 0, -2)
  menu:SetFrameStrata("DIALOG")
  menu:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  menu:Hide()
  local channels = {}
  local channelList = {
    { "SAY", "Say" },
    { "PARTY", "Party" },
    { "YELL", "Yell" },
    { "RAID", "Raid" },
    { "GUILD", "Guild" },
    { "WHISPER", "Whisper" },
  }
  for i = 1, #channelList do
    local kind, label = channelList[i][1], channelList[i][2]
    local button = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    button:SetSize(58, 20)
    local col = (i - 1) % 3
    local row = math.floor((i - 1) / 3)
    button:SetPoint("TOPLEFT", 8 + col * 62, -8 - row * 22)
    button:SetText(label)
    local font = button:GetFontString()
    if font then
      font:SetFontObject(GameFontNormalSmall)
    end
    button:SetScript("OnClick", function()
      local err = WoWdle.ShareTo(kind)
      if err then
        status:SetText(err)
        return
      end
      local sent = label == "Whisper" and ("Whispered " .. (GetUnitName("target", true) or "them") .. ".") or ("Sent to " .. label .. ".")
      status:SetText(sent)
      menu:Hide()
    end)
    channels[i] = button
  end

  local keys = {}
  local keyRows = { "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM" }
  local keyY = { -328, -352, -376 }
  for r = 1, #keyRows do
    local letters = keyRows[r]
    local width = #letters * 26 + (#letters - 1) * 3
    local origin = -math.floor(width / 2)
    for i = 1, #letters do
      local letter = letters:sub(i, i)
      local key = CreateFrame("Button", "WoWdleKey_" .. letter, board, "UIPanelButtonTemplate")
      key:SetSize(26, 22)
      key:SetPoint("TOP", board, "TOP", origin + (i - 1) * 29, keyY[r])
      key:SetText(letter)
      local label = key:GetFontString()
      if label then
        label:SetFontObject(GameFontNormalSmall)
      end
      key:SetScript("OnClick", function()
        local cur = WoWdleDB.current
        if cur and cur.done ~= "play" then
          return
        end
        box:SetText(((box:GetText() or "") .. letter):sub(1, 5))
        box:SetFocus()
      end)
      keys[letter] = key
    end
  end

  local hardMode = CreateFrame("CheckButton", "WoWdleHardModeCheck", board, "UICheckButtonTemplate")
  hardMode:SetPoint("TOPLEFT", board, "TOPLEFT", 48, -406)
  CheckText(hardMode, "Hard mode")
  local colorblind = CreateFrame("CheckButton", "WoWdleColorblindCheck", board, "UICheckButtonTemplate")
  colorblind:SetPoint("LEFT", hardMode, "RIGHT", 110, 0)
  CheckText(colorblind, "Colorblind")
  local stats = board:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  stats:SetPoint("BOTTOM", board, "BOTTOM", 0, 8)

  local guildNote = guild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  guildNote:SetPoint("TOPLEFT", 8, -2)
  guildNote:SetText("Today")
  local scroll = CreateFrame("ScrollFrame", "WoWdleGuildScroll", guild, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 4, -22)
  scroll:SetPoint("BOTTOMRIGHT", -26, 4)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(280, 40)
  scroll:SetScrollChild(content)
  local empty = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  empty:SetPoint("TOPLEFT", 4, -4)
  empty:SetWidth(260)
  empty:SetJustifyH("LEFT")
  empty:SetJustifyV("TOP")
  local guildRows = {}
  for i = 1, 40 do
    local row = CreateFrame("Frame", nil, content)
    row:SetSize(280, 52)
    row:SetPoint("TOPLEFT", 4, -(i - 1) * 54)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", 0, -2)
    row.name:SetJustifyH("LEFT")
    row.score = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.score:SetPoint("TOPLEFT", 0, -18)
    row.grid = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.grid:SetPoint("TOPRIGHT", -4, -4)
    row.grid:SetJustifyH("RIGHT")
    row:Hide()
    guildRows[i] = row
  end

  local function Submit()
    local err = WoWdle.SubmitGuess(box:GetText() or "")
    if err then
      status:SetText(err)
      return
    end
    status:SetText("")
    box:SetText("")
    WoWdle.draft = ""
    WoWdle.Refresh()
  end

  box:SetScript("OnTextChanged", function(self)
    local text = string.upper(self:GetText() or ""):gsub("[^A-Z]", "")
    if text ~= self:GetText() then
      self:SetText(text)
      return
    end
    WoWdle.draft = text
    if WoWdle.frames then
      WoWdle.Refresh()
    end
  end)
  box:SetScript("OnEnterPressed", Submit)
  box:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    frame:Hide()
  end)
  back:SetScript("OnClick", function()
    local text = box:GetText() or ""
    box:SetText(text:sub(1, -2))
    box:SetFocus()
  end)
  submit:SetScript("OnClick", Submit)
  share:SetScript("OnClick", function()
    if WoWdleDB.current and WoWdleDB.current.done ~= "win" then
      return
    end
    menu:SetShown(not menu:IsShown())
  end)
  hardMode:SetScript("OnClick", function(self)
    local cur = WoWdle.EnsureToday()
    if #cur.guesses > 0 then
      self:SetChecked(cur.hardMode and true or false)
      return
    end
    WoWdleDB.settings.hardMode = self:GetChecked() and true or false
  end)
  colorblind:SetScript("OnClick", function(self)
    WoWdleDB.settings.colorblind = self:GetChecked() and true or false
    WoWdle.Refresh()
  end)

  local function ShowPage(which)
    WoWdle.page = which
    if which ~= "puzzle" then
      menu:Hide()
    end
    board:SetShown(which == "puzzle")
    guild:SetShown(which == "guild")
    if WoWdle.SyncEllesmereTabs then
      WoWdle.SyncEllesmereTabs(which)
    end
    if which == "guild" and WoWdle.RequestSync then
      WoWdle.RequestSync()
    end
  end
  puzzleTab:SetScript("OnClick", function()
    ShowPage("puzzle")
  end)
  guildTab:SetScript("OnClick", function()
    ShowPage("guild")
  end)

  WoWdle.frames = {
    main = frame,
    inset = anchor,
    board = board,
    guild = guild,
    tiles = tiles,
    keys = keys,
    guessBox = box,
    submit = submit,
    share = share,
    shareMenu = menu,
    channels = channels,
    back = back,
    puzzleTab = puzzleTab,
    guildTab = guildTab,
    hardMode = hardMode,
    colorblind = colorblind,
    status = status,
    stats = stats,
    result = result,
    number = number,
    guildScroll = scroll,
    guildContent = content,
    guildRows = guildRows,
    guildEmpty = empty,
  }
  WoWdle.draft = ""
  frame:SetScript("OnShow", function()
    WoWdle.Refresh()
  end)
  WoWdle.framesBuilt = true
  if WoWdle.ApplyBuiltinSkins then
    WoWdle.ApplyBuiltinSkins()
  end
  if WoWdle.ApplyEllesmere then
    WoWdle.ApplyEllesmere()
  end
  if WoWdle.RunSkinCallbacks then
    WoWdle.RunSkinCallbacks()
  end
  ShowPage("puzzle")
  frame:Hide()
end

function WoWdle.Toggle()
  if not WoWdle.frames then
    Build()
  end
  local frame = WoWdle.frames.main
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end
