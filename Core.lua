-- Broker_PlayerCoords - Core
-- LDB data broker plugin: zone, subzone, coordinates, sanctuary status, continent.
-- Copyright (C) 2026 artherion77
-- Licensed under the GNU General Public License v2.0 - see LICENSE.

local addonName, ns = ...

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, loaded)
    if event == "ADDON_LOADED" and loaded == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        -- Functionality is wired in here in subsequent steps.
    end
end)
