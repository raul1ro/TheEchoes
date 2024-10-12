local _, Addon = ...;

Addon.Utils = {}

function Addon.Utils.getGuildData()

    local members = {}
    local alts = {}
    local errorMembers = {}

    local counterTank = 0
    local counterHeal = 0
    local counterDPS = 0

    -- get the members from group - if you are in a home-group(manual-group)
    local groupMembers = Addon.Utils.getGroupMembers()

    -- get the members
    local membersTotal, _, membersOnline = GetNumGuildMembers()
    for i = 1, membersTotal do

        -- get the data for current member
        local name, rank, rankIndex, level, _, zone, note, officerNote, online, _, classFileName = GetGuildRosterInfo(i)

        -- if the player is offline get last online
        local lastOnline = ""
        if(online == false) then

            yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i);

            if(yearsOffline and yearsOffline > 0) then
                lastOnline = yearsOffline .. " year(s)"
            elseif(monthsOffline and monthsOffline > 0) then
                lastOnline = monthsOffline .. " month(s)"
            elseif(daysOffline and daysOffline > 0) then
                lastOnline = daysOffline .. " day(s)"
            elseif(hoursOffline and hoursOffline > 0) then
                lastOnline = hoursOffline .. " hour(s)"
            else
                lastOnline = "< hour"
            end

        end

        -- remove the realm from name
        local startIndex = string.find(name, "-")
        if startIndex then
            name = Addon.Utils.trimString(string.sub(name, 0, startIndex - 1))
        end

        -- splite note in roles
        local roles = Addon.Utils.extractRoles(note)
        if roles == nil or next(roles) == nil then
            table.insert(errorMembers, {
                name = name,
                online = online,
                class = classFileName,
                level = level,
                rank = rank,
                rankIndex = rankIndex,
                note = note,
                officerNote = officerNote,
                lastOnline = lastOnline
            })
        else

            -- count the roles
            if roles.TANK ~= nil then
                counterTank = counterTank + 1
            end
            if roles.HEAL ~= nil then
                counterHeal = counterHeal + 1
            end
            if roles.DPS ~= nil then
                counterDPS = counterDPS + 1
            end

            -- build the object
            local memberInfo = {
                online = online,
                class = classFileName,
                rank = rank,
                rankIndex = rankIndex,
                roles = roles,
                level = level,
                zone = zone,
                lastOnline = lastOnline,
                note = note,
                officerNote = officerNote,
                isSameGroup = groupMembers[name]
            }

            -- group members on main and alts
            officerNote = Addon.Utils.trimString(officerNote)
            officerNote = officerNote:upper()
            local mainMember = Addon.Utils.extractMain(officerNote)
            if officerNote == "MAIN" then -- if the officerNote is main

                memberInfo.alts = {} -- add the alts attribute
                members[name] = memberInfo -- save the member

            elseif mainMember ~= nil then -- if it is an alt

                memberInfo.main = mainMember -- save the main member in memberInfo
                alts[name] = memberInfo -- save member as alt]]

            else -- unknown case

                table.insert(errorMembers, {
                    name = name,
                    online = online,
                    class = classFileName,
                    level = level,
                    rank = rank,
                    rankIndex = rankIndex,
                    note = note,
                    officerNote = officerNote,
                    lastOnline = lastOnline
                })

            end

        end

    end

    -- set the alts to the main members
    for altName, altInfo in pairs(alts) do

        -- get the main member
        local mainName = altInfo.main
        local mainMember = members[mainName]

        if mainMember ~= nil then -- main member found

            mainMember.note = nil
            mainMember.officerNote = nil
            altInfo.note = nil
            altInfo.officerNote = nil
            mainMember.alts[altName] = altInfo

        else -- main member not found -> errorMembers

            table.insert(errorMembers, {
                name = altName,
                online = altInfo.online,
                class = altInfo.class,
                level = altInfo.level,
                rank = altInfo.rank,
                rankIndex = altInfo.rankIndex,
                note = altInfo.note,
                officerNote = altInfo.officerNote,
                lastOnline = altInfo.lastOnline
            })

        end

    end

    table.sort(errorMembers, function(a, b) return a.name < b.name end)

    return { membersData = members, totalSize = membersTotal, onlineSize = membersOnline, tankSize = counterTank, healSize = counterHeal, dpsSize = counterDPS, errorMembers = errorMembers }

