Leyword = Leyword or {}

Leyword.Colors = {
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

function Leyword.Palette()
  if LeywordDB and LeywordDB.settings and LeywordDB.settings.colorblind then
    return Leyword.Colors.colorblind
  end
  return Leyword.Colors.normal
end

function Leyword.ApplyTile(tile, letter, mark)
  tile.letter:SetText(letter or "")
  local color = mark and Leyword.Palette()[mark]
  if color then
    tile:SetBackdropColor(color[1], color[2], color[3], 1)
    tile:SetBackdropBorderColor(color[1] * 0.55, color[2] * 0.55, color[3] * 0.55, 1)
    tile.letter:SetTextColor(0.98, 0.96, 0.9)
  elseif letter and letter ~= "" then
    tile:SetBackdropColor(0.32, 0.24, 0.14, 1)
    tile:SetBackdropBorderColor(0.95, 0.78, 0.38, 1)
    tile.letter:SetTextColor(1, 0.96, 0.82)
  else
    tile:SetBackdropColor(0.18, 0.13, 0.08, 0.55)
    tile:SetBackdropBorderColor(0.45, 0.36, 0.22, 1)
  end
end

function Leyword.ApplyKey(button, mark)
  button.leywordMark = mark
  local swatch = button.leywordSwatch
  if not swatch then
    swatch = button:CreateTexture(nil, "ARTWORK", nil, 7)
    swatch:SetPoint("TOPLEFT", 2, -2)
    swatch:SetPoint("BOTTOMRIGHT", -2, 2)
    swatch:SetTexture("Interface\\Buttons\\WHITE8X8")
    button.leywordSwatch = swatch
  end
  local label = button.leywordLabel or button:GetFontString()
  if label and label.SetDrawLayer then
    label:SetDrawLayer("OVERLAY", 7)
  end
  local color = mark and Leyword.Palette()[mark]
  if color then
    swatch:Show()
    swatch:SetVertexColor(color[1], color[2], color[3], 1)
    if label then
      label:SetTextColor(0.98, 0.96, 0.9)
    end
  else
    swatch:Hide()
    if label then
      label:SetTextColor(1, 0.95, 0.78)
    end
  end
end

local function Swatch(mark)
  local color = Leyword.Palette()[mark]
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

function Leyword.ShareLines()
  local cur = Leyword.review or Leyword.Round()
  if not cur or cur.done ~= "win" then
    return nil
  end
  local rows = {}
  for i = 1, #cur.states do
    rows[i] = (cur.states[i] or ""):gsub("[^GYB]", "")
  end
  local head
  if cur.extra then
    head = string.format("Leyword extra %d/6", #cur.guesses)
  else
    local _, number = Leyword.AnswerFor(cur.y, cur.m, cur.d)
    head = string.format("Leyword %d %d/6", number, #cur.guesses)
  end
  return head
    .. " "
    .. table.concat(rows, " ")
    .. ". https://www.curseforge.com/wow/addons/leyword"
end

function Leyword.ShareTo(kind)
  local text = Leyword.ShareLines()
  if not text then
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
  if target then
    SendChatMessage(text, kind, nil, target)
  else
    SendChatMessage(text, kind)
  end
  return nil
end

function Leyword.Refresh()
  local frames = Leyword.frames
  if not frames or not frames.main:IsShown() then
    return
  end
  if frames.versionWarn then
    frames.versionWarn:SetShown(Leyword.outdated and true or false)
  end
  local reviewing = Leyword.review
  local cur = reviewing or Leyword.Round()
  local _, number = Leyword.AnswerFor(cur.y, cur.m, cur.d)
  frames.number:SetText(reviewing and "Past" or (cur.extra and "Extra" or ("No. " .. number)))
  local draft = (not reviewing and cur.done == "play") and string.lower(Leyword.draft or "") or ""
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
      Leyword.ApplyTile(frames.tiles[row][col], letter, mark)
    end
  end
  local best = {}
  local rank = { B = 1, Y = 2, G = 3 }
  for i = 1, #cur.guesses do
    local guess = cur.guesses[i]
    local state = cur.states[i]
    if type(guess) == "string" and type(state) == "string" then
      for col = 1, 5 do
        local ch = guess:sub(col, col):upper()
        local mark = state:sub(col, col)
        if rank[mark] and (not best[ch] or rank[mark] > rank[best[ch]]) then
          best[ch] = mark
        end
      end
    end
  end
  for letter, button in pairs(frames.keys) do
    Leyword.ApplyKey(button, best[letter])
  end
  frames.colorblind:SetChecked(LeywordDB.settings.colorblind)
  local showKeys = LeywordDB.settings.keyboard ~= false
  frames.keyboard:SetChecked(showKeys)
  frames.keypad:SetShown(showKeys and not reviewing)
  if reviewing then
    if cur.done == "win" then
      frames.result:SetText("Solved in " .. #cur.guesses .. ".")
      frames.share:Enable()
    else
      if frames.shareMenu then
        frames.shareMenu:Hide()
      end
      if cur.done == "loss" then
        local word = cur.answer or ""
        frames.result:SetText(word ~= "" and ("The word was " .. word:upper() .. ".") or "Not solved.")
      else
        frames.result:SetText("")
      end
      frames.share:Disable()
    end
    frames.another:Hide()
    frames.today:Show()
    frames.guessBox:EnableMouse(false)
    frames.submit:Disable()
    frames.back:Disable()
  else
    frames.today:Hide()
    frames.guessBox:EnableMouse(true)
    frames.submit:Enable()
    frames.back:Enable()
    if cur.done == "win" then
      frames.result:SetText("Solved in " .. #cur.guesses .. ".")
      frames.share:Enable()
      frames.another:Show()
    else
      if frames.shareMenu then
        frames.shareMenu:Hide()
      end
      if cur.done == "loss" then
        local word = cur.answer or Leyword.AnswerFor(cur.y, cur.m, cur.d)
        frames.result:SetText("The word was " .. word:upper() .. ".")
        frames.another:Show()
      else
        frames.result:SetText("")
        frames.another:Hide()
      end
      frames.share:Disable()
    end
  end
  local stats = LeywordDB.stats
  local played = stats.played or 0
  local rate = played > 0 and math.floor((stats.wins / played) * 100 + 0.5) or 0
  frames.stats:SetText(string.format("Played %d    Win %d%%    Streak %d    Max %d", played, rate, stats.streak or 0, stats.maxStreak or 0))
  Leyword.RefreshGuild()
end

function Leyword.RefreshGuild()
  local frames = Leyword.frames
  if not frames then
    return
  end
  local cur = LeywordDB.current
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
  local bucket = cur and LeywordDB.guild[cur.date]
  if bucket then
    for sender, info in pairs(bucket) do
      if not seen[sender] and not Leyword.IsSelf(sender) then
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
    frames.guildEmpty:SetText("No guild results yet. Press Sync, or wait for a guildmate to log on.")
  else
    frames.guildEmpty:SetText("")
  end
  if frames.guildStatus then
    frames.guildStatus:SetText(Leyword.syncStatus or "Press Sync while you are both online.")
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
  Leyword.RefreshHistory()
end

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

function Leyword.RefreshHistory()
  local frames = Leyword.frames
  if not frames or not frames.pastRows then
    return
  end
  local history = LeywordDB.history or {}
  if #history == 0 then
    frames.pastEmpty:SetText("Finished puzzles show up here. Games from before this update were not kept.")
  else
    frames.pastEmpty:SetText("")
  end
  for i = 1, #frames.pastRows do
    local row = frames.pastRows[i]
    local entry = history[i]
    if entry then
      local when = (MONTHS[entry.m] or "?") .. " " .. tostring(entry.d)
      if entry.extra then
        when = when .. " extra"
      else
        local _, puzzle = Leyword.AnswerFor(entry.y, entry.m, entry.d)
        when = when .. "   No. " .. puzzle
      end
      local score = entry.done == "win" and (#entry.guesses .. "/6") or "X/6"
      row:SetText(when .. "    " .. score)
      row:Show()
    else
      row:Hide()
    end
  end
  frames.pastContent:SetHeight(math.max(40, math.min(#history, #frames.pastRows) * 26))
end

local SUGGESTIONS = {
  "Maro",
}

local function Build()
  local frame = CreateFrame("Frame", "LeywordFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(470, 748)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(200)
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    LeywordDB.settings.point = { point, relativePoint, x, y }
  end)
  local saved = LeywordDB.settings.point
  if type(saved) == "table" and saved[1] and saved[2] then
    frame:ClearAllPoints()
    frame:SetPoint(saved[1], UIParent, saved[2], saved[3] or 0, saved[4] or 0)
  else
    frame:SetPoint("CENTER")
  end
  if frame.TitleText then
    frame.TitleText:SetText("")
    frame.TitleText:Hide()
  end
  local title = frame:CreateFontString(nil, "OVERLAY")
  title:SetPoint("TOP", frame, "TOP", 0, -30)
  if not title:SetFont("Fonts\\MORPHEUS.TTF", 24, "") then
    title:SetFont("Fonts\\MORPHEUS.ttf", 24, "")
  end
  title:SetText("LEYWORD")
  title:SetTextColor(1, 0.82, 0.2)
  local versionWarn = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  versionWarn:SetPoint("TOP", frame, "TOP", 0, -4)
  versionWarn:SetText("Leyword is out of date. Update on CurseForge.")
  versionWarn:SetTextColor(1, 0.45, 0.35)
  versionWarn:Hide()
  AddEscape("LeywordFrame")
  local anchor = frame.Inset or frame
  local puzzleTab = CreateFrame("Button", "LeywordPuzzleTab", frame, "UIPanelButtonTemplate")
  puzzleTab:SetSize(90, 22)
  puzzleTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -62)
  puzzleTab:SetText("Puzzle")
  local guildTab = CreateFrame("Button", "LeywordGuildTab", frame, "UIPanelButtonTemplate")
  guildTab:SetSize(90, 22)
  guildTab:SetPoint("LEFT", puzzleTab, "RIGHT", 6, 0)
  guildTab:SetText("Guild")
  local pastTab = CreateFrame("Button", "LeywordPastTab", frame, "UIPanelButtonTemplate")
  pastTab:SetSize(70, 22)
  pastTab:SetPoint("LEFT", guildTab, "RIGHT", 6, 0)
  pastTab:SetText("Past")

  local board = CreateFrame("Frame", nil, frame)
  board:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -92)
  board:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
  local guild = CreateFrame("Frame", nil, frame)
  guild:SetPoint("TOPLEFT", board, "TOPLEFT")
  guild:SetPoint("BOTTOMRIGHT", board, "BOTTOMRIGHT")
  guild:Hide()

  local number = board:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  number:SetPoint("TOP", 0, -2)
  local tiles = {}
  for row = 1, 6 do
    tiles[row] = {}
    for col = 1, 5 do
      local tile = CreateFrame("Frame", "LeywordTile_" .. row .. "_" .. col, board, "BackdropTemplate")
      tile:SetSize(56, 56)
      tile:SetPoint("TOPLEFT", board, "TOP", -156 + (col - 1) * 64, -28 - (row - 1) * 64)
      tile:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
      })
      tile.letter = tile:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
      tile.letter:SetPoint("CENTER", 0, 1)
      if not tile.letter:SetFont("Fonts\\FRIZQT__.TTF", 28, "") then
        tile.letter:SetFont("Fonts\\FRIZQT__.ttf", 28, "")
      end
      tiles[row][col] = tile
    end
  end

  local status = board:CreateFontString(nil, "OVERLAY", "GameFontRed")
  status:SetPoint("TOP", board, "TOP", 0, -416)
  status:SetWidth(320)
  local result = board:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  result:SetPoint("TOP", status, "BOTTOM", 0, -1)

  local box = CreateFrame("EditBox", "LeywordGuessBox", board, "InputBoxTemplate")
  box:SetSize(110, 22)
  box:SetPoint("TOP", board, "TOP", -96, -442)
  box:SetAutoFocus(false)
  box:SetMaxLetters(5)
  box:SetFontObject(GameFontHighlight)
  box:SetTextColor(1, 0.96, 0.82)
  local back = CreateFrame("Button", "LeywordBackButton", board, "UIPanelButtonTemplate")
  back:SetSize(50, 22)
  back:SetPoint("LEFT", box, "RIGHT", 6, 0)
  back:SetText("Back")
  local submit = CreateFrame("Button", "LeywordSubmitButton", board, "UIPanelButtonTemplate")
  submit:SetSize(58, 22)
  submit:SetPoint("LEFT", back, "RIGHT", 4, 0)
  submit:SetText("Enter")
  local share = CreateFrame("Button", "LeywordShareButton", board, "UIPanelButtonTemplate")
  share:SetSize(58, 22)
  share:SetPoint("LEFT", submit, "RIGHT", 4, 0)
  share:SetText("Share")
  share:Disable()
  local another = CreateFrame("Button", "LeywordAnotherButton", board, "UIPanelButtonTemplate")
  another:SetSize(78, 22)
  another:SetPoint("TOPRIGHT", board, "TOPRIGHT", -12, -556)
  another:SetText("Another")
  another:Hide()
  local today = CreateFrame("Button", "LeywordTodayButton", board, "UIPanelButtonTemplate")
  today:SetSize(70, 22)
  today:SetPoint("TOPRIGHT", board, "TOPRIGHT", -8, -2)
  today:SetText("Today")
  today:Hide()
  local feedback = CreateFrame("Button", "LeywordFeedbackButton", frame, "UIPanelButtonTemplate")
  feedback:SetSize(84, 22)
  feedback:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -62)
  feedback:SetText("Feedback")
  local popup = CreateFrame("Frame", "LeywordFeedback", UIParent, "BasicFrameTemplateWithInset")
  popup:SetSize(360, 150)
  popup:SetPoint("CENTER")
  popup:SetFrameStrata("DIALOG")
  popup:SetFrameLevel(400)
  popup:SetToplevel(true)
  popup:Hide()
  if popup.TitleText then
    popup.TitleText:SetText("Feedback")
  end
  AddEscape("LeywordFeedback")
  local hint = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOP", 0, -32)
  hint:SetWidth(320)
  hint:SetJustifyH("CENTER")
  hint:SetText("Post in #feedback. Click the link in chat, or press Ctrl+C.")
  local edit = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
  edit:SetSize(250, 22)
  edit:SetPoint("TOP", 0, -58)
  edit:SetAutoFocus(false)
  edit:SetFontObject(GameFontHighlight)
  edit:SetText("https://discord.gg/ShzNPC2ahn")
  local closeFeedback = CreateFrame("Button", "LeywordFeedbackClose", popup, "UIPanelButtonTemplate")
  closeFeedback:SetSize(80, 22)
  closeFeedback:SetPoint("BOTTOM", 0, 14)
  closeFeedback:SetText("Close")
  local thanks = CreateFrame("Button", "LeywordThanksButton", frame, "UIPanelButtonTemplate")
  thanks:SetSize(70, 22)
  thanks:SetPoint("RIGHT", feedback, "LEFT", -6, 0)
  thanks:SetText("Thanks")
  local thanksPopup = CreateFrame("Frame", "LeywordThanks", UIParent, "BasicFrameTemplateWithInset")
  thanksPopup:SetSize(260, 78 + #SUGGESTIONS * 18)
  thanksPopup:SetPoint("CENTER")
  thanksPopup:SetFrameStrata("DIALOG")
  thanksPopup:SetFrameLevel(400)
  thanksPopup:SetToplevel(true)
  thanksPopup:Hide()
  if thanksPopup.TitleText then
    thanksPopup.TitleText:SetText("Suggestions")
  end
  AddEscape("LeywordThanks")
  local thanksHint = thanksPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  thanksHint:SetPoint("TOP", 0, -32)
  thanksHint:SetText("Suggestion givers")
  for i = 1, #SUGGESTIONS do
    local line = thanksPopup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line:SetPoint("TOP", 0, -50 - (i - 1) * 18)
    line:SetText(SUGGESTIONS[i])
  end
  local closeThanks = CreateFrame("Button", "LeywordThanksClose", thanksPopup, "UIPanelButtonTemplate")
  closeThanks:SetSize(80, 22)
  closeThanks:SetPoint("BOTTOM", 0, 14)
  closeThanks:SetText("Close")
  local menu = CreateFrame("Frame", "LeywordShareMenu", frame, "BackdropTemplate")
  menu:SetSize(196, 58)
  menu:SetPoint("BOTTOMRIGHT", share, "TOPRIGHT", 0, 4)
  menu:SetFrameStrata("TOOLTIP")
  menu:SetFrameLevel(50)
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
      local err = Leyword.ShareTo(kind)
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

  local keypad = CreateFrame("Frame", nil, board)
  local keys = {}
  local keyRows = { "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM" }
  local keyY = { -474, -500, -526 }
  for r = 1, #keyRows do
    local letters = keyRows[r]
    local width = #letters * 26 + (#letters - 1) * 3
    local origin = -math.floor(width / 2)
    for i = 1, #letters do
      local letter = letters:sub(i, i)
      local key = CreateFrame("Button", "LeywordKey_" .. letter, keypad, "UIPanelButtonTemplate")
      key:SetSize(26, 22)
      key:SetPoint("TOP", board, "TOP", origin + (i - 1) * 29, keyY[r])
      key:SetText(letter)
      local label = key:GetFontString()
      key.leywordLabel = label
      if label then
        label:SetFontObject(GameFontNormalSmall)
      end
      key:SetScript("OnClick", function()
        if Leyword.review then
          return
        end
        local cur = Leyword.Round()
        if cur and cur.done ~= "play" then
          return
        end
        box:SetText(((box:GetText() or "") .. letter):sub(1, 5))
        box:SetFocus()
      end)
      key:HookScript("OnEnter", function(self)
        Leyword.ApplyKey(self, self.leywordMark)
      end)
      key:HookScript("OnLeave", function(self)
        Leyword.ApplyKey(self, self.leywordMark)
      end)
      keys[letter] = key
    end
  end

  local colorblind = CreateFrame("CheckButton", "LeywordColorblindCheck", board, "UICheckButtonTemplate")
  colorblind:SetPoint("TOP", board, "TOP", -120, -560)
  CheckText(colorblind, "Colorblind")
  local keyboard = CreateFrame("CheckButton", "LeywordKeyboardCheck", board, "UICheckButtonTemplate")
  keyboard:SetPoint("TOP", board, "TOP", 48, -560)
  CheckText(keyboard, "Keys")
  keyboard:SetChecked(LeywordDB.settings.keyboard ~= false)
  keypad:SetShown(LeywordDB.settings.keyboard ~= false)
  local stats = board:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  stats:SetPoint("BOTTOM", board, "BOTTOM", 0, 8)

  local guildNote = guild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  guildNote:SetPoint("TOPLEFT", 8, -2)
  guildNote:SetText("Today")
  local guildSync = CreateFrame("Button", "LeywordGuildSyncButton", guild, "UIPanelButtonTemplate")
  guildSync:SetSize(70, 22)
  guildSync:SetPoint("TOPRIGHT", -28, 0)
  guildSync:SetText("Sync")
  guildSync:SetScript("OnClick", function()
    if not IsInGuild() then
      return
    end
    if C_GuildInfo and C_GuildInfo.GuildRoster then
      pcall(C_GuildInfo.GuildRoster)
    elseif GuildRoster then
      pcall(GuildRoster)
    end
    if Leyword.SyncGuild then
      Leyword.SyncGuild(true)
    end
    guildNote:SetText("Syncing...")
    C_Timer.After(2, function()
      if guildNote:GetText() == "Syncing..." then
        guildNote:SetText("Today")
      end
    end)
  end)
  local scroll = CreateFrame("ScrollFrame", "LeywordGuildScroll", guild, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 4, -28)
  scroll:SetPoint("BOTTOMRIGHT", -26, 22)
  local guildStatus = guild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  guildStatus:SetPoint("BOTTOMLEFT", 8, 4)
  guildStatus:SetPoint("BOTTOMRIGHT", -28, 4)
  guildStatus:SetJustifyH("LEFT")
  guildStatus:SetText("Press Sync while you are both online.")
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

  local past = CreateFrame("Frame", nil, frame)
  past:SetPoint("TOPLEFT", board, "TOPLEFT")
  past:SetPoint("BOTTOMRIGHT", board, "BOTTOMRIGHT")
  past:Hide()
  local pastScroll = CreateFrame("ScrollFrame", "LeywordPastScroll", past, "UIPanelScrollFrameTemplate")
  pastScroll:SetPoint("TOPLEFT", 4, -8)
  pastScroll:SetPoint("BOTTOMRIGHT", -26, 4)
  local pastContent = CreateFrame("Frame", nil, pastScroll)
  pastContent:SetSize(280, 40)
  pastScroll:SetScrollChild(pastContent)
  local pastEmpty = pastContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pastEmpty:SetPoint("TOPLEFT", 4, -4)
  pastEmpty:SetWidth(280)
  pastEmpty:SetJustifyH("LEFT")
  pastEmpty:SetText("Finished puzzles show up here. Games from before this update were not kept.")
  local pastRows = {}
  for i = 1, 60 do
    local row = CreateFrame("Button", nil, pastContent, "UIPanelButtonTemplate")
    row:SetSize(300, 22)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * 26)
    row:SetText("")
    row:Hide()
    pastRows[i] = row
  end

  local function Submit()
    if Leyword.review then
      return
    end
    local err = Leyword.SubmitGuess(box:GetText() or "")
    if err then
      status:SetText(err)
      return
    end
    status:SetText("")
    box:SetText("")
    Leyword.draft = ""
    Leyword.Refresh()
  end

  box:SetScript("OnTextChanged", function(self)
    local text = string.upper(self:GetText() or ""):gsub("[^A-Z]", "")
    if text ~= self:GetText() then
      self:SetText(text)
      return
    end
    Leyword.draft = text
    self:SetTextColor(1, 0.96, 0.82)
    if Leyword.frames then
      Leyword.Refresh()
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
    local cur = Leyword.review or Leyword.Round()
    if not cur or cur.done ~= "win" then
      return
    end
    menu:SetShown(not menu:IsShown())
  end)
  another:SetScript("OnClick", function()
    Leyword.StartExtra()
    box:SetText("")
    Leyword.draft = ""
    status:SetText("")
    menu:Hide()
    Leyword.Refresh()
  end)
  feedback:SetScript("OnClick", function()
    edit:SetText("https://discord.gg/ShzNPC2ahn")
    edit:HighlightText()
    edit:SetFocus()
    popup:Show()
    DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37Leyword|r  #feedback: https://discord.gg/ShzNPC2ahn")
  end)
  closeFeedback:SetScript("OnClick", function()
    popup:Hide()
  end)
  thanks:SetScript("OnClick", function()
    thanksPopup:SetShown(not thanksPopup:IsShown())
  end)
  closeThanks:SetScript("OnClick", function()
    thanksPopup:Hide()
  end)
  frame:HookScript("OnHide", function()
    popup:Hide()
    thanksPopup:Hide()
  end)
  colorblind:SetScript("OnClick", function(self)
    LeywordDB.settings.colorblind = self:GetChecked() and true or false
    Leyword.Refresh()
  end)
  keyboard:SetScript("OnClick", function(self)
    local shown = self:GetChecked() and true or false
    LeywordDB.settings.keyboard = shown
    keypad:SetShown(shown)
  end)

  local function ShowPage(which, keepReview)
    Leyword.page = which
    if which == "puzzle" and not keepReview then
      Leyword.review = nil
    end
    if which ~= "puzzle" then
      menu:Hide()
    end
    board:SetShown(which == "puzzle")
    guild:SetShown(which == "guild")
    past:SetShown(which == "past")
    if Leyword.SyncEllesmereTabs then
      Leyword.SyncEllesmereTabs(which)
    end
    if which == "guild" and Leyword.RequestSync then
      Leyword.RequestSync()
    end
    if which == "past" then
      Leyword.RefreshHistory()
    end
  end
  puzzleTab:SetScript("OnClick", function()
    if Leyword.review then
      Leyword.focus = "daily"
    end
    ShowPage("puzzle")
    Leyword.Refresh()
  end)
  guildTab:SetScript("OnClick", function()
    ShowPage("guild")
  end)
  pastTab:SetScript("OnClick", function()
    ShowPage("past")
  end)
  today:SetScript("OnClick", function()
    Leyword.review = nil
    Leyword.focus = "daily"
    box:SetText("")
    Leyword.draft = ""
    ShowPage("puzzle")
    Leyword.Refresh()
  end)
  for i = 1, #pastRows do
    pastRows[i]:SetScript("OnClick", function()
      local entry = LeywordDB.history and LeywordDB.history[i]
      if not entry then
        return
      end
      Leyword.review = entry
      box:SetText("")
      Leyword.draft = ""
      ShowPage("puzzle", true)
      Leyword.Refresh()
    end)
  end

  Leyword.frames = {
    main = frame,
    inset = anchor,
    board = board,
    guild = guild,
    tiles = tiles,
    keys = keys,
    keypad = keypad,
    guessBox = box,
    submit = submit,
    share = share,
    another = another,
    today = today,
    feedback = feedback,
    thanks = thanks,
    shareMenu = menu,
    channels = channels,
    back = back,
    puzzleTab = puzzleTab,
    guildTab = guildTab,
    pastTab = pastTab,
    pastRows = pastRows,
    pastEmpty = pastEmpty,
    pastContent = pastContent,
    colorblind = colorblind,
    keyboard = keyboard,
    status = status,
    stats = stats,
    result = result,
    number = number,
    versionWarn = versionWarn,
    guildScroll = scroll,
    guildStatus = guildStatus,
    guildSync = guildSync,
    guildContent = content,
    guildRows = guildRows,
    guildEmpty = empty,
  }
  Leyword.draft = ""
  frame:SetScript("OnShow", function()
    Leyword.Refresh()
  end)
  Leyword.framesBuilt = true
  if Leyword.ApplyBuiltinSkins then
    Leyword.ApplyBuiltinSkins()
  end
  if Leyword.ApplyEllesmere then
    Leyword.ApplyEllesmere()
  end
  if Leyword.RunSkinCallbacks then
    Leyword.RunSkinCallbacks()
  end
  ShowPage("puzzle")
  frame:Hide()
end

function Leyword.Toggle()
  if not Leyword.frames then
    Build()
  end
  local frame = Leyword.frames.main
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
    frame:Raise()
  end
end
