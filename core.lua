--
-- KillStream
-- Simple FPS-style kill notification addon for World of Warcraft.
-- Written by atbigelow, originally written by Lifetapt
--
-- Found and updated by me. Be gentle.
--
-- Licensed under the WTFPL.

KillStream = LibStub("AceAddon-3.0"):NewAddon("KillStream", "AceConsole-3.0")
KillStream.TimerFrame = CreateFrame("Frame", "KillStreamTimerFrame", UIParent)
KillStream.TimerFrame:SetScript("OnEvent", function(self, event, ...) KillStream:OnEvent(event, ...); end)
KillStream.TimerFrame:RegisterEvent("VARIABLES_LOADED")

local L = LibStub("AceLocale-3.0"):GetLocale("KillStream", true)

local Core = _G.KillStream
local CombatData = { Units = {} }

local KILLSTREAM_VERSION = "1.0.2"

local UNITFLAG_TYPE_MASK = 0x0000FC00
local UNITFLAG_TYPE_OBJECT = 0x00004000
local UNITFLAG_TYPE_GUARDIAN = 0x00002000
local UNITFLAG_TYPE_PET = 0x00001000
local UNITFLAG_TYPE_NPC = 0x00000800
local UNITFLAG_TYPE_PLAYER = 0x00000400

local UNITFLAG_REACTION_MASK = 0x000000F0
local UNITFLAG_REACTION_HOSTILE = 0x00000040

local UNITFLAG_CONTROL_MASK = 0x00000300
local UNITFLAG_CONTROL_NPC = 0x00000200
local UNITFLAG_CONTROL_PLAYER = 0x00000100

local ONUPDATE_INTERVAL = 0.1

local substring = string.sub
local bit_band = bit.band

KillStream.defaults = {
    profile = {
        enabled = true,
        enableInArenas = true,
        enableInBattlegrounds = true,
        enableInWorldBattlegrounds = false,
        enableInOpenWorld = false,
        enableInDungeons = false,
        lockFrame = false,
        maxKills = 4,
        killDisplayDuration = 15,
        killFadeoutDuration = 1.5,
        killFrameScale = 1.1,
        killFrameGrowthMode = "DOWN",
        killFrameAnchorMode = "LEFT",
        killFrameDesaturateClassIcons = true,
        killFrameDesaturateSkillIcon = false,
        killFramePlayerDeathsOnly = true,
    }
}

