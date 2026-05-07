-- Broker_PlayerCoords - Core
-- LDB data broker plugin: zone, subzone, coordinates, sanctuary status, continent.
-- Copyright (C) 2026 artherion77
-- Licensed under the GNU General Public License v2.0 - see LICENSE.

local addonName, ns = ...

local addonVersion = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"

local LDB = LibStub("LibDataBroker-1.1")
local broker = LDB:NewDataObject("Broker_PlayerCoords", {
    type  = "data source",
    label = "Coords",
    icon  = "Interface\\Icons\\INV_Misc_Map_01",
    text  = "...",
})
ns.broker = broker  -- exposed for LibDBIcon registration in Settings.lua

-- ── tooltip colors ────────────────────────────────────────────────────────────
-- teal for static labels, white for dynamic values, dark-orange for interaction hints
local CL_r, CL_g, CL_b = 0.40, 0.80, 0.80   -- teal   (label)
local CV_r, CV_g, CV_b = 1.00, 1.00, 1.00   -- white  (value)
local CH_r, CH_g, CH_b = 1.00, 0.60, 0.10   -- orange (hint keyword)

local PVP_STATUS = {
    [""]      = { "None",      1.00, 1.00, 1.00 },
    sanctuary = { "Sanctuary", 0.41, 0.80, 0.94 },  -- sky-blue
    friendly  = { "Friendly",  0.10, 1.00, 0.10 },  -- green
    contested = { "Contested", 1.00, 0.70, 0.10 },  -- amber
    hostile   = { "Hostile",   1.00, 0.10, 0.10 },  -- red
    arena     = { "Arena",     1.00, 0.10, 0.10 },
    combat    = { "Combat",    1.00, 0.10, 0.10 },
}

