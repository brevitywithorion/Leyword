-- Reskin contract for ElvUI, Tukui, and anything else.
--
-- WoWdle.RegisterSkin(function(frames) end) runs after the window exists.
-- EventRegistry:RegisterCallback("WoWdle.Skin", function(_, frames) end) does too.
-- WoWdle.GetFrames() returns nil until the window has been opened once.
--
-- frames.main, guessBox, submit, share, back, puzzleTab, guildTab,
-- hardMode, colorblind, guildScroll, tiles[row][col], keys[letter]
--
-- Named frames: WoWdleFrame, WoWdleGuessBox, WoWdleSubmitButton,
-- WoWdleShareButton, WoWdleBackButton, WoWdleGuildScroll,
-- WoWdleHardModeCheck, WoWdleColorblindCheck, WoWdleTile_1_1 .. WoWdleTile_6_5
--
-- Templates: BasicFrameTemplateWithInset, UIPanelButtonTemplate,
-- InputBoxTemplate, UICheckButtonTemplate, UIPanelScrollFrameTemplate, BackdropTemplate.
-- Replace WoWdle.ApplyTile(tile, letter, mark) to paint tiles yourself.
-- Mark is nil, "G", "Y", or "B". LibSharedMedia is not required.
WoWdle = WoWdle or {}

local callbacks = {}

function WoWdle.GetFrames()
  return WoWdle.frames
end

function WoWdle.RegisterSkin(fn)
  if type(fn) ~= "function" then
    return
  end
  callbacks[#callbacks + 1] = fn
  if WoWdle.framesBuilt and WoWdle.frames then
    pcall(fn, WoWdle.frames)
  end
end

local function Try(fn, ...)
  if type(fn) == "function" then
    pcall(fn, ...)
  end
end

function WoWdle.ApplyBuiltinSkins()
  local frames = WoWdle.frames
  if not frames or not WoWdleDB or WoWdleDB.settings.useUISkin == false then
    return
  end
  local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
  if loaded and loaded("ElvUI") then
    local ok, E = pcall(unpack, ElvUI)
    if ok and type(E) == "table" and E.GetModule then
      local skins = E:GetModule("Skins", true)
      if skins then
        Try(skins.HandleFrame, skins, frames.main, true)
        Try(skins.HandleEditBox, skins, frames.guessBox)
        Try(skins.HandleButton, skins, frames.submit)
        Try(skins.HandleButton, skins, frames.share)
        if frames.channels then
          for i = 1, #frames.channels do
            Try(skins.HandleButton, skins, frames.channels[i])
          end
        end
        Try(skins.HandleButton, skins, frames.back)
        Try(skins.HandleButton, skins, frames.puzzleTab)
        Try(skins.HandleButton, skins, frames.guildTab)
        Try(skins.HandleCloseButton, skins, frames.main.CloseButton)
        Try(skins.HandleCheckBox, skins, frames.hardMode)
        Try(skins.HandleCheckBox, skins, frames.colorblind)
        Try(skins.HandleScrollBar, skins, _G.WoWdleGuildScrollScrollBar)
      end
    end
  end
  if loaded and loaded("Tukui") then
    local ok, T = pcall(unpack, Tukui)
    if ok and type(T) == "table" then
      Try(T.SkinFrame, frames.main)
      Try(T.SkinButton, frames.submit)
      Try(T.SkinButton, frames.share)
      if frames.channels then
        for i = 1, #frames.channels do
          Try(T.SkinButton, frames.channels[i])
        end
      end
      Try(T.SkinButton, frames.back)
      Try(T.SkinEditBox, frames.guessBox)
      Try(T.SkinCheckBox, frames.hardMode)
      Try(T.SkinCheckBox, frames.colorblind)
      Try(T.SkinCloseButton, frames.main.CloseButton)
    end
  end
end

function WoWdle.RunSkinCallbacks()
  local frames = WoWdle.frames
  if not frames then
    return
  end
  for i = 1, #callbacks do
    pcall(callbacks[i], frames)
  end
  if EventRegistry and EventRegistry.TriggerEvent then
    pcall(EventRegistry.TriggerEvent, EventRegistry, "WoWdle.Skin", frames)
  end
end

function WoWdle.SyncEllesmereTabs(which)
  local skin = WoWdle.Ellesmere
  local frames = WoWdle.frames
  if not skin or not frames or type(skin.SetTabSelection) ~= "function" then
    return
  end
  if skin.IsEnabled and not skin.IsEnabled() then
    return
  end
  pcall(skin.SetTabSelection, frames.puzzleTab, which == "puzzle")
  pcall(skin.SetTabSelection, frames.guildTab, which == "guild")
end

function WoWdle.ApplyEllesmere(skin)
  skin = skin or WoWdle.Ellesmere
  local frames = WoWdle.frames
  if not skin or not frames then
    return
  end
  if skin.IsEnabled and not skin.IsEnabled() then
    return
  end
  local function call(name, ...)
    if type(skin[name]) == "function" then
      pcall(skin[name], ...)
    end
  end
  call("Shell", frames.main)
  if frames.inset and frames.inset ~= frames.main then
    call("Inset", frames.inset)
  end
  call("CloseButton", frames.main.CloseButton)
  if (skin.apiVersion or 0) >= 3 then
    call("EditBox", frames.guessBox, { padInput = true })
  else
    call("EditBox", frames.guessBox)
  end
  call("Button", frames.submit)
  call("Button", frames.share)
  if frames.channels then
    for i = 1, #frames.channels do
      call("Button", frames.channels[i])
    end
  end
  call("Button", frames.back)
  call("Checkbox", frames.hardMode)
  call("Checkbox", frames.colorblind)
  call("Tab", frames.puzzleTab)
  call("Tab", frames.guildTab)
  call("ScrollBar", frames.guildScroll.ScrollBar or _G.WoWdleGuildScrollScrollBar)
  call("Font", frames.number)
  call("Font", frames.status)
  call("Font", frames.result)
  call("Font", frames.stats)
  call("Font", frames.guildEmpty)
  if not WoWdle._ellesmereLooks and type(skin.OnLooksChanged) == "function" then
    WoWdle._ellesmereLooks = true
    pcall(skin.OnLooksChanged, function()
      if WoWdle.Refresh and WoWdle.frames and WoWdle.frames.main:IsShown() then
        WoWdle.Refresh()
      end
    end)
  end
  WoWdle.SyncEllesmereTabs(WoWdle.page or "puzzle")
end

local function RegisterEllesmere()
  if WoWdle._ellesmereRegistered then
    return
  end
  if not (EllesmereUI and type(EllesmereUI.RegisterSkin) == "function") then
    return
  end
  WoWdle._ellesmereRegistered = true
  EllesmereUI.RegisterSkin("WoWdle", function(skin)
    WoWdle.Ellesmere = skin
    WoWdle.ApplyEllesmere(skin)
  end)
end

RegisterEllesmere()

local ellesmereWatch = CreateFrame("Frame")
ellesmereWatch:RegisterEvent("ADDON_LOADED")
ellesmereWatch:SetScript("OnEvent", function(_, _, name)
  if name == "EllesmereUI" then
    RegisterEllesmere()
    ellesmereWatch:UnregisterEvent("ADDON_LOADED")
  end
end)

