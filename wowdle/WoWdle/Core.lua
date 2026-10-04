WoWdle = WoWdle or {}

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

function WoWdle.InitDB()
  if type(WoWdleDB) ~= "table" then
    WoWdleDB = {}
  end
  CopyDefaults(WoWdleDB, DEFAULTS)
  if type(WoWdleDB.stats.dist) ~= "table" or #WoWdleDB.stats.dist < 6 then
    WoWdleDB.stats.dist = { 0, 0, 0, 0, 0, 0 }
  end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == "WoWdle" then
    WoWdle.InitDB()
    if WoWdle.PruneGuild then
      WoWdle.PruneGuild()
    end
    loader:UnregisterEvent("ADDON_LOADED")
  elseif event == "PLAYER_LOGIN" then
    pcall(C_ChatInfo.RegisterAddonMessagePrefix, "WOWDLE")
    if WoWdle.RequestSync then
      WoWdle.RequestSync()
    end
  end
end)

function WoWdle_Toggle()
  if not WoWdleDB then
    WoWdle.InitDB()
  end
  if WoWdle.Toggle then
    WoWdle.Toggle()
  end
end

function WoWdle_CompartmentClick()
  WoWdle_Toggle()
end

function WoWdle_CompartmentEnter(a, b)
  local owner = a
  if type(a) ~= "table" then
    owner = b
  end
  if type(owner) ~= "table" then
    return
  end
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:ClearLines()
  GameTooltip:AddLine("WoWdle", 1, 0.82, 0.45)
  GameTooltip:AddLine("Daily word puzzle", 1, 1, 1)
  GameTooltip:Show()
end

function WoWdle_CompartmentLeave()
  GameTooltip:Hide()
end

SLASH_WOWDLE1 = "/wowdle"
SLASH_WOWDLE2 = "/wd"
SlashCmdList.WOWDLE = function(msg)
  if not WoWdleDB then
    WoWdle.InitDB()
  end
  msg = string.lower(msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "noskin" then
    WoWdleDB.settings.useUISkin = false
    print("|cffd4a85aWoWdle|r will keep the Blizzard frame after you reload. EllesmereUI still follows its own skin toggle.")
    return
  elseif msg == "skin" then
    WoWdleDB.settings.useUISkin = true
    print("|cffd4a85aWoWdle|r will match ElvUI and Tukui after you reload.")
    return
  elseif msg == "test" then
    WoWdle.SelfTest()
    return
  end
  WoWdle_Toggle()
end
