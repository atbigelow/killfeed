--
-- Created by IntelliJ IDEA.
-- User: Victor
-- Date: 8/6/12
-- Time: 7:56 PM
-- To change this template use File | Settings | File Templates.
--

local Core = KillStream

KillStream.FeedFrame = CreateFrame("Frame", "KillStreamMainFrame", UIParent)
local frame = KillStream.FeedFrame
frame.LastOnUpdate = 0
frame:SetScript("OnShow", function(...) KillStream.FeedFrame:OnShow() end)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:Hide()

--This should be made local before releasing.
KillLines = {}

local KILLSTREAM_WIDTH = 200
local KILLSTREAM_LINEHEIGHT = 20
local KILLSTREAM_MAXITEMS = 5

local bit_band = bit.band

local UNITFLAG_TYPE_MASK = 0x0000FC00
local UNITFLAG_TYPE_OBJECT = 0x00004000
local UNITFLAG_TYPE_GUARDIAN = 0x00002000
local UNITFLAG_TYPE_PET = 0x00001000
local UNITFLAG_TYPE_NPC = 0x00000800
local UNITFLAG_TYPE_PLAYER = 0x00000400

local UNITFLAG_REACTION_MASK = 0x000000F0
local UNITFLAG_REACTION_HOSTILE = 0x00000040
local UNITFLAG_REACTION_FRIEND = 0x00000010

local UNITFLAG_CONTROL_MASK = 0x00000300
local UNITFLAG_CONTROL_NPC = 0x00000200
local UNITFLAG_CONTROL_PLAYER = 0x00000100

local PlayerIsAlliance = false

local frameCreated = false

function frame:Initialize()
    local _, faction = UnitFactionGroup("player")
    if (faction == "Alliance") then PlayerIsAlliance = true; end

    KILLSTREAM_MAXITEMS = Core.db.profile.maxKills

    -- Set up container frame
    frame:EnableMouse(not Core.db.profile.lockFrame)
    frame:SetMovable(true)
    frame:SetScale(Core.db.profile.killFrameScale)
    frame:SetSize(KILLSTREAM_WIDTH, KILLSTREAM_LINEHEIGHT * KILLSTREAM_MAXITEMS + 10)
    if (not frame:IsUserPlaced()) then frame:ClearAllPoints(); frame:SetPoint("BOTTOMRIGHT", -120, 50) else frame:SetPoint("CENTER") end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(...) KillStream.FeedFrame:OnDragStart() end)
    frame:SetScript("OnDragStop", function(...) KillStream.FeedFrame:OnDragStop() end)
    frame.texture = frame:CreateTexture()
    frameCreated = true

    -- Set up rows
    frame.ListRows = {}
    frame:InitializeRows()
end