-- Instance difficulty color lookup; order matters (Mythic+ before Mythic, Delve before default).
local DIFF_KEYS  = { "Mythic+", "Keystone", "Mythic", "Heroic", "Timewalking", "LFR", "Normal", "Delve", "Follower" }
local DIFF_COLOR = {
    ["Mythic+"]     = { 1.00, 0.80, 0.00 },  -- gold
    ["Keystone"]    = { 1.00, 0.80, 0.00 },  -- gold  (Blizzard's internal name)
    ["Mythic"]      = { 0.80, 0.30, 1.00 },  -- purple
    ["Heroic"]      = { 0.44, 0.64, 1.00 },  -- blue
    ["Timewalking"] = { 0.41, 0.80, 0.94 },  -- sky-blue
    ["LFR"]         = { 0.52, 0.80, 0.52 },  -- green
    ["Normal"]      = { 0.52, 0.80, 0.52 },  -- green
    ["Delve"]       = { 0.94, 0.69, 0.23 },  -- warm amber
    ["Follower"]    = { 0.70, 0.70, 0.70 },  -- grey (NPC-companion content)
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

-- Returns (label, r, g, b) describing zone/instance difficulty, with tier or key level appended.
local function GetZoneDifficulty(mapID)
    local inInstance, instanceType = IsInInstance()
    if inInstance and instanceType ~= "none" then
        local _, _, difficultyID, difficultyName = GetInstanceInfo()
        if difficultyName and difficultyName ~= "" then

            -- Mythic Keystone (M+): append key level.
            if difficultyID == 8 then
                local keystoneLevel = C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo
                                      and C_ChallengeMode.GetActiveKeystoneInfo() or 0
                if keystoneLevel and keystoneLevel > 0 then
                    difficultyName = difficultyName .. "  +" .. keystoneLevel
                end

            -- Delves: append tier or Nemesis label from UI widget.
            elseif difficultyID == 208 then
                local wNormal  = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(6183)
                local wNemesis = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(6184)
                local wNemHard = C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(6185)
                if wNemHard and wNemHard.shownState == 1 then
                    difficultyName = difficultyName .. "  Nemesis+"
                elseif wNemesis and wNemesis.shownState == 1 then
                    difficultyName = difficultyName .. "  Nemesis"
                elseif wNormal and wNormal.shownState == 1 and wNormal.tierText then
                    local tier = tonumber(wNormal.tierText)
                    if tier and tier > 0 then
                        difficultyName = difficultyName .. "  T" .. tier
                    end
                end
            end

            for _, key in ipairs(DIFF_KEYS) do
                if difficultyName:find(key, 1, true) then
                    local c = DIFF_COLOR[key]
                    return difficultyName, c[1], c[2], c[3]
                end
            end
            return difficultyName, CV_r, CV_g, CV_b  -- unknown type → white
        end
    end

    -- Open world: try the map level range.
    local minLvl, maxLvl = C_Map.GetMapLevels(mapID)
    if minLvl and minLvl > 0 then
        local label = (minLvl == maxLvl) and tostring(minLvl)
                      or (minLvl .. " \226\128\147 " .. maxLvl)  -- en-dash
        return label, CV_r, CV_g, CV_b
    end

    return "Scales", CV_r, CV_g, CV_b
end

-- Returns (equippedIlvl, recommendedIlvl|nil) for the current instance.
-- recommendedIlvl comes from C_LFGInfo.GetDungeonInfo via the lfgDungeonID in GetInstanceInfo.
local function GetInstanceIlvlInfo()
    local _, equipped = GetAverageItemLevel()
    local _, _, _, _, _, _, _, _, _, lfgDungeonID = GetInstanceInfo()
    local recommended
    if lfgDungeonID and lfgDungeonID > 0 then
        local info = C_LFGInfo.GetDungeonInfo(lfgDungeonID)
        if info then
            local raw = info.minGearLevel or info.minLevel or nil
            if raw and raw > 0 then recommended = raw end
        end
    end
    return math.floor(equipped), recommended
end

-- Returns (labelSuffix, valueText, r, g, b) for the item level row, or nil when no rec ilvl known.
local function FormatIlvl(equipped, recommended)
    if not recommended then return nil end  -- hide the row entirely when no comparison possible
    local diff = equipped - recommended
    local r, g, b
    if diff >= 0 then
        r, g, b = 0.10, 1.00, 0.10   -- green:  at or above recommended
    elseif diff >= -15 then
        r, g, b = 1.00, 1.00, 0.00   -- yellow: slightly under
    elseif diff >= -30 then
        r, g, b = 1.00, 0.50, 0.00   -- orange: under
    else
        r, g, b = 1.00, 0.10, 0.10   -- red:    severely under
    end
    return "iLvl (rec " .. recommended .. ")", tostring(equipped), r, g, b
end

-- Formats two map-position values (0–1 range) into a coord string using the saved precision.
local function FmtCoords(x, y)
    local p = ns.db and ns.db.coordPrecision or 2
    return ("%." .. p .. "f, %." .. p .. "f"):format(x * 100, y * 100)
end

-- Returns an 8-point compass label for the player's current facing, or nil when unavailable.
-- GetPlayerFacing() returns radians, 0 = North, increasing counter-clockwise (confirmed in-game).
local COMPASS = { "N", "NW", "W", "SW", "S", "SE", "E", "NE" }
local function GetFacingLabel()
    local f = GetPlayerFacing()
    if not f then return nil end
    return COMPASS[(math.floor(f / (math.pi / 4) + 0.5) % 8) + 1]
end

-- ── minimap text overlay ───────────────────────────────────────────────────────

local minimapText  -- FontString; created in SetupMinimapText() on ADDON_LOADED

local function UpdateMinimapText()
    if not minimapText then return end
    local db = ns.db or {}
    if not db.showMinimapCoords then
        minimapText:Hide()
        return
    end
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos   = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if pos then
        minimapText:SetText(FmtCoords(pos.x, pos.y))
        minimapText:Show()
    else
        minimapText:Hide()
    end
end
ns.UpdateMinimapText = UpdateMinimapText

-- ── broker text ───────────────────────────────────────────────────────────────

local elapsed = 0
local moving  = false

local function UpdateText()
    local mapID = C_Map.GetBestMapForUnit("player")
    local pos   = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    local db    = ns.db or {}

    local zone    = db.showZone    ~= false and (GetZoneText()    or "") or ""
    local subzone = db.showSubzone           and (GetSubZoneText() or "") or ""

    -- Build the text label from whichever name parts are enabled.
    local label
    if zone ~= "" and subzone ~= "" and subzone ~= zone then
        label = zone .. ": " .. subzone
    elseif zone ~= "" then
        label = zone
    elseif subzone ~= "" then
        label = subzone
    end

    if pos then
        local coords = FmtCoords(pos.x, pos.y)
        if db.showFacing then
            local dir = GetFacingLabel()
            if dir then coords = coords .. "  " .. dir end
        end
        broker.text = label and (label .. "  " .. coords) or coords
    elseif label then
        broker.text = label
    else
        broker.text = "Unknown"
    end

    UpdateMinimapText()
end
ns.UpdateText = UpdateText  -- exposed so Settings callbacks can refresh the bar immediately

-- ── event frame ───────────────────────────────────────────────────────────────

-- Forward declarations for setup functions defined further below.
local SetupMinimapText, SetupWorldMapCursor

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ZONE_CHANGED")
f:RegisterEvent("ZONE_CHANGED_INDOORS")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_STARTED_MOVING")
f:RegisterEvent("PLAYER_STOPPED_MOVING")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            self:UnregisterEvent("ADDON_LOADED")
            SetupMinimapText()
            SetupWorldMapCursor()
        end
    elseif event == "PLAYER_STARTED_MOVING" then
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
    if elapsed >= (ns.db and ns.db.throttle or 0.5) then
        elapsed = 0
        UpdateText()
    end
end)

-- ── one-time frame setup ──────────────────────────────────────────────────────

SetupMinimapText = function()
    minimapText = Minimap:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    local fontPath = minimapText:GetFont()
    minimapText:SetFont(fontPath, 10, "OUTLINE")
    minimapText:SetTextColor(1, 1, 1)
    minimapText:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 5)
    minimapText:Hide()