end

function Addon.Utils.getMemberIndex(name)

    name = name .. "-" .. GetRealmName()
    for i = 1, GetNumGuildMembers() do
        local memberName = GetGuildRosterInfo(i)
        if memberName == name then
            return i;
        end
    end

    error("Member: " + name + " not found")

end

-- update the ilvl of the player
function Addon.Utils.updateMemberILVL(memberIndex, tank, heal, dps)

    local finalNote = "";

    if(tank ~= nil) then
        tank = Addon.Utils.trimString(tank)
        if(tank ~= "") then
            finalNote = finalNote .. " - tank:" .. tank
        end
    end

    if(heal ~= nil) then
        heal = Addon.Utils.trimString(heal)
        if(heal ~= "") then
            finalNote = finalNote .. " - heal:" .. heal
        end
    end

    if(dps ~= nil) then
        dps = Addon.Utils.trimString(dps)
        if(dps ~= "") then
            finalNote = finalNote .. " - dps:" .. dps
        end
    end

    finalNote = string.sub(finalNote, 4)

    GuildRosterSetPublicNote(memberIndex, finalNote)

end

function Addon.Utils.updateMemberType(memberIndex, type, mainMember)

    local finalNote = "";
    if type == "Main" then
        finalNote = "main"
    elseif type == "Alt" then
        finalNote = "alt : " .. (mainMember ~= nil and mainMember or "")
    end

    GuildRosterSetOfficerNote(memberIndex, finalNote)

end

-- trim the blank spaces from the begining and the end of the string
function Addon.Utils.trimString(str)
    return str:match("^%s*(.-)%s*$")
end

-- split the note "dps:x - tank:y - heal:z" -> {dps: x, tank: y, heal: z}
function Addon.Utils.extractRoles(str)

    local result = {}
    str = str:upper()

    -- parse every role
    for pair in str:gmatch("%s*([^-]+)%s*") do

        -- parse
        local key, value = pair:match("(%a+):([^%-]+)")

        -- check if is valid
        if key == nil or value == nil then
            return nil
        end

        -- extract them
        key = Addon.Utils.trimString(key)
        value = Addon.Utils.trimString(value)

        -- validate
        if key ~= "TANK" and key ~= "HEAL" and key ~= "DPS" then
            return nil
        end

        -- save it
        result[key] = value

    end

    return result

end

-- extract the main char from the officer note "alt : MainMember" -> MainMember / nil
function Addon.Utils.extractMain(str)

    local mainName = str:match("ALT%s*:%s*(.+)");
    if(mainName == nil) then return nil end

    local firstChar = string.sub(mainName, 1, 1);
    local restChars = string.sub(mainName, 2);

    mainName = firstChar:upper() .. restChars:lower();

    return mainName;

end

-- sort the members
function Addon.Utils.sortMembers(members, onlyName)

    -- put the members in an indexed array
    local sortedMembers = {}
    for name, value in pairs(members) do

        --sort the alts, if it has
        local alts = value.alts
        if alts ~= nil then
            alts = Addon.Utils.sortMembers(alts, onlyName)
            value.alts = alts
        end

        -- set the name as field
        value.name = name
        table.insert(sortedMembers, value)

        alts = nil

    end

    if(onlyName) then
        table.sort(sortedMembers, Addon.Utils.compareOnlyName)
    else
        table.sort(sortedMembers, Addon.Utils.compare)
    end

    return sortedMembers

end

-- Custom comparison for members
function Addon.Utils.compare(a, b)

    -- Rule 1: Sort by online status
    if a.online and not b.online then
        return true
    elseif not a.online and b.online then
        return false
    end

    -- Rule 2: Sort by online status of alt
    local aAlts = a.alts
    local aAltOnline = false
    local bAlts = b.alts
    local bAltOnline = false

    if(aAlts ~= nil) then
        for _, alt in pairs(aAlts) do

            if alt.online  then
                aAltOnline = true
            end
        end
    end
    aAlts = nil

    if(bAlts ~= nil) then
        for _, alt in pairs(bAlts) do
            if alt.online  then
                bAltOnline = true
            end
        end
    end
    bAlts = nil

    if aAltOnline and not bAltOnline then
        aAltOnline = nil
        bAltOnline = nil
        return true
    elseif not aAltOnline and bAltOnline then
        aAltOnline = nil
        bAltOnline = nil
        return false
    end

    -- Rule 3: Sort by level
    if a.level > b.level then
        return true
    elseif a.level < b.level then
        return false
    end

    -- Rule 4: Sort by name alphabetically
    return a.name < b.name

