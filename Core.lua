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

local THROTTLE = 0.5  -- seconds between coord updates while moving
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
        -- PLAYER_ENTERING_WORLD, ZONE_CHANGED*
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
