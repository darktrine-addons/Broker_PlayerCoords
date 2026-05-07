-- Broker_PlayerCoords - Settings
-- WoW Settings panel registration and saved-variables defaults.
-- Copyright (C) 2026 artherion77
-- Licensed under the GNU General Public License v2.0 - see LICENSE.

local addonName, ns = ...

local defaults = {
    -- Broker Bar
    coordPrecision = 2,      -- decimal places shown for coordinates (0, 1, or 2)
    showZone       = true,   -- show zone name in broker bar text
    showSubzone    = false,  -- show subzone name in broker bar text
    showFacing     = false,  -- append compass direction (N/NE/E/…) after coordinates
    throttle       = 0.5,    -- coordinate update interval while moving (seconds)
    -- Minimap
    showMinimapCoords  = false,  -- coordinate text overlay at bottom of minimap
    showWorldMapCursor = true,   -- cursor coordinates shown on the world map
    -- Tooltip
    showContinent  = true,   -- Continent row in tooltip
    showDifficulty = true,   -- Difficulty row in tooltip
    showIlvl       = true,   -- iLvl row in tooltip (instances only)
}

local sf = CreateFrame("Frame")
sf:RegisterEvent("ADDON_LOADED")
sf:SetScript("OnEvent", function(self, event, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    Broker_PlayerCoordsDB = Broker_PlayerCoordsDB or {}
    local db = Broker_PlayerCoordsDB
    db.minimapIcon = db.minimapIcon or { hide = false }  -- sub-table; managed by LibDBIcon
    for k, v in pairs(defaults) do
        if db[k] == nil then db[k] = v end
    end
    ns.db = db

    -- Register minimap button (LibDBIcon manages show/hide via its own right-click menu).
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)
    if LibDBIcon and ns.broker then
        LibDBIcon:Register("Broker_PlayerCoords", ns.broker, db.minimapIcon)
    end

    -- ── Settings panel ────────────────────────────────────────────────────────

    local category = Settings.RegisterVerticalLayoutCategory("Broker: Coords")

    -- ── Section: Broker Bar ───────────────────────────────────────────────────

    Settings.RegisterInitializer(category,
        CreateSettingsListSectionHeaderInitializer("Broker Bar", nil))

    local function RefreshBar() if ns.UpdateText then ns.UpdateText() end end

    -- Coordinate precision
    local precSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_coordPrecision", "coordPrecision", db,
        Settings.VarType.Number, "Coordinate precision", defaults.coordPrecision)
    precSetting:SetValueChangedCallback(RefreshBar)
    Settings.CreateDropdown(category, precSetting, function()
        local c = Settings.CreateControlTextContainer()
        c:Add(0, "0 decimals (34, 67)")
        c:Add(1, "1 decimal  (34.5, 67.8)")
        c:Add(2, "2 decimals (34.56, 67.89)")
        return c:GetData()
    end, "Number of decimal places shown in the broker bar and tooltip coordinates.")

    -- Show zone name
    local zoneSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showZone", "showZone", db,
        Settings.VarType.Boolean, "Show zone name", defaults.showZone)
    zoneSetting:SetValueChangedCallback(RefreshBar)
    Settings.CreateCheckbox(category, zoneSetting,
        "Show the current zone name in the broker bar text.")

    -- Show subzone name
    local subzoneSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showSubzone", "showSubzone", db,
        Settings.VarType.Boolean, "Show subzone name", defaults.showSubzone)
    subzoneSetting:SetValueChangedCallback(RefreshBar)
    Settings.CreateCheckbox(category, subzoneSetting,
        "Append the subzone name to the broker bar text (e.g. \"Stormwind: Trade District\").")

    -- Show facing direction
    local facingSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showFacing", "showFacing", db,
        Settings.VarType.Boolean, "Show facing direction", defaults.showFacing)
    facingSetting:SetValueChangedCallback(RefreshBar)
    Settings.CreateCheckbox(category, facingSetting,
        "Append an 8-point compass label (N / NE / E …) after the coordinates in the broker bar.")

    -- Update rate while moving
    local throttleSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_throttle", "throttle", db,
        Settings.VarType.Number, "Update rate while moving", defaults.throttle)
    Settings.CreateDropdown(category, throttleSetting, function()
        local c = Settings.CreateControlTextContainer()
        c:Add(0.25, "Fast (4 times/sec)")
        c:Add(0.5,  "Normal (2 times/sec)")
        c:Add(1.0,  "Slow (1 time/sec)")
        return c:GetData()
    end, "How often coordinates update while you are moving.")

    -- ── Section: Minimap ─────────────────────────────────────────────────────

    Settings.RegisterInitializer(category,
        CreateSettingsListSectionHeaderInitializer("Minimap", nil))

    -- Show coordinates near minimap
    local minimapCoordsSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showMinimapCoords", "showMinimapCoords", db,
        Settings.VarType.Boolean, "Show coordinates near minimap", defaults.showMinimapCoords)
    minimapCoordsSetting:SetValueChangedCallback(function()
        if ns.UpdateMinimapText then ns.UpdateMinimapText() end
    end)
    Settings.CreateCheckbox(category, minimapCoordsSetting,
        "Display your current coordinates as a small text overlay at the bottom of the minimap.")

    -- Show cursor coordinates on world map
    local worldMapCursorSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showWorldMapCursor", "showWorldMapCursor", db,
        Settings.VarType.Boolean, "Show cursor coordinates on world map", defaults.showWorldMapCursor)
    Settings.CreateCheckbox(category, worldMapCursorSetting,
        "Display the map coordinates under your cursor while the world map is open.")

    -- ── Section: Tooltip ──────────────────────────────────────────────────────

    Settings.RegisterInitializer(category,
        CreateSettingsListSectionHeaderInitializer("Tooltip", nil))

    -- Show continent
    local contSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showContinent", "showContinent", db,
        Settings.VarType.Boolean, "Show continent", defaults.showContinent)
    Settings.CreateCheckbox(category, contSetting,
        "Show the continent name in the tooltip.")

    -- Show difficulty
    local diffSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showDifficulty", "showDifficulty", db,
        Settings.VarType.Boolean, "Show difficulty", defaults.showDifficulty)
    Settings.CreateCheckbox(category, diffSetting,
        "Show zone or instance difficulty in the tooltip.")

    -- Show item level
    local ilvlSetting = Settings.RegisterAddOnSetting(
        category, addonName .. "_showIlvl", "showIlvl", db,
        Settings.VarType.Boolean, "Show item level", defaults.showIlvl)
    Settings.CreateCheckbox(category, ilvlSetting,
        "Show equipped item level vs recommended in the tooltip (instances only, when data is available).")

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategoryID = category:GetID()
end)