end

SetupWorldMapCursor = function()
    local container = WorldMapFrame and WorldMapFrame.ScrollContainer
    if not container then return end

    local cursorText = WorldMapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cursorText:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -8, 8)
    cursorText:SetTextColor(1, 1, 1, 0.9)

    WorldMapFrame:HookScript("OnUpdate", function()
        local db = ns.db or {}
        if not db.showWorldMapCursor then
            cursorText:SetText("")
            return
        end
        local x, y = container:GetNormalizedCursorPosition()
        if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
            cursorText:SetText(FmtCoords(x, y))
        else
            cursorText:SetText("")
        end
    end)
end

-- ── clipboard copy ────────────────────────────────────────────────────────────
-- Fallback when C_Clipboard is unavailable: a standard WoW dialog with a pre-selected
-- EditBox. Built lazily on first use; we own editBox so SetText is always reliable.
local copyFrame
local copyFrameTitle  -- cached reference to the title FontString

local function ShowCopyDialog(text, title)
    if not copyFrame then
        local f = CreateFrame("Frame", "BrokerCoordsCopyFrame", UIParent,
                              "BasicFrameTemplateWithInset")
        f:SetSize(380, 100)
        f:SetPoint("CENTER", 0, 80)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop",  f.StopMovingOrSizing)

        -- Cache the title FontString so we can update it on each call.
        copyFrameTitle = f.TitleText
                      or (f.TitleContainer and f.TitleContainer.TitleText)

        -- Close button already provided by the template; wire it to Hide.
        if f.CloseButton then
            f.CloseButton:SetScript("OnClick", function() f:Hide() end)
        end

        -- Hint line
        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -32)
        hint:SetTextColor(0.6, 0.6, 0.6)
        hint:SetText("Ctrl-C to copy  \226\128\148  Enter or Esc to close")  -- em-dash

        -- EditBox with standard WoW input styling
        local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        eb:SetPoint("TOPLEFT",     f, "TOPLEFT",     16, -52)
        eb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16,  14)
        eb:SetAutoFocus(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEnterPressed",  function() f:Hide() end)

        f.editBox = eb
        copyFrame = f
    end

    if copyFrameTitle then copyFrameTitle:SetText(title or "Copy Coordinates") end
    copyFrame.editBox:SetText(text)
    copyFrame.editBox:HighlightText()
    copyFrame:Show()
    copyFrame.editBox:SetFocus()
end

local function CopyToClipboard(text, title)
    if C_Clipboard and C_Clipboard.SetText then
        C_Clipboard.SetText(text)
    else
        ShowCopyDialog(text, title)
    end
end

-- ── tooltip ───────────────────────────────────────────────────────────────────

broker.OnEnter = function(self)
    local db        = ns.db or {}
    local mapID     = C_Map.GetBestMapForUnit("player")
    local pos       = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    local zone      = GetZoneText() or ""
    local subzone   = GetSubZoneText() or ""
    local pvpType   = C_PvP.GetZonePVPInfo() or ""
    local pvp       = PVP_STATUS[pvpType] or { pvpType, 1, 1, 1 }
    local continent = GetContinentName(mapID) or "Unknown"
    local diffLabel, diffR, diffG, diffB = GetZoneDifficulty(mapID)

    local inInstance, instanceType = IsInInstance()
    inInstance = inInstance and instanceType ~= "none"

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
    if db.showContinent ~= false then
        GameTooltip:AddDoubleLine("Continent",  continent,  CL_r, CL_g, CL_b, CV_r,  CV_g,  CV_b  )
    end
    GameTooltip:AddDoubleLine("Status",     pvp[1],     CL_r, CL_g, CL_b, pvp[2],pvp[3],pvp[4])
    if db.showDifficulty ~= false then
        GameTooltip:AddDoubleLine("Difficulty", diffLabel,  CL_r, CL_g, CL_b, diffR, diffG, diffB )
    end
    if pos then
        GameTooltip:AddDoubleLine("Coordinates", FmtCoords(pos.x, pos.y), CL_r, CL_g, CL_b, CV_r, CV_g, CV_b)
    end

    -- Item level row: only inside instances, only when a recommended ilvl is known, and only if enabled.
    if inInstance and db.showIlvl ~= false then
        local equipped, recommended            = GetInstanceIlvlInfo()
        local ilvlLabel, ilvlValue, ir, ig, ib = FormatIlvl(equipped, recommended)
        if ilvlLabel then
            GameTooltip:AddDoubleLine(ilvlLabel, ilvlValue, CL_r, CL_g, CL_b, ir, ig, ib)
        end
    end

    -- Interaction hints: keyword in orange, description in white.
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Click",            "open the World Map",      CH_r, CH_g, CH_b, CV_r, CV_g, CV_b)
    GameTooltip:AddDoubleLine("Shift-Click",      "share location in chat",  CH_r, CH_g, CH_b, CV_r, CV_g, CV_b)
    GameTooltip:AddDoubleLine("Ctrl-Click",       "copy coordinates",        CH_r, CH_g, CH_b, CV_r, CV_g, CV_b)
    GameTooltip:AddDoubleLine("Ctrl-Shift-Click", "copy /way command",       CH_r, CH_g, CH_b, CV_r, CV_g, CV_b)
    GameTooltip:AddDoubleLine("Shift-RightClick", "open settings",           CH_r, CH_g, CH_b, CV_r, CV_g, CV_b)

    -- Footer: addon name + version, right-aligned, faint grey.
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("", "Broker: Coords  v" .. addonVersion, 0, 0, 0, 0.45, 0.45, 0.45)

    GameTooltip:Show()
end

broker.OnLeave = function(self)
    GameTooltip:Hide()
end

broker.OnClick = function(self, button)
    if button == "RightButton" then
        if IsShiftKeyDown() and ns.settingsCategoryID then
            Settings.OpenToCategory(ns.settingsCategoryID)
        end
        return
    end
    if button ~= "LeftButton" then return end

    if IsControlKeyDown() then
        local mapID = C_Map.GetBestMapForUnit("player")
        local pos   = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            local zone = GetZoneText() or ""
            if IsShiftKeyDown() then
                -- Ctrl+Shift+Click: copy a /way command (TomTom / Blizzard waypoint).
                -- Coordinates are always 2 dp and space-separated (standard /way format).
                local x = ("%.2f"):format(pos.x * 100)
                local y = ("%.2f"):format(pos.y * 100)
                local cmd = zone ~= "" and ("/way " .. zone .. " " .. x .. " " .. y)
                                       or  ("/way " .. x .. " " .. y)
                CopyToClipboard(cmd, "Copy /way Command")
            else
                -- Ctrl+Click: copy plain "Zone x.xx, y.yy" text.
                local text = zone ~= "" and (zone .. " " .. FmtCoords(pos.x, pos.y))
                                        or  FmtCoords(pos.x, pos.y)
                CopyToClipboard(text, "Copy Coordinates")
            end
        end
        return
    end

    if IsShiftKeyDown() then
        -- Build a waypoint hyperlink and insert it into the active chat box.
        local mapID = C_Map.GetBestMapForUnit("player")
        local pos   = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
        if mapID and pos then
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, pos.x, pos.y))
            local hyperlink = C_Map.GetUserWaypointHyperlink()
            C_Map.ClearUserWaypoint()  -- non-destructive: restores no-waypoint state
            if hyperlink then
                local zone    = GetZoneText() or ""
                local subzone = GetSubZoneText() or ""
                local msg = (subzone ~= "" and subzone ~= zone)
                            and (zone .. ": " .. subzone .. " " .. hyperlink)
                            or  (zone .. " " .. hyperlink)
                local editBox = ChatEdit_ChooseBoxForSend()
                ChatEdit_ActivateChat(editBox)
                editBox:Insert(msg)
            end
        end
    else
        ToggleFrame(WorldMapFrame)
    end
end
