local L = LibStub("AceLocale-3.0"):NewLocale("KillStream", "enUS", true)

if not L then return end

--Addon load
L["KillStream v%s loaded!  For preferences, type /kf."] = true
L["Need help with KillStream?  Head over to the Curse page or feel free to email me at <wowaddons@leetsoft.net>."] = true


L["Enable KillStream"] = true
L["Enables or disables the addon.  While disabled, KillStream will not parse the combat log."] = true
L["Add Test Kill"] = true
L["Adds a fake kill to the kill stream so you can test your preferences."] = true
L["Clear Kill Stream"] = true
L["Clears all kills from the kill stream."] = true
L["Toggle Background"] = true
L["Toggles a background behind the kill stream, to allow you to position it more accurately."] = true

L["Zone Preferences"] = true
L["Allows you to enable or disable KillStream while in specific areas of the game."] = true

L["Enabled in Arenas"] = true
L["Sets whether or not the addon is enabled in arenas."] = true
L["Enabled in Battlegrounds"] = true
L["Sets whether or not the addon is enabled in battlegrounds."] = true
L["Enabled in Open World"] = true
L["Sets whether or not the addon is enabled in the open world."] = true
L["Enabled in Instances"] = true
L["Sets whether or not the addon is enabled in dungeon and raid instances."] = true

L["Stream Preferences"] = true
L["Allows you to modify the appearance and behavior of the kill stream."] = true

L["Lock Kill Stream"] = true
L["Unlock if you want to move the kill stream with your mouse."] = true
L["Max Kill Lines"] = true
L["Sets the maximum number of kills that will be displayed at once."] = true
L["Kill Display Duration"] = true
L["Sets how long (in seconds) a kill should be shown before it begins to fade out."] = true
L["Kill Fadeout Duration"] = true
L["Sets how long it takes (in seconds) for a kill to fade out."] = true
L["Kill Stream Scale"] = true
L["Sets the size of the kill stream."] = true
L["Only Show Player Deaths"] = true
L["If checked, KillStream will only show kills against players, not NPCs or pets."] = true
L["Growth Direction"] = true
L["Specifies the direction in which the kill stream grows.  If 'Grow Upwards' is selected, new kills will be added at the bottom, pushing older ones up.  For 'Grow Downwards', the opposite is true."] = true
L["Grow Upwards"] = true
L["Grow Downwards"] = true
L["Anchor Mode"] = true
L["Specifies whether kills should be anchored to the left or right side of the kill stream."] = true
L["Left Side"] = true
L["Right Side"] = true
L["Desaturate Class Icons"] = true
L["Specifies whether class icons are desaturated (greyscale)."] = true
L["Desaturate Skill Icon"] = true
L["Specifies whether the skill icon is desaturated (greyscale)."] = true