Leyword = Leyword or {}

local button = CreateFrame("Button", "LeywordMinimapButton", Minimap)
button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("AnyUp")
button:RegisterForDrag("LeftButton")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetPoint("CENTER", 0, 1)
icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local ring = button:CreateTexture(nil, "OVERLAY")
ring:SetSize(53, 53)
ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
ring:SetPoint("TOPLEFT")

local dragging = false

local function Angle()
  local saved = LeywordDB and LeywordDB.minimap
  local angle = saved and saved.angle
  if type(angle) ~= "number" then
    return 225
  end
  return angle
end

local function Place()
  if button:GetParent() ~= Minimap then
    return
  end
  local radius = (Minimap:GetWidth() / 2) + 5
  local rad = math.rad(Angle())
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * radius, math.sin(rad) * radius)
end

local function SaveAngle()
  if not LeywordDB then
    return
  end
  if type(LeywordDB.minimap) ~= "table" then
    LeywordDB.minimap = {}
  end
  local scale = Minimap:GetEffectiveScale()
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  cx, cy = cx / scale, cy / scale
  LeywordDB.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
end

button:SetScript("OnDragStart", function(self)
  if self:GetParent() ~= Minimap then
    return
  end
  dragging = true
  self:SetScript("OnUpdate", function()
    SaveAngle()
    Place()
  end)
end)

button:SetScript("OnDragStop", function(self)
  self:SetScript("OnUpdate", nil)
  SaveAngle()
  Place()
end)

button:SetScript("OnMouseUp", function()
  if dragging then
    dragging = false
    return
  end
  Leyword_Toggle()
end)

button:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:ClearLines()
  GameTooltip:AddLine("Leyword", 1, 0.82, 0.45)
  GameTooltip:AddLine("Daily word puzzle", 1, 1, 1)
  GameTooltip:AddLine("Drag to move.", 0.7, 0.7, 0.7)
  GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

local function RegisterBroker()
  if Leyword._broker or not LibStub then
    return
  end
  local ok, ldb = pcall(LibStub, "LibDataBroker-1.1", true)
  if not ok or type(ldb) ~= "table" or type(ldb.NewDataObject) ~= "function" then
    return
  end
  Leyword._broker = ldb:NewDataObject("Leyword", {
    type = "launcher",
    text = "Leyword",
    icon = "Interface\\Icons\\INV_Misc_Book_09",
    OnClick = function()
      Leyword_Toggle()
    end,
    OnTooltipShow = function(tip)
      if not tip then
        return
      end
      tip:AddLine("Leyword", 1, 0.82, 0.45)
      tip:AddLine("Daily word puzzle", 1, 1, 1)
    end,
  })
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name ~= "Leyword" then
    return
  end
  Place()
  RegisterBroker()
  if event == "PLAYER_LOGIN" then
    watcher:UnregisterEvent("PLAYER_LOGIN")
  end
end)

Place()
