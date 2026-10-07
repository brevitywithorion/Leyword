-- Reskin contract for ElvUI, Tukui, and anything else.
--
-- Leyword.RegisterSkin(function(frames) end) runs after the window exists.
-- EventRegistry:RegisterCallback("Leyword.Skin", function(_, frames) end) does too.
-- Leyword.GetFrames() returns nil until the window has been opened once.
--
-- frames.main, guessBox, submit, share, back, puzzleTab, guildTab,
-- hardMode, colorblind, guildScroll, tiles[row][col], keys[letter]
--
-- Named frames: LeywordFrame, LeywordGuessBox, LeywordSubmitButton,
-- LeywordShareButton, LeywordBackButton, LeywordGuildScroll,
-- LeywordHardModeCheck, LeywordColorblindCheck, LeywordTile_1_1 .. LeywordTile_6_5
--
-- Templates: BasicFrameTemplateWithInset, UIPanelButtonTemplate,
-- InputBoxTemplate, UICheckButtonTemplate, UIPanelScrollFrameTemplate, BackdropTemplate.
-- Replace Leyword.ApplyTile(tile, letter, mark) to paint tiles yourself.
-- Mark is nil, "G", "Y", or "B". LibSharedMedia is not required.
Leyword = Leyword or {}

local callbacks = {}

function Leyword.GetFrames()
  return Leyword.frames
end

function Leyword.RegisterSkin(fn)
  if type(fn) ~= "function" then
    return
  end
  callbacks[#callbacks + 1] = fn
  if Leyword.framesBuilt and Leyword.frames then
    pcall(fn, Leyword.frames)
  end
end

local function Try(fn, ...)
  if type(fn) == "function" then
    pcall(fn, ...)
  end
end

function Leyword.ApplyBuiltinSkins()
  local frames = Leyword.frames
  if not frames or not LeywordDB or LeywordDB.settings.useUISkin == false then
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
        Try(skins.HandleButton, skins, frames.another)
        Try(skins.HandleButton, skins, frames.today)
        Try(skins.HandleButton, skins, frames.feedback)
        Try(skins.HandleButton, skins, frames.thanks)
        if frames.channels then
          for i = 1, #frames.channels do
            Try(skins.HandleButton, skins, frames.channels[i])
          end
        end
        Try(skins.HandleButton, skins, frames.back)
        Try(skins.HandleButton, skins, frames.puzzleTab)
        Try(skins.HandleButton, skins, frames.guildTab)
        Try(skins.HandleButton, skins, frames.pastTab)
        Try(skins.HandleCloseButton, skins, frames.main.CloseButton)
        Try(skins.HandleCheckBox, skins, frames.colorblind)
        Try(skins.HandleCheckBox, skins, frames.keyboard)
        Try(skins.HandleScrollBar, skins, _G.LeywordGuildScrollScrollBar)
      end
    end
  end
  if loaded and loaded("Tukui") then
    local ok, T = pcall(unpack, Tukui)
    if ok and type(T) == "table" then
      Try(T.SkinFrame, frames.main)
      Try(T.SkinButton, frames.submit)
      Try(T.SkinButton, frames.share)
      Try(T.SkinButton, frames.another)
      Try(T.SkinButton, frames.today)
      Try(T.SkinButton, frames.feedback)
      Try(T.SkinButton, frames.thanks)
      if frames.channels then
        for i = 1, #frames.channels do
          Try(T.SkinButton, frames.channels[i])
        end
      end
      Try(T.SkinButton, frames.back)
      Try(T.SkinEditBox, frames.guessBox)
      Try(T.SkinCheckBox, frames.colorblind)
      Try(T.SkinCheckBox, frames.keyboard)
      Try(T.SkinCloseButton, frames.main.CloseButton)
    end
  end
end

function Leyword.RunSkinCallbacks()
  local frames = Leyword.frames
  if not frames then
    return
  end
  for i = 1, #callbacks do
    pcall(callbacks[i], frames)
  end
  if EventRegistry and EventRegistry.TriggerEvent then
    pcall(EventRegistry.TriggerEvent, EventRegistry, "Leyword.Skin", frames)
  end
end

function Leyword.SyncEllesmereTabs(which)
  local skin = Leyword.Ellesmere
  local frames = Leyword.frames
  if not skin or not frames or type(skin.SetTabSelection) ~= "function" then
    return
  end
  if skin.IsEnabled and not skin.IsEnabled() then
    return
  end
  pcall(skin.SetTabSelection, frames.puzzleTab, which == "puzzle")
  pcall(skin.SetTabSelection, frames.guildTab, which == "guild")
  pcall(skin.SetTabSelection, frames.pastTab, which == "past")
end

function Leyword.ApplyEllesmere(skin)
  skin = skin or Leyword.Ellesmere
  local frames = Leyword.frames
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
  call("Button", frames.another)
  call("Button", frames.today)
  call("Button", frames.feedback)
  call("Button", frames.thanks)
  if frames.channels then
    for i = 1, #frames.channels do
      call("Button", frames.channels[i])
    end
  end
  call("Button", frames.back)
  call("Checkbox", frames.colorblind)
  call("Checkbox", frames.keyboard)
  call("Tab", frames.puzzleTab)
  call("Tab", frames.guildTab)
  call("Tab", frames.pastTab)
  call("ScrollBar", frames.guildScroll.ScrollBar or _G.LeywordGuildScrollScrollBar)
  call("Font", frames.number)
  call("Font", frames.status)
  call("Font", frames.result)
  call("Font", frames.stats)
  call("Font", frames.guildEmpty)
  if not Leyword._ellesmereLooks and type(skin.OnLooksChanged) == "function" then
    Leyword._ellesmereLooks = true
    pcall(skin.OnLooksChanged, function()
      if Leyword.Refresh and Leyword.frames and Leyword.frames.main:IsShown() then
        Leyword.Refresh()
      end
    end)
  end
  Leyword.SyncEllesmereTabs(Leyword.page or "puzzle")
end

local function RegisterEllesmere()
  if Leyword._ellesmereRegistered then
    return
  end
  if not (EllesmereUI and type(EllesmereUI.RegisterSkin) == "function") then
    return
  end
  Leyword._ellesmereRegistered = true
  EllesmereUI.RegisterSkin("Leyword", function(skin)
    Leyword.Ellesmere = skin
    Leyword.ApplyEllesmere(skin)
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

