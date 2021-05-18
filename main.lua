local MultipleMarkAndRecall = {}

local scriptName = "MultipleMarkAndRecall"
local logPrefix = "[ " .. scriptName .." ]: "

local Mysticism = "Mysticism"
local teleportForbidden = {
    "Akulakhan's Chamber",
    "Sotha Sil,", "Solstheim, Mortrag Glacier: Entry", "Solstheim, Mortrag Glacier: Outer Ring",
    "Solstheim, Mortrag Glacier: Inner Ring", "Solstheim, Mortrag Glacier: Huntsman's Hall"
}

MultipleMarkAndRecall.defaultConfig = {
    maxMarks = 18,
    msgMark = color.Green .. "The mark \"%s\" has been set!" .. color.Default,
    msgMarkRm = color.Green .. "The mark \"%s\" has been deleted!" .. color.Default,
    msgNotAllowed = color.Red .. "Teleportation is not allowed here!" .. color.Default,
    msgRecall = color.Green .. "Recalled to: \"%s\"!" .. color.Default,
    msgRecallFailed = color.Red .. "Recall failed; that mark doesn't exist!" .. color.Default,
    over10mod = 2,
    over50mod = 7,
    skillProgressPoints = 2,
    spellCost = 18,
    teleportForbidden = teleportForbidden,
}

MultipleMarkAndRecall.config = DataManager.loadConfiguration(scriptName, MultipleMarkAndRecall.defaultConfig)

math.randomseed(os.time())


local function dbg(msg)
    tes3mp.LogMessage(enumerations.log.VERBOSE, logPrefix .. msg)
end

local function fatal(msg)
   tes3mp.LogMessage(enumerations.log.FATAL, logPrefix .. msg)
end

local function warn(msg)
    tes3mp.LogMessage(enumerations.log.WARN, logPrefix .. msg)
end

local function info(msg)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. msg)
end

-- Check for new settings that may not be present
if MultipleMarkAndRecall.config.over10mod == nil then
    warn("No 'over10mod' value was found in your config!")
    warn("Please set that, the default of '2' is being used.")
    MultipleMarkAndRecall.config.over10mod = 2
end
if MultipleMarkAndRecall.config.over50mod == nil then
    warn("No 'over50mod' value was found in your config!")
    warn("Please set that, the default of '7' is being used.")
    MultipleMarkAndRecall.config.over50mod = 7
end

local function chatMsg(pid, msg)
    dbg("Called chatMsg for pid: " .. pid .. " and msg: " .. msg)
   tes3mp.SendMessage(pid, "[MMAR]: " .. msg .. "\n")
end

local function canTeleport(pid)
    dbg("Called canTeleport for pid: " .. pid)
    local currentCell = tes3mp.GetCell(pid)
    if tableHelper.containsValue(MultipleMarkAndRecall.config.teleportForbidden, currentCell) then
        return false
    end
    return true
end

local function doProgressAndStats(pid, noProgress)
    dbg("Called doProgressAndStats for pid: " .. pid)
    local player = Players[pid]
    if noProgress == nil then
        player.data.skills.Mysticism.progress = player.data.skills.Mysticism.progress + MultipleMarkAndRecall.config.skillProgressPoints
        player:LoadSkills()
    end

    player.data.stats.magickaCurrent = player.data.stats.magickaCurrent - MultipleMarkAndRecall.config.spellCost
    player:LoadStatsDynamic()
end

local function doRecall(pid, name)
    dbg("Called doRecall for pid: " .. pid .. " and name: " .. name)
    local player = Players[pid]

    if not canTeleport(pid) then
        chatMsg(pid, MultipleMarkAndRecall.config.msgNotAllowed)
        return
    end

    local mark = player.data.customVariables.MultipleMarkAndRecall.marks[name]

    player.data.location.cell = mark.cell
    player.data.location.posX = mark.x
    player.data.location.posY = mark.y
    player.data.location.posZ = mark.z
    player.data.location.rotZ = mark.rot

    player:LoadCell()
    doProgressAndStats(pid)
    chatMsg(pid, string.format(MultipleMarkAndRecall.config.msgRecall, name))
end

local function getMarkCount(pid)
    dbg("Called getMarkCount for pid: " .. pid)
    local extraMarks = 0
    local markCount = 2
    local mysticism = Players[pid].data.skills[Mysticism].base
    local totalMarks