function frame:InitializeRows()
    --Creates the rows, anchors them to the frame, and anchors their compontents to each other
    --Rows are only created once, even if the user changes the maxKills setting.
    KILLSTREAM_MAXITEMS = Core.db.profile.maxKills
    frame:SetSize(KILLSTREAM_WIDTH, KILLSTREAM_LINEHEIGHT * KILLSTREAM_MAXITEMS + 10)

    for i = 1, ((KILLSTREAM_MAXITEMS > #frame.ListRows) and KILLSTREAM_MAXITEMS or #frame.ListRows) do
        if (frame.ListRows[i] == nil) then
            local row = CreateFrame("Frame", "$parentRow" .. i, frame)

            row.AttackerClassIcon = row:CreateTexture()
            row.AttackerClassIcon:SetSize(KILLSTREAM_LINEHEIGHT - 2, KILLSTREAM_LINEHEIGHT - 2)
            row.AttackerClassIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            local coords = CLASS_ICON_TCOORDS["MAGE"];
            row.AttackerClassIcon:SetTexCoord(unpack(coords))
            row.AttackerClassIcon:SetDesaturated(Core.db.profile.killFrameDesaturateClassIcons)


            row.AttackerName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.AttackerName:SetText("Testattacker")
            row.AttackerName:SetTextColor(1, 1, 1)
            Core:ApplyFont(row.AttackerName, KILLSTREAM_LINEHEIGHT - 8)

            row.SpellIcon = row:CreateTexture()
            row.SpellIcon:SetSize(KILLSTREAM_LINEHEIGHT - 2, KILLSTREAM_LINEHEIGHT - 2)
            row.SpellIcon:SetTexture("Interface\\Icons\\spell_frost_frostbolt02")
            row.SpellIcon:SetDesaturated(Core.db.profile.killFrameDesaturateSkillIcon)


            row.VictimName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.VictimName:SetText("Testvictim")
            row.VictimName:SetTextColor(1, 1, 1)
            Core:ApplyFont(row.VictimName, KILLSTREAM_LINEHEIGHT - 8)

            row.VictimClassIcon = row:CreateTexture()
            row.VictimClassIcon:SetSize(KILLSTREAM_LINEHEIGHT - 2, KILLSTREAM_LINEHEIGHT - 2)
            row.VictimClassIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            local coords = CLASS_ICON_TCOORDS["SHAMAN"];
            row.VictimClassIcon:SetTexCoord(unpack(coords))
            row.VictimClassIcon:SetDesaturated(Core.db.profile.killFrameDesaturateClassIcons)

            row:SetHeight(KILLSTREAM_LINEHEIGHT)
            row:SetWidth(KILLSTREAM_WIDTH)
            frame.ListRows[i] = row
        end

        local row = frame.ListRows[i]

        if (i > KILLSTREAM_MAXITEMS) then
            row:ClearAllPoints()
        end

        row.VictimClassIcon:ClearAllPoints()
        row.VictimName:ClearAllPoints()
        row.SpellIcon:ClearAllPoints()
        row.AttackerName:ClearAllPoints()
        row.AttackerClassIcon:ClearAllPoints()

        if (Core.db.profile.killFrameAnchorMode == "RIGHT") then
            row.VictimClassIcon:SetPoint("TOPRIGHT", row)
            row.VictimName:SetPoint("TOPRIGHT", row.VictimClassIcon, "TOPLEFT", -4, -3)
            row.SpellIcon:SetPoint("TOPRIGHT", row.VictimName, "TOPLEFT", -4, 3)
            row.AttackerName:SetPoint("TOPRIGHT", row.SpellIcon, "TOPLEFT", -4, -3)
            row.AttackerClassIcon:SetPoint("TOPRIGHT", row.AttackerName, "TOPLEFT", -4, 3)
        else
            row.AttackerClassIcon:SetPoint("TOPLEFT", row)
            row.AttackerName:SetPoint("TOPLEFT", row.AttackerClassIcon, "TOPRIGHT", 4, -3)
            row.SpellIcon:SetPoint("TOPLEFT", row.AttackerName, "TOPRIGHT", 4, 3)
            row.VictimName:SetPoint("TOPLEFT", row.SpellIcon, "TOPRIGHT", 4, -3)
            row.VictimClassIcon:SetPoint("TOPLEFT", row.VictimName, "TOPRIGHT", 4, 3)
        end

        if (Core.db.profile.killFrameGrowthMode == "UP") then
            row:ClearAllPoints()
            if i == 1 then
                row:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 5)
            else
                row:SetPoint("BOTTOMLEFT", frame.ListRows[i - 1], "TOPLEFT", 0, 0)
            end
        else

            row:ClearAllPoints()
            if i == 1 then
                row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -5)
            else
                row:SetPoint("TOPLEFT", frame.ListRows[i - 1], "BOTTOMLEFT", 0, 0)
            end
        end
    end
end

function frame:ToggleBackground()
    if (frame.texture:GetNumPoints() == 0) then
        frame.texture:SetAllPoints(frame)
        frame.texture:SetTexture(0, 0, 0, 0.75)
    else
        frame.texture:ClearAllPoints()
        frame.texture:SetTexture(0, 0, 0, 0.0)
    end
end