end

-- Custom comparison for members which is ignoring the online status
function Addon.Utils.compareOnlyName(a, b)

    -- Rule 4: Sort by name alphabetically
    return a.name < b.name

end

-- get the size of the array
function Addon.Utils.size(array)

    local size = 0
    for _ in pairs(array) do
        size = size + 1
    end

    return size

end

-- get the width based on longest text element from array
function Addon.Utils.getMaxWidth(array)

    local wordSize = 0
    for _, v in pairs(array) do

        local vLength = string.len(v)
        if wordSize < vLength then
            wordSize = vLength
        end

    end

    return wordSize * 10;

end

-- check if the player can edit notes
--[[function Addon.Utils.canEditNotes()
    return CanEditPublicNote() and CanEditOfficerNote()
end]]

-- reposition the scrollbar of scrollframe
function Addon.Utils.positionScrollBar(scrollFrame)
    local scrollBar = scrollFrame.ScrollBar
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 3, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 3, 16)
end

-- get the party members name
function Addon.Utils.getGroupMembers()

    -- get the members from group
    tempArray = GetHomePartyInfo()
    if tempArray == nil then tempArray = {} end

    -- put them as key/value, instead of index/value
    groupMembers = {}
    for _, v in ipairs(tempArray) do
        groupMembers[v] = true
    end

    return groupMembers

end

function Addon.Utils.exportData()

    local guildData = Addon.Utils.getGuildData()
    local membersData = Addon.Utils.sortMembers(guildData.membersData, true)

    local json = "[\n"
    for _, member in ipairs(membersData) do

        json = json .. "{\n"
        json = json .. "\t\"name\": \"" .. member.name .. "\", \"class\": \"" .. member.class .. "\", \"rank\": \"" .. member.rank .. "\", \"roles\": ["
        for role, ilvl in pairs(member.roles) do
            json = json .. "{\"" .. role .. "\": \"" .. ilvl  .. "\"}, "
        end
        json = string.sub(json, 1, string.len(json) - 2) .. "],\n\t\"alts\": [\n"

        for _, altMember in ipairs(member.alts) do

            json = json .. "\t\t{"
            json = json .. "\"name\": \"" .. altMember.name .. "\", \"class\": \"" .. altMember.class .. "\", \"rank\": \"" .. altMember.rank .. "\", \"roles\": ["
            for role, ilvl in pairs(altMember.roles) do
                json = json .. "{\"" .. role .. "\": \"" .. ilvl  .. "\"}, "
            end
            json = string.sub(json, 1, string.len(json) - 2) .. "]},\n"

        end

        if Addon.Utils.size(member.alts) > 0 then
            json = string.sub(json, 1, string.len(json) - 2) .. "\n\t]\n},\n"
        else
            json = string.sub(json, 1, string.len(json) - 1) .. "]\n},\n"
        end

    end
    json = string.sub(json, 1, string.len(json) - 2) .. "\n]"

    return json

end

function Addon.Utils.getGuildRanks()

    local numRanks = GuildControlGetNumRanks()

    local ranks = {}
    for i = 1, numRanks do
        table.insert(ranks, GuildControlGetRankName(i))
    end

    return ranks

end

function Addon.Utils.canModifyRanks()
    return CanGuildPromote() and CanGuildDemote()
end

local classNameList = {
    ["WARRIOR"] = "Warrior",
    ["PALADIN"] = "Paladin",
    ["HUNTER"] = "Hunter",
    ["ROGUE"] = "Rogue",
    ["PRIEST"] = "Priest",
    ["DEATHKNIGHT"] = "Death Knight",
    ["SHAMAN"] = "Shaman",
    ["MAGE"] = "Mage",
    ["WARLOCK"] = "Warlock",
    ["MONK"] = "Monk",
    ["DRUID"] = "Druid",
    ["DEMONHUNTER"] = "Demon Hunter"
}
function Addon.Utils.getClassName(classFile)
    return classNameList[classFile]
end

function Addon.Utils.containsIgnoringCase(mainString, searchString)
    return string.find(string.lower(mainString), string.lower(searchString)) ~= nil
end