--[[

From the `Teleport_Menu2` script in "MultiMarkOMW-MysticismBalance-1.1.esp"
(and the readme):

  optional: get between 2 and 18 marks depending on Mysticism
  (additional mark every 10 levels then every 5 levels after 50)
  use together with either of the MultiMarkOMW plugins.

UNFORTUNATELY.... their maths do not actually work like that.
These scripts were extracted from the plugin (thanks Delta Plugin!):

  ...
  Set TeleportMaxSlots to ( player->GetMysticism )
  Set TeleportMaxSlots to ( ( ( TeleportMaxSlots - 50 ) / 5 ) + 7 )
  ...
  Set TeleportMaxSlots to ( player->GetMysticism )
  Set TeleportMaxSlots to ( ( TeleportMaxSlots / 10 ) + 2 )
  ...

The '+ 7' and '+ 2' are what break the described formula, and it's unclear to
me why they do that but I'll copy that behavior too, if only to allow for more
marks.

]]--

    if mysticism >= 50 then
        local count = math.floor((mysticism - 50) / 5) + MultipleMarkAndRecall.config.over50mod
        extraMarks = extraMarks + count

    elseif mysticism >= 10 then
        extraMarks = math.floor(mysticism / 10) + MultipleMarkAndRecall.config.over10mod

    else
        extraMarks = 0
    end

    totalMarks = markCount + extraMarks

    if totalMarks > MultipleMarkAndRecall.config.maxMarks then
        totalMarks = MultipleMarkAndRecall.config.maxMarks
    end

    return totalMarks
end

local function hasSpell(pid, spell)
    dbg("Called hasSpell for pid: " .. pid .. " and spell: " .. spell)
    return tableHelper.containsValue(Players[pid].data.spellbook, spell)
end

local function lsMarks(pid)
    local player = Players[pid]
    local marks = player.data.customVariables.MultipleMarkAndRecall.marks

    if tableHelper.isEmpty(marks) then
        chatMsg(pid, "You have no marks set.")

    else
        chatMsg(pid, "Your marks:")
        for name, pos in pairs(marks) do
            chatMsg(pid, "    " .. name .. "    (" .. pos.cell .. ")")
        end
    end

    local curMarkCount = tableHelper.getCount(player.data.customVariables.MultipleMarkAndRecall.marks)
    local maxMarkCount = getMarkCount(pid)
    chatMsg(pid, tostring(curMarkCount) .. "/" .. tostring(maxMarkCount) .. " marks used.")
end

local function rmMark(pid, name)
    dbg("Called rmMark for pid: " .. pid .. " and name: " .. name)
    local player = Players[pid]
    player.data.customVariables.MultipleMarkAndRecall.marks[name] = nil
    tableHelper.cleanNils(player.data.customVariables.MultipleMarkAndRecall.marks)
    chatMsg(pid, string.format(MultipleMarkAndRecall.config.msgMarkRm, name))
end

local function setMark(pid, name)
    dbg("Called setMark for pid: " .. pid .. " and name: " .. name)
    local player = Players[pid]

    player.data.customVariables.MultipleMarkAndRecall.marks[name] = {
        cell = tes3mp.GetCell(pid),
        x = tes3mp.GetPosX(pid),
        y = tes3mp.GetPosY(pid),
        z = tes3mp.GetPosZ(pid),
        rot = tes3mp.GetRotZ(pid)
    }

    doProgressAndStats(pid)
    chatMsg(pid, string.format(MultipleMarkAndRecall.config.msgMark, name))
end