function frame:OnShow()
    if (not frameCreated) then
        frame:Initialize()
    end
    frame:UpdateKillStream()
end

function frame:OnDragStart()
    frame:StartMoving()
end

function frame:OnDragStop()
    frame:StopMovingOrSizing()
    frame:SetUserPlaced(true)
end

function frame:AddKillLine(kill)
    if (string.ends(kill.LastAttackerGuid, "00000")) then
        --Someimes the combat log bugs out and returns invalid all-zero Guids.  If this value
        --is ever passed to GetPlayerInfoByGUID (such as in the update function) the API
        --throws a usage error and breaks execution.  So we need to make sure bugged kills
        --don't get that far.
        Core:AddConsoleMessage(string.format("|cFFFF0000Bad unit guid!|r|cFFFFFFFF %s [%s] %s", kill.UnitName, kill.SpellName, kill.LastAttackerName))
        Core:AddConsoleMessage("|cFFFFFFFFType /reload if this is ocurring frequently.")
        return
    end

    if (#KillLines >= KILLSTREAM_MAXITEMS) then
        tremove(KillLines, #KillLines)
    end

    tinsert(KillLines, 1, kill)

    --Since animations are tied to a row, and rows change if new killlines are added, we
    --need to re-assign any currently playing animations to their new rows.  This is done
    --by cancelling the animation, creating a new one (setting the Duration and Change
    --values according to the old animation's progress) and assigning it to the new row.
    for i = #KillLines, 1, -1 do
        if (frame.ListRows[i].anim ~= nil) then
            local remainingTime = (1 - frame.ListRows[i].anim:GetProgress()) * frame.ListRows[i].anim:GetDuration()
            local alpha = frame.ListRows[i]:GetAlpha()
            frame.ListRows[i].anim:Stop()
            frame.ListRows[i].anim = nil
            frame.ListRows[i]:SetAlpha(1)

            --Now, re-assign animations to their new (shifted up) rows
            if (i < KILLSTREAM_MAXITEMS) then
                local animation = frame:CreateFadeOutAnimation(frame.ListRows[i + 1])
                frame.ListRows[i + 1]:SetAlpha(alpha)
                animation:GetAnimations():SetFromAlpha(alpha)
                animation:GetAnimations():SetDuration(remainingTime)
                frame.ListRows[i + 1].anim = animation
                frame.ListRows[i + 1].anim:Play()
            end
        end
    end

    frame:UpdateKillStream()

    --We use my own ghetto timer system to schedule the fadeout after the user-configured delay.
    --One day I'll move it over to AceTimer.
    Core:AddScheduledTask(Core.CurrentTime + Core.db.profile.killDisplayDuration, function() frame:FadeOutKillLine(kill);
    end)
end

function frame:RemoveKillLine(kill)
    for i = KILLSTREAM_MAXITEMS, 1, -1 do
        if (KillLines[i] == kill) then
            tremove(KillLines, i)
            break
        end
    end
end

function frame:FadeOutKillLine(kill)
    --Starts the animation for a killine.  The row itself is not used as the argument, since
    --if a new kill is added to the feed before this function is called, the wrong row would
    --be animated.
    local row
    for i = KILLSTREAM_MAXITEMS, 1, -1 do
        if (frame.ListRows[i].killref == kill) then
            row = frame.ListRows[i]
        end
    end

    --Check if row doesn't exist because the kill was pushed off by newer ones
    if (row == nil) then return; end

    local animation = frame:CreateFadeOutAnimation(row)
    row.anim = animation
    row.anim:Play()
end

function frame:CreateFadeOutAnimation(parentFrame)
    --Creates a standard fadeout animation starting from 1 and animating to 0
    local animation = parentFrame:CreateAnimationGroup()
    local fadeout = animation:CreateAnimation("Alpha")
    fadeout:SetFromAlpha(1)
    local duration = Core.db.profile.killFadeoutDuration

    --True 0 durations cause the animation to not play at all (and not fire OnFinished)
    if (duration == 0) then
        duration = 0.01
    end
    fadeout:SetDuration(duration)

    --In OnFinished, we remove the killline associated with the animating row from memory.
    animation:SetScript("OnFinished", function(self, requested)
        frame:RemoveKillLine(self:GetParent().killref)
        self:GetParent().anim = nil;
        frame:UpdateKillStream();
    end)
    return animation
end

function frame:ClearKillStream()
    KillLines = {}
    frame:UpdateKillStream()
end

function frame:AddDummyData()
    local kill
    if (math.random() >= 0.1) then
        kill = {
            ["LastAttackTime"] = GetTime(),
            ["KillTime"] = GetTime(),
            ["IsCritical"] = false,
            ["UnitFlags"] = 68136,
            ["LastAttackerGuid"] = UnitGUID("player"),
            ["LastAttackerFlags"] = 1297,
            ["UnitGuid"] = UnitGUID("player"),
            ["SpellSchool"] = 1,
            ["SpellId"] = -1,
            ["LastAttackerName"] = UnitName("player"),
            ["IsEnvironmental"] = false,
            ["UnitName"] = frame:RandomTestName(),
            ["SpellName"] = "Melee",
        }
    else
        kill = {
            ["LastAttackTime"] = GetTime(),
            ["KillTime"] = GetTime(),
            ["IsCritical"] = false,
            ["UnitFlags"] = 1297,
            ["LastAttackerGuid"] = UnitGUID("player"),
            ["LastAttackerFlags"] = 1297,
            ["UnitGuid"] = UnitGUID("player"),
            ["SpellSchool"] = 1,
            ["SpellId"] = -1,
            ["LastAttackerName"] = "Falling",
            ["IsEnvironmental"] = true,
            ["UnitName"] = frame:RandomTestName(),
            ["SpellName"] = "Falling",
        }
    end
    frame:AddKillLine(kill)
end

function frame:RandomTestName()
    local length = math.random(2, 7)
    local name = "Test"
    for i = 1, length do
        local char = string.lower(string.char(65 + math.random(0, 25)))
        name = name .. char
    end
    return name
end

function frame:UpdateKillStream()
    local maxValue = #KillLines

    for i = 1, KILLSTREAM_MAXITEMS do
        if i <= maxValue then
            local row = self.ListRows[i]
            row.killref = KillLines[i] --Set a reference on the row to the kill, used by the animation system

            if (row.anim == nil) then --Reset alpha just in case the row was abandoned by the animator
                row:SetAlpha(1)
            end

            if (row.killref.IsMessage) then
                -- Console-style message
                row.SpellIcon:SetTexture(nil)
                row.VictimClassIcon:Hide()
                row.AttackerClassIcon:Hide()
                row.VictimName:SetText("")
                row.AttackerName:SetText(row.killref.Message)
                row.AttackerName:SetTextColor(0.1, 0.5, 0.1)
                row:Show()
            else
                -- Traditional KillStream line

                local displayVictimClass = true
                local displayAttackerClass = true
                local victimClass, victimName, spellId, attackerClass, attackerName, attackerFlags, victimFlags, victimType, attackerType, attackerFriendly, victimFriendly

                --Retrieve killline details
                _, victimClass = GetPlayerInfoByGUID(KillLines[i].UnitGuid)
                _, attackerClass = GetPlayerInfoByGUID(KillLines[i].LastAttackerGuid)
                attackerFlags = KillLines[i].LastAttackerFlags
                attackerName = KillLines[i].LastAttackerName
                victimName = KillLines[i].UnitName
                victimFlags = KillLines[i].UnitFlags
                spellId = KillLines[i].SpellId
                victimType = bit_band(victimFlags, UNITFLAG_TYPE_MASK)
                attackerType = bit_band(attackerFlags, UNITFLAG_TYPE_MASK)
                attackerFriendly = (bit_band(attackerFlags, UNITFLAG_REACTION_MASK) == UNITFLAG_REACTION_FRIEND)
                victimFriendly = (bit_band(victimFlags, UNITFLAG_REACTION_MASK) == UNITFLAG_REACTION_FRIEND)

                --NPCs don't get a class icon
                if (victimClass == nil) then displayVictimClass = false; end
                if (attackerClass == nil) then displayAttackerClass = false; end

                --Append NPC/Pet tags
                if (attackerType == UNITFLAG_TYPE_PET or attackerType == UNITFLAG_TYPE_GUARDIAN) then
                    attackerName = attackerName .. " (Pet)"
                elseif (attackerType == UNITFLAG_TYPE_NPC) then
                    attackerName = attackerName .. " (NPC)"
                end

                if (victimType == UNITFLAG_TYPE_PET or victimType == UNITFLAG_TYPE_GUARDIAN) then
                    victimName = victimName .. " (Pet)"
                elseif (victimType == UNITFLAG_TYPE_NPC) then
                    victimName = victimName .. " (NPC)"
                end

                --Melee is recorded as spellid -1, but that isn't actually valid.  Set spellid to Attack.
                if (spellId < 0) then
                    spellId = 88163
                end

                local _, _, spellIcon = GetSpellInfo(spellId)

                if (spellId == 75) then
                    --Spell 75 is Auto-Shot, which uses the player's currently equipped ranged weapon as the icon, even if it's a wand.
                    spellIcon = "Interface\\Icons\\inv_weapon_bow_05"
                elseif (KillLines[i].IsEnvironmental) then
                    --Environmental kills are (for now) assumed to be from falling.  Set a fall damage icon.
                    displayAttackerClass = false
                    spellIcon = "Interface\\Icons\\ability_deathknight_brittlebones"
                end

                if (displayAttackerClass) then
                    local coords = CLASS_ICON_TCOORDS[attackerClass];
                    row.AttackerClassIcon:SetTexCoord(unpack(coords))
                    row.AttackerClassIcon:SetDesaturated(Core.db.profile.killFrameDesaturateClassIcons)
                    row.AttackerClassIcon:Show()
                else
                    row.AttackerClassIcon:Hide()
                end
                if (displayVictimClass) then
                    local coords = CLASS_ICON_TCOORDS[victimClass];
                    row.VictimClassIcon:SetTexCoord(unpack(coords))
                    row.VictimClassIcon:SetDesaturated(Core.db.profile.killFrameDesaturateClassIcons)
                    row.VictimClassIcon:Show()
                else
                    row.VictimClassIcon:Hide()
                end

                row.AttackerName:SetText(attackerName)
                row.VictimName:SetText(victimName)

                --Set color based upon player's current faction
                --Come MoP this will probably cause problems on the Wandering Isles.
                if (PlayerIsAlliance) then
                    if (victimFriendly) then
                        row.VictimName:SetTextColor(0.3, 0.3, 1)
                    else
                        row.VictimName:SetTextColor(0.75, 0, 0)
                    end
                    if (attackerFriendly) then
                        row.AttackerName:SetTextColor(0.3, 0.3, 1)
                    else
                        row.AttackerName:SetTextColor(0.75, 0, 0)
                    end
                else
                    if (victimFriendly) then
                        row.VictimName:SetTextColor(0.75, 0, 0)
                    else
                        row.VictimName:SetTextColor(0.3, 0.3, 1)
                    end
                    if (attackerFriendly) then
                        row.AttackerName:SetTextColor(0.75, 0, 0)
                    else
                        row.AttackerName:SetTextColor(0.3, 0.3, 1)
                    end
                end

                row.SpellIcon:SetTexture(spellIcon)
                row.SpellIcon:SetDesaturated(Core.db.profile.killFrameDesaturateSkillIcon)

                row:SetHeight(KILLSTREAM_LINEHEIGHT)
                row:Show()
            end
        else
            --For rows without matching killlines, clear the existing killref, hide it, and stop any animations if necessary
            if (self.ListRows[i].anim ~= nil) then self.ListRows[i].anim:Stop() end
            self.ListRows[i].anim = nil
            self.ListRows[i]:Hide()
            self.ListRows[i].killref = nil
        end
    end
end