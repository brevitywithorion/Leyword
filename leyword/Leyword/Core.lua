Leyword = Leyword or {}

local DEFAULTS = {
  settings = {
    hardMode = false,
    colorblind = false,
    useUISkin = true,
    point = nil,
  },
  stats = {
    played = 0,
    wins = 0,
    streak = 0,
    maxStreak = 0,
    lastDate = nil,
    dist = { 0, 0, 0, 0, 0, 0 },
  },
  current = nil,
  guild = {},
  lastQuery = 0,
}

local function CopyDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then
        dst[k] = {}
      end
      CopyDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

function Leyword.InitDB()
  if type(LeywordDB) ~= "table" then
    LeywordDB = {}
  end
  CopyDefaults(LeywordDB, DEFAULTS)
  if type(LeywordDB.stats.dist) ~= "table" or #LeywordDB.stats.dist < 6 then
    LeywordDB.stats.dist = { 0, 0, 0, 0, 0, 0 }
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "Leyword" then
    Leyword.InitDB()
    if Leyword.PruneGuild then
      Leyword.PruneGuild()
    end
    loader:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_LOGIN" then
    pcall(C_ChatInfo.RegisterAddonMessagePrefix, "LEYWORD")
    if Leyword.RequestSync then
      Leyword.RequestSync()
    end
  end
end)

function Leyword_Toggle()
  if not LeywordDB then
    Leyword.InitDB()
  end
  if Leyword.Toggle then
    Leyword.Toggle()
  end
end

function Leyword_CompartmentClick()
  Leyword_Toggle()
end

function Leyword_CompartmentEnter(a, b)
  local owner = a
  if type(a) ~= "table" then
    owner = b
  end
  if type(owner) ~= "table" then
    return
  end
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:ClearLines()
  GameTooltip:AddLine("Leyword", 1, 0.82, 0.45)
  GameTooltip:AddLine("Daily word puzzle", 1, 1, 1)
  GameTooltip:Show()
end

function Leyword_CompartmentLeave()
  GameTooltip:Hide()
end

SLASH_LEYWORD1 = "/leyword"
SLASH_LEYWORD2 = "/lw"
SlashCmdList.LEYWORD = function(msg)
  if not LeywordDB then
    Leyword.InitDB()
  end
  msg = string.lower(msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "noskin" then
    LeywordDB.settings.useUISkin = false
    print("|cffd4a85aLeyword|r will keep the Blizzard frame after you reload. EllesmereUI still follows its own skin toggle.")
    return
  elseif msg == "skin" then
    LeywordDB.settings.useUISkin = true
    print("|cffd4a85aLeyword|r will match ElvUI and Tukui after you reload.")
    return
  elseif msg == "test" then
    Leyword.SelfTest()
    return
  end
  Leyword_Toggle()
end