function Core:SetupPreferencesDatabase()
    self.db = LibStub("AceDB-3.0"):New("KillStreamData", KillStream.defaults)

    self.Prefs = {
        name = "KillStream",
        handler = KillStream,
        type = "group",
        args = {
            enabled = {
                name = L["Enable KillStream"],
                desc = L["Enables or disables the addon.  While disabled, KillStream will not parse the combat log."],
                type = "toggle",
                order = 1,
                set = function(info, val) Core:SetPreference(info[#info], val); end,
                get = function(info) return self.db.profile.enabled; end
            },
            testButton = {
                name = L["Add Test Kill"],
                desc = L["Adds a fake kill to the kill stream so you can test your preferences."],
                type = "execute",
                order = 2,
                func = function() KillStream.FeedFrame:AddDummyData(); end
            },
            clearButton = {
                name = L["Clear Kill Stream"],
                desc = L["Clears all kills from the kill stream."],
                type = "execute",
                order = 3,
                func = function() KillStream.FeedFrame:ClearKillStream(); end
            },
            toggleBackground = {
                name = L["Toggle Background"],
                desc = L["Toggles a background behind the kill stream, to allow you to position it more accurately."],
                type = "execute",
                order = 4,
                func = function() KillStream.FeedFrame:ToggleBackground(); end
            },
            zone = {
                type = "group",
                name = L["Zone Preferences"],
                desc = L["Allows you to enable or disable KillStream while in specific areas of the game."],
                order = 3,
                args = {
                    enableInArenas = {
                        name = L["Enabled in Arenas"],
                        desc = L["Sets whether or not the addon is enabled in arenas."],
                        type = "toggle",
                        order = 1,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.enableInArenas; end
                    },
                    enableInBattlegrounds = {
                        name = L["Enabled in Battlegrounds"],
                        desc = L["Sets whether or not the addon is enabled in battlegrounds."],
                        type = "toggle",
                        order = 2,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.enableInBattlegrounds; end
                    },
                    enableInOpenWorld = {
                        name = L["Enabled in Open World"],
                        desc = L["Sets whether or not the addon is enabled in the open world."],
                        type = "toggle",
                        order = 3,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.enableInOpenWorld; end
                    },
                    enableInDungeons = {
                        name = L["Enabled in Instances"],
                        desc = L["Sets whether or not the addon is enabled in dungeon and raid instances."],
                        type = "toggle",
                        order = 4,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.enableInDungeons; end
                    },
                },
            },
            killframe = {
                type = "group",
                name = L["Stream Preferences"],
                desc = L["Allows you to modify the appearance and behavior of the kill stream."],
                order = 2,
                args = {
                    lockFrame = {
                        name = L["Lock Kill Stream"],
                        desc = L["Unlock if you want to move the kill stream with your mouse."],
                        type = "toggle",
                        order = 1,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.lockFrame; end
                    },
                    maxKills = {
                        name = L["Max Kill Lines"],
                        desc = L["Sets the maximum number of kills that will be displayed at once."],
                        type = "range",
                        min = 2,
                        max = 10,
                        step = 1,
                        order = 6,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.maxKills; end
                    },
                    killDisplayDuration = {
                        name = L["Kill Display Duration"],
                        desc = L["Sets how long (in seconds) a kill should be shown before it begins to fade out."],
                        type = "range",
                        min = 1,
                        max = 120,
                        softMin = 1,
                        softMax = 30,
                        step = 1,
                        order = 7,
                        set = function(info, val) self.db.profile.killDisplayDuration = val; end,
                        get = function(info) return self.db.profile.killDisplayDuration; end
                    },
                    killFadeoutDuration = {
                        name = L["Kill Fadeout Duration"],
                        desc = L["Sets how long it takes (in seconds) for a kill to fade out."],
                        type = "range",
                        min = 0,
                        max = 5,
                        step = 0.1,
                        bigStep = 0.5,
                        order = 8,
                        set = function(info, val) self.db.profile.killFadeoutDuration = val; end,
                        get = function(info) return self.db.profile.killFadeoutDuration; end
                    },
                    killFrameScale = {
                        name = L["Kill Stream Scale"],
                        desc = L["Sets the size of the kill stream."],
                        type = "range",
                        min = 0.4,
                        max = 3,
                        step = 0.01,
                        bigStep = 0.1,
                        isPercent = true,
                        order = 5,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.killFrameScale; end
                    },
                    killFramePlayerDeathsOnly = {
                        name = L["Only Show Player Deaths"],
                        desc = L["If checked, KillStream will only show kills against players, not NPCs or pets."],
                        type = "toggle",
                        order = 2,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.killFramePlayerDeathsOnly; end
                    },
                    killFrameGrowthMode = {
                        name = L["Growth Direction"],
                        desc = L["Specifies the direction in which the kill stream grows.  If 'Grow Upwards' is selected, new kills will be added at the bottom, pushing older ones up.  For 'Grow Downwards', the opposite is true."],
                        type = "select",
                        values = { UP = L["Grow Upwards"], DOWN = L["Grow Downwards"] },
                        order = 3,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.killFrameGrowthMode; end
                    },
                    killFrameAnchorMode = {
                        name = L["Anchor Mode"],
                        desc = L["Specifies whether kills should be anchored to the left or right side of the kill stream."],
                        type = "select",
                        values = { LEFT = L["Left Side"], RIGHT = L["Right Side"] },
                        order = 4,
                        set = function(info, val) Core:SetPreference(info[#info], val); end,
                        get = function(info) return self.db.profile.killFrameAnchorMode; end
                    },
                    killFrameDesaturateClassIcons = {
                        name = L["Desaturate Class Icons"],
                        desc = L["Specifies whether class icons are desaturated (greyscale)."],
                        type = "toggle",
                        order = 9,
                        set = function(info, val) Core:SetPreference(info[#info], val); KillStream.FeedFrame:UpdateKillStream(); end,
                        get = function(info) return self.db.profile.killFrameDesaturateClassIcons; end
                    },
                    killFrameDesaturateSkillIcon = {
                        name = L["Desaturate Skill Icon"],
                        desc = L["Specifies whether the skill icon is desaturated (greyscale)."],
                        type = "toggle",
                        order = 10,
                        set = function(info, val) Core:SetPreference(info[#info], val); KillStream.FeedFrame:UpdateKillStream(); end,
                        get = function(info) return self.db.profile.killFrameDesaturateSkillIcon; end
                    }
                }
            }
        }
    }

    self.Prefs.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    LibStub("AceConfig-3.0"):RegisterOptionsTable("KillStream", self.Prefs)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("KillStream", "KillStream");
    --self:RegisterChatCommand("KillStream", function() LibStub("AceConfigDialog-3.0"):Open("KillStream"); end)
    --self:RegisterChatCommand("kf", function() LibStub("AceConfigDialog-3.0"):Open("KillStream"); end)
end

function Core:SetPreference(preference, value)
    self.db.profile[preference] = value
    if (preference == "enabled" or string.find(preference, "enableIn") ~= nil) then
        Core:EnteringWorld()
    elseif (preference == "killFrameScale") then
        KillStream.FeedFrame:SetScale(self.db.profile.killFrameScale)
    elseif (preference == "reloadrequired") then --unused
        StaticPopupDialogs["KFRELOADUI"] = {
            text = "One or more modified preferences require the UI to be reloaded.  Reload the UI now?",
            button1 = "Yep, reload",
            button2 = "No, not now",
            OnAccept = function()
                ReloadUI()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("KFRELOADUI")
    elseif (preference == "lockFrame") then
        KillStream.FeedFrame:EnableMouse(not self.db.profile.lockFrame)
    elseif (preference == "maxKills") then
        KillStream.FeedFrame:ClearKillStream()
        KillStream.FeedFrame:InitializeRows()
    elseif (preference == "killFrameGrowthMode" or preference == "killFrameAnchorMode") then
        KillStream.FeedFrame:InitializeRows()
    end
end

function Core:SetEnabled(value)
    Core:PrintDebugLine("KillStream enabled = " .. tostring(value))
    if (value == false) then
        Core.TimerFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    else
        Core.TimerFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end

function Core:OnInitialize()
    SLASH_KILLSTREAMRL1 = "/rl"
    SlashCmdList["KILLSTREAMRL"] = function(msg) ReloadUI(); end

    Core.TimerFrame:SetScript("OnUpdate", KillStream.OnUpdate)

    Core:RegisterEvents()

    Core.PlayerGuid = UnitGUID("player")
    Core.ScheduledTasks = {};
    Core.LastOnUpdate = 0
    Core.LastDamageEvent = 0
    Core:OnUpdate(0)
end

function Core:OnEnable()
end

function Core:OnDisable()
end

function Core:RegisterEvents()
    Core.CurrentTime = GetTime()
    Core.TimerFrame:RegisterEvent("PLAYER_ALIVE")
    Core.TimerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    Core.TimerFrame:RegisterEvent("ADDON_LOADED")
end

function Core:UnregisterEvents()
    Core.TimerFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    Core.TimerFrame:UnregisterEvent("ADDON_LOADED")
end

function Core:OnUpdate(elapsed)
    Core.LastOnUpdate = Core.LastOnUpdate + elapsed
    if (Core.LastOnUpdate < ONUPDATE_INTERVAL) then return; else Core.LastOnUpdate = 0; end

    Core.CurrentTime = GetTime()

    if (#Core.ScheduledTasks > 0) then
        for k, v in pairs(Core.ScheduledTasks) do
            if (v.Time < Core.CurrentTime) then
                v.Task()
                tremove(Core.ScheduledTasks, k)
                break;
            end
        end
    end
end

local loaded = false
function Core:OnEvent(event, ...)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        Core:DispatchCombatEvent(CombatLogGetCurrentEventInfo())
    elseif (event == "ADDON_LOADED") then
        if (loaded == false) then
            loaded = true
            Core:SetupPreferencesDatabase()
            KillStream.FeedFrame:Initialize()
            KillStream.FeedFrame:Show()
            --Core:AddScheduledTask(0, function() Core:AddConsoleMessage("KillStream v" .. KILLSTREAM_VERSION .. " loaded!") Core:AddConsoleMessage("Type /kf for preferences.") end)
        end
    elseif (event == "PLAYER_ENTERING_WORLD") then
        --print(event)
        Core:EnteringWorld()
    end
end

function Core:EnteringWorld()
    if (self.db.profile.enabled) then
        --Arena check
        if (IsActiveBattlefieldArena()) then
            Core:PrintDebugLine("In arena!")
            if (self.db.profile.enableInArenas) then
                Core:SetEnabled(true)
            else
                Core:SetEnabled(false)
            end
            return
        end

        --BG and dungeon check
        local inInstance, instanceType = IsInInstance()
        if (inInstance ~= nil and instanceType == "pvp") then
            Core:PrintDebugLine("In battleground!")
            if (self.db.profile.enableInBattlegrounds) then
                Core:SetEnabled(true)
            else
                Core:SetEnabled(false)
            end
            return
        end

        if (inInstance ~= nil and (instanceType == "party" or instanceType == "raid")) then
            Core:PrintDebugLine("In raid!")
            if (self.db.profile.enableInDungeons) then
                Core:SetEnabled(true)
            else
                Core:SetEnabled(false)
            end
            return
        end

        Core:PrintDebugLine("In open world!")
        --Not in arena, BG, or instance, so assume open world.
        if (self.db.profile.enableInOpenWorld) then
            Core:SetEnabled(true)
        else
            Core:SetEnabled(false)
        end
    else
        Core:SetEnabled(false)
    end
end

function Core:SlashCommand(string)
    Core:PrintDebugLine(string)
end

function Core:PrintLine(msg)
    Core:Print("|cFF9482CAKillStream:|r |cFF8294C9" .. tostring(msg) .. "|r")
end

function Core:PrintDebugLine(msg)
    if (1 == 1) then
        Core:Print(ChatFrame3, "|cFF9482CAKillStream Debug:|r |cFF8294C9" .. tostring(msg) .. "|r")
    end
end

function Core:AddScheduledTask(time, task)
    Core.ScheduledTasks[#Core.ScheduledTasks + 1] = { Time = time, Task = task }
end

function Core:AddConsoleMessage(message)
    Core:PrintDebugLine("Adding startup line.")
    local kill
    kill = {
        ["IsMessage"] = true,
        ["Message"] = message,
        ["LastAttackerGuid"] = UnitGUID("player"),
    }
    local display = self.db.profile.killDisplayDuration
    self.db.profile.killDisplayDuration = 5
    Core.FeedFrame:AddKillLine(kill)
    self.db.profile.killDisplayDuration = display
end



--====================
--|Combat Event Class|
--====================

--Unit definition
--====================
--UnitGuid
--UnitName
--UnitFlags

--LastAttackerGuid
--LastAttackerName
--LastAttackerType
--LastAttackTime
--SpellId
--SpellName
--SpellSchool
--IsCritical
--IsEnvironmental
--KillTime

--====================
--|Combat Log Parsing|
--====================

function Core:DispatchCombatEvent(timestamp, event_name, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
    if (event_name == "SWING_DAMAGE") then
        Core:ProcessDamageEvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, -1, "Melee", 1, Core:ToBoolean(select(7, ...)), false)
    elseif (event_name == "RANGE_DAMAGE" or event_name == "SPELL_DAMAGE" or event_name == "SPELL_PERIODIC_DAMAGE") then
        Core:ProcessDamageEvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, select(1, ...), select(2, ...), select(3, ...), Core:ToBoolean(select(10, ...)), false)
    elseif (event_name == "ENVIRONMENT_DAMAGE") then
        Core:ProcessDamageEvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, -2, "Falling", 1, false, true)
    elseif (event_name == "UNIT_DIED") then
        Core:ProcessKill(destGUID)
    end
end

function Core:ProcessDamageEvent(sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, isCritical, isEnvironmental)
    local destUnitType = bit_band(destFlags, UNITFLAG_TYPE_MASK)

    if (self.db.profile.killFramePlayerDeathsOnly) then
        if (destUnitType ~= UNITFLAG_TYPE_PLAYER) then return; end
    end

    if (CombatData.Units[destGUID] == nil) then
        Core:NewUnit(destGUID, destName, destFlags)
    end

    -- "playerGUID" keeps seeping through the events, so try to filter this here?
    if (sourceGUID == "playerGUID") then
        sourceGUID = UnitGUID("player")
    end
    Core:UpdateLastAttacker(destGUID, sourceGUID, sourceName, sourceFlags, spellID, spellName, spellSchool, isCritical, isEnvironmental)

    Core:PrintDebugLine("|cFFFFFFFFTime:|r" .. tostring(timestamp) .. "\n|cFFFFFFFFType:|r" .. tostring(type) .. " \n|cFFFFFFFFSourceName:|r " .. tostring(sourceName) .. " 	\n|cFFFFFFFFSourceFlags:|r " .. tostring(sourceFlags) .. " \n|cFFFFFFFFDestName:|r " .. tostring(destName) .. " \n|cFFFFFFFFDestFlags:|r " .. tostring(destFlags) .. " \n|cFFFFFFFF")
end

function Core:ProcessKill(destGUID)
    if (CombatData.Units[destGUID] == nil) then return; end

    CombatData.Units[destGUID].KillTime = Core.CurrentTime

    Core:AddScheduledTask(Core.CurrentTime + 0.1, function() KillStream:UpdateKillStream(destGUID); end)
end

function Core:UpdateKillStream(unitGuid)
    Core.FeedFrame:AddKillLine(CombatData.Units[unitGuid])
end

function Core:NewUnit(unitGuid, unitName, unitFlags)
    CombatData.Units[unitGuid] = {}
    CombatData.Units[unitGuid].UnitGuid = unitGuid
    CombatData.Units[unitGuid].UnitName = unitName
    CombatData.Units[unitGuid].UnitFlags = unitFlags

    Core:PrintDebugLine("Added new unit! " .. unitName)
end

function Core:UpdateLastAttacker(victimGuid, attackerGuid, attackerName, attackerFlags, spellId, spellName, spellSchool, isCritical, isEnvironmental)
    CombatData.Units[victimGuid].LastAttackerGuid = attackerGuid
    CombatData.Units[victimGuid].LastAttackerName = attackerName
    CombatData.Units[victimGuid].LastAttackerFlags = attackerFlags
    CombatData.Units[victimGuid].LastAttackTime = Core.CurrentTime
    CombatData.Units[victimGuid].SpellId = spellId
    CombatData.Units[victimGuid].SpellName = spellName
    CombatData.Units[victimGuid].SpellSchool = spellSchool
    CombatData.Units[victimGuid].IsCritical = isCritical
    CombatData.Units[victimGuid].IsEnvironmental = isEnvironmental
end


--===============
--|Utility stuff|
--===============

function Core:GetSpellSchoolArgb(spellSchool)
    local c = COMBATLOG_DEFAULT_COLORS.schoolColoring[spellSchool]
    if (c == nil) then
        return { a = 1, r = 1, g = 1, b = 1 }
    else
        return c
    end
end

function Core:GetClassColor(class)
    local r, g, b
    if (class ~= nil and class ~= "UNKNOWN") then
        r = RAID_CLASS_COLORS[class].r;
        g = RAID_CLASS_COLORS[class].g;
        b = RAID_CLASS_COLORS[class].b;
    else
        r = 1;
        g = 1;
        b = 1;
    end
    return r, g, b
end

function Core:GetColorEscapeString(r, g, b)
    r = r <= 1 and r >= 0 and r or 0
    g = g <= 1 and g >= 0 and g or 0
    b = b <= 1 and b >= 0 and b or 0
    return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

function string.starts(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

function string.ends(str, ends)
    return string.sub(str, string.len(str) - (string.len(ends) - 1)) == ends
end

function Core:Round(value, decimalplaces)
    local mult = 10 ^ (decimalplaces or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Core:ToBoolean(val)
    if val == 1 or tostring(val) == "1" then return (true);
    end
    if val == nil then return (false);
    end
    if type(val) == "boolean" then return (val);
    end
end

-- This is comma_value() by Richard Warburton from: http://lua-users.org/wiki/FormattingNumbers with slight modifications (and a bug fix)
function Core:FormatNumber(n)
    n = ("%.0f"):format(n)
    local left, num, right = string.match(n, '^([^%d]*%d)(%d+)(.-)$')
    return left and left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) or n --..right
end

-- Based on cck's numeric Short code in DogTag-3.0.
function Core:ShortNumber(value)
    if value >= 10000000 or value <= -10000000 then
        return ("%.1fm"):format(value / 1000000)
    elseif value >= 1000000 or value <= -1000000 then
        return ("%.2fm"):format(value / 1000000)
    elseif value >= 100000 or value <= -100000 then
        return ("%.0fk"):format(value / 1000)
    elseif value >= 10000 or value <= -10000 then
        return ("%.1fk"):format(value / 1000)
    else
        return math_floor(value + 0.5) .. ''
    end
end

function Core:ApplyFont(fontstring, fSize, fFlags)
    local font, height, flags = fontstring:GetFont()
    if (fSize) then height = fSize;
    end
    if (fFlags) then flags = fFlags;
    end
    fontstring:SetFont("Interface\\AddOns\\KillStream\\res\\PT_Sans_Narrow.ttf", height, flags)
end

function Core:tcount(tab)
    local n = #tab
    if (n == 0) then
        for _ in pairs(tab) do
            n = n + 1
        end
    end
    return n
end

function Core:DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end

    return _copy(object)
end