local function spellSuccess(pid)
    dbg("Called spellSuccess for pid: " .. pid)
    local player = Players[pid]
    local currentFatigue = player.data.stats.fatigueCurrent
    local maximumFatigue = player.data.stats.fatigueBase
    local luck = player.data.attributes["Luck"].base
    local mysticism = player.data.skills[Mysticism].base
    local willpower = player.data.attributes["Willpower"].base
    -- TODO: Actually get the value of this
    -- local soundMagnitude = 0

    -- The OpenMW wiki and UESP seem to disagree on this formula; I'm going with the OpenMW wiki.
    --
    -- castChance = (lowestSkill - spellCost + actor.castBonus + 0.2 * actorWillpower + 0.1 * actorLuck) * fatigueTerm
    -- fatigueTerm = fFatigueBase - fFatigueMult * (1 - normalizedFatigue)
    --
    -- Source:  https://wiki.openmw.org/index.php?title=Research:Magic#Spell_Casting
    -- Related: https://wiki.openmw.org/index.php?title=Research:Common_Terms
    --          https://wiki.openmw.org/index.php?title=GMSTs_(status)
    --
    -- Chance of success is (Spell's skill * 2 + Willpower / 5 + Luck / 10 - Spell cost - Sound magnitude) * (0.75 + 0.5 * Current Fatigue/Maximum Fatigue)
    -- Source: https://en.uesp.net/wiki/Morrowind:Spells

    local normalizedFatigue = math.max(0, currentFatigue / maximumFatigue)
    local ft = 1.25 - 0.5 * (1 - normalizedFatigue)
    local fatigueTerm = tonumber(string.format("%.3f", ft))
    local chance = math.floor((2 * mysticism - MultipleMarkAndRecall.config.spellCost + 0.2 * willpower + 0.1 * luck) * fatigueTerm)
    local roll = math.random(1, 100)

    if roll < chance then
        return true
    else
        return false
    end
end


MultipleMarkAndRecall.Cmd = function(pid, cmd)
    info("Called MultipleMarkAndRecall.Cmd for pid: " .. pid)
    local spell = cmd[1]
    local spellName = spell

    if spellName == "markrm" then
        -- The spell for "markrm" is "mark"
        spellName = "mark"
    end

    -- THANKS: http://lua-users.org/wiki/StringRecipes
    local Spell = spellName:gsub("^%l", string.upper)

    -- Do you know the spell?
    if not hasSpell(pid, spellName) then
        chatMsg(pid, color.Red .. "You do not have the " .. Spell .. " spell!" .. color.Default)
        return
    end

    local markName = tableHelper.concatenateFromIndex(cmd, 2)

    -- Did you supply a mark name?
    if markName == "" then
        chatMsg(pid, color.Red .. "Please supply a mark name!" .. color.Default)
        lsMarks(pid)
        return
    end

    -- Are you trying to delete a mark?
    if spell == "markrm" and markName ~= "" then
        -- Deleting marks doesn't cost any magicka, nor is there any failure chance.
        rmMark(pid, markName)
        return
    end

    local player = Players[pid]
    local mark = player.data.customVariables.MultipleMarkAndRecall.marks[markName]

    -- Is the mark a real, stored mark?
    if spellName == "recall" and markName ~= "" and mark == nil then
        -- Telling the player the mark name is bad shouldn't have a success chance or cost any magicka.
        chatMsg(pid, string.format(MultipleMarkAndRecall.config.msgRecallFailed, markName))
        return
    end

    local curMarkCount = tableHelper.getCount(player.data.customVariables.MultipleMarkAndRecall.marks)
    local maxMarkCount = getMarkCount(pid)

    -- TODO: Allow overwriting an already saved mark?
    -- Is there any space for a new mark?
    if spell == "mark" and curMarkCount == maxMarkCount then
        -- Telling the player there's no free marks shouldn't have a success chance or cost any magicka.
        chatMsg(pid, color.Red .. "You do not have any free marks!" .. color.Default)
        chatMsg(pid, color.Red .. "Please use the \"/markrm\" command to make room for new marks." .. color.Default)
        return
    end

    -- Now we start caring about magicka levels... do you have enough magicka to cast the spell?
    player:SaveStatsDynamic()
    if player.data.stats.magickaCurrent < MultipleMarkAndRecall.config.spellCost and markName ~= "" then
        chatMsg(pid, color.Red .. "You do not have enough magicka to cast " .. Spell .. "!" .. color.Default)
        return
    end

    local success = spellSuccess(pid)

    -- Did you succeed at casting the spell?
    if not success then
        doProgressAndStats(pid, true)
        chatMsg(pid, color.Red .. "Casting " .. Spell .. " has failed!" .. color.Default)
        return
    end

    -- Okay, finally do the spell.
    if spell == "mark" then
        setMark(pid, markName)

    elseif spell == "recall" then
        doRecall(pid, markName)
    end
end

MultipleMarkAndRecall.OnPlayerAuthentified = function(eventStatus, pid)
    if eventStatus.validCustomHandlers then
        dbg("Called MultipleMarkAndRecall.OnPlayerAuthentified for pid: " .. pid)
        local player = Players[pid]
        if player.data.customVariables.MultipleMarkAndRecall == nil then
            player.data.customVariables.MultipleMarkAndRecall = {}
            player.data.customVariables.MultipleMarkAndRecall.marks = {}
        end
    else
        fatal(scriptName .. " cannot work right!")
        fatal("Unable to set custom player data!")
    end
end


customCommandHooks.registerCommand("mark", MultipleMarkAndRecall.Cmd)
customCommandHooks.registerCommand("markrm", MultipleMarkAndRecall.Cmd)
customCommandHooks.registerCommand("recall", MultipleMarkAndRecall.Cmd)

customEventHooks.registerHandler("OnPlayerAuthentified", MultipleMarkAndRecall.OnPlayerAuthentified)
