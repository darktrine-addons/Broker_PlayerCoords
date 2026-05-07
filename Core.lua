-- Broker_PlayerCoords - Core
-- LDB data broker plugin: zone, subzone, coordinates, sanctuary status, continent.
-- Copyright (C) 2026 artherion77
-- Licensed under the GNU General Public License v2.0 - see LICENSE.

local addonName, ns = ...

local LDB = LibStub("LibDataBroker-1.1")
local broker = LDB:NewDataObject("Broker_PlayerCoords", {
    type  = "data source",
    label = "Coords",
    icon  = "Interface\\Icons\\INV_Misc_Map_01",
    text  = "...",
})

-- ── tooltip colors ────────────────────────────────────────────────────────────
-- teal for static labels, white for dynamic values, dark-orange for interaction hints
local CL_r, CL_g, CL_b = 0.40, 0.80, 0.80   -- teal   (label)
local CV_r, CV_g, CV_b = 1.00, 1.00, 1.00   -- white  (value)
local CH_r, CH_g, CH_b = 1.00, 0.60, 0.10   -- orange (hint)

local PVP_STATUS = {
    [""]      = { "None",      1.00, 1.00, 1.00 },
    sanctuary = { "Sanctuary", 0.41, 0.80, 0.94 },  -- sky-blue
    friendly  = { "Friendly",  0.10, 1.00, 0.10 },  -- green
    contested = { "Contested", 1.00, 0.70, 0.10 },  -- amber
    hostile   = { "Hostile",   1.00, 0.10, 0.10 },  -- red
    arena     = { "Arena",     1.00, 0.10, 0.10 },
    combat    = { "Combat",    1.00, 0.10, 0.10 },
}

-- Walk the parent-map chain to find the continent name.
local function GetContinentName(mapID)
    local info = mapID and C_Map.GetMapInfo(mapID)
    while info do
        if info.mapType == Enum.UIMapType.Continent then
            return info.name
        end
        if not info.parentMapID or info.parentMapID == 0 then break end
        info = C_Map.GetMapInfo(info.parentMapID)
    end
end

-- ── broker text ───────────────────────────────────────────────────────────────

local THROTTLE = 0.5
local elapsed  = 0
local moving   = false

local function UpdateText()
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos   = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    local zone  = GetZoneText() or ""
    if pos then
        broker.text = ("%s  %.2f, %.2f"):format(zone, pos.x * 100, pos.y * 100)
    elseif zone ~= "" then
        broker.text = zone
    else
        broker.text = "Unknown"
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_INDOORS")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_STARTED_MOVING")
f:RegisterEvent("PLAYER_STOPPED_MOVING")

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_STARTED_MOVING" then
        moving  = true
        elapsed = 0
    elseif event == "PLAYER_STOPPED_MOVING" then
        moving = false
        UpdateText()
    else
        UpdateText()
    end
end)

f:SetScript("OnUpdate", function(self, dt)
    if not moving then return end
    elapsed = elapsed + dt
    if elapsed >= THROTTLE then
        elapsed = 0
        UpdateText()
    end
end)

-- ── tooltip ───────────────────────────────────────────────────────────────────

broker.OnEnter = function(self)
    local mapID     = C_Map.GetBestMapForUnit("player")
    local pos       = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    local zone      = GetZoneText() or ""
    local subzone   = GetSubZoneText() or ""
    local pvpType   = C_PvP.GetZonePVPInfo() or ""
    local pvp       = PVP_STATUS[pvpType] or { pvpType, 1, 1, 1 }
    local continent = GetContinentName(mapID) or "Unknown"

    -- Anchor below the bar when in the top half, above when in the bottom half.
    local _, frameY = self:GetCenter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    if frameY and frameY > (GetScreenHeight() / 2) then
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
    else
        GameTooltip:SetPoint("BOTTOMLEFT", self, "TOPLEFT")
    end

    -- Header: zone (always), subzone on its own line when present and distinct.
    GameTooltip:SetText(zone, CV_r, CV_g, CV_b)
    if subzone ~= "" and subzone ~= zone then
        GameTooltip:AddLine(subzone, CV_r, CV_g, CV_b)
    end

    -- Detail block.
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Continent",   continent,      CL_r, CL_g, CL_b, CV_r,   CV_g,   CV_b  )
    GameTooltip:AddDoubleLine("Status",      pvp[1],         CL_r, CL_g, CL_b, pvp[2], pvp[3], pvp[4])
    if pos then
        local coords = ("%.2f, %.2f"):format(pos.x * 100, pos.y * 100)
        GameTooltip:AddDoubleLine("Coordinates", coords,     CL_r, CL_g, CL_b, CV_r,   CV_g,   CV_b  )
    end

    -- Interaction hints.
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click to open the World Map", CH_r, CH_g, CH_b)

    GameTooltip:Show()
end

broker.OnLeave = function(self)
    GameTooltip:Hide()
end
