local _, Addon = ...;

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

local Utils = {};
Addon.Utils = Utils;

-- reanchor the scroll bar of the scroll frame
-- default position is too much to the right
-- set it more near to the scrollframe.
function Utils.PositionScrollBar(scrollFrame)
    local scrollBar = scrollFrame.ScrollBar
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 3, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 3, 16)
end

-- get the size of the array
function Utils.ArraySize(array)

    if(array == nil) then
        return 0;
    end

    local size = 0
    for _ in pairs(array) do
        size = size + 1
    end

    return size

end

-- get the width based on longest text element from array
function Utils.MaxWidth(array)

    local wordSize = 0
    for _, v in pairs(array) do

        local vLength = string.len(v)
        if wordSize < vLength then
            wordSize = vLength
        end

    end

    return wordSize * 10;

end

-- get the data about guild: {membersSize, membersOnlineSize, membersData}
function Utils.GetGuildData()

    local guildData = {}

    local membersSize, _, membersOnlineSize = GetNumGuildMembers();
    guildData.membersSize = membersSize;
    guildData.membersOnlineSize = membersOnlineSize;

    -- get group members;
    local groupMembers = Utils.GetGroupMembers();

    local membersData = {};
    for i = 1, membersSize do

        local name, rankName, rankIndex, level, _, zone, publicNote, officerNote, isOnline, _, class = GetGuildRosterInfo(i);

        -- remove the realm from name
        name = Utils.RemoveRealm(name);

        -- get lastSeen, only if the player is offline
        local lastSeen;
        if(isOnline == false) then
            lastSeen = Utils.GetLastSeen(i);
        end

        local isInGroup = groupMembers[name];

        local memberData = {
            isOnline = isOnline,
            isInGroup = isInGroup,
            class = class,
            rank = rankName,
            rankIndex = rankIndex,
            level = level,
            zone = zone,
            publicNote = publicNote,
            officerNote = officerNote,
            lastSeen = lastSeen
        }

        membersData[name] = memberData;

    end

    guildData.membersData = Utils.ParseMembersData(membersData);

    return guildData;

end

-- parse the members based on their notes (roles, type)
-- flags: errorRoles, errorType, errorMain
function Utils.ParseMembersData(membersData)

    local membersMain = {};
    local membersAlt = {};

    -- take every member and parse it
    for charName, memberData in pairs(membersData) do

        local roles = Utils.ParsePublicNote(memberData.publicNote);
        local type = Utils.ParseOfficerNote(memberData.officerNote);

        memberData.roles = roles;
        if(roles == nil) then
            memberData.errorRoles = true; -- flag to identify errors at roles.
        end

        -- is main
        if type == "main" then

            memberData.alts = {};
            membersMain[charName] = memberData;

        elseif type ~= nil then -- alt

            memberData.main = type
            membersAlt[charName] = memberData

        else -- unknown

            memberData.errorType = true; -- flag to identify errors at type.
            memberData.alts = {}; -- it can be a main with alts
            membersMain[charName] = memberData;

        end
    end

    -- merge the alts into mains
    for altName, altData in pairs(membersAlt) do

        local mainName = altData.main
        local mainData = membersMain[mainName]

        -- if the main exists
        if mainData then
            mainData.alts[altName] = altData
        else
            altData.errorMain = true; -- flag to identify that the main was not found
            membersMain[altName] = altData;
        end

    end

    -- sort by name, including alts.
    return Utils.SortMembers(membersMain);

end

-- sort the members
function Utils.SortMembers(members)

    -- put the members in an indexed array
    local sortedMembers = {}
    for name, value in pairs(members) do

        --sort the alts, if it has
        local alts = value.alts
        if alts ~= nil and Utils.ArraySize(alts) > 0 then
            alts = Utils.SortMembers(alts)
            value.alts = alts -- overwrite the alts with ordered list
        end

        -- set the name as field
        value.name = name
        table.insert(sortedMembers, value)

    end

    table.sort(sortedMembers, Utils.CompareMembers)

    return sortedMembers;

end

function Utils.CompareMembers(a, b)

    -- by is in group.
    -- place the group members first.
    if(TheEchoesGroupMembersFirst and Utils.IsInGroup()) then
        -- a in group
        local aIsInGroup = a.isInGroup or false;
        if(aIsInGroup == false) then
            -- check alts
            local alts = a.alts;
            if(alts ~= nil) then
                for _, altData in pairs(alts) do
                    if(altData.isInGroup) then
                        aIsInGroup = true;
                        break;
                    end
                end
            end
        end
        -- b in group
        local bIsInGroup = b.isInGroup or false;
        if(bIsInGroup == false) then
            -- check alts
            local alts = b.alts;
            if(alts ~= nil) then
                for _, altData in pairs(alts) do
                    if(altData.isInGroup) then
                        bIsInGroup = true;
                        break;
                    end
                end
            end
        end
        -- final check
        if(aIsInGroup and not bIsInGroup) then
            return true;
        elseif(bIsInGroup and not aIsInGroup) then
            return false;
        end
    end

    -- a online
    local aIsOnline = a.isOnline;
    if(aIsOnline == false) then
        -- check alts
        local alts = a.alts;
        if(alts ~= nil) then
            for _, altData in pairs(alts) do
                if(altData.isOnline) then
                    aIsOnline = true;
                    break;
                end
            end
        end
    end

    -- b online
    local bIsOnline = b.isOnline;
    if(bIsOnline == false) then
        -- check alts
        local alts = b.alts;
        if(alts ~= nil) then
            for _, altData in pairs(alts) do
                if(altData.isOnline) then
                    bIsOnline = true;
                    break;
                end
            end
        end
    end

    -- online
    if(aIsOnline and not bIsOnline) then
        return true;
    elseif(bIsOnline and not aIsOnline) then
        return false;
    end

    -- rank
    if(a.rankIndex < b.rankIndex) then
        return true;
    elseif(a.rankIndex > b.rankIndex) then
        return false;
    end

    -- by level
    --[[if a.level > b.level then
        return true;
    elseif a.level < b.level then
        return false;
    end]]

    -- by name
    return a.name < b.name

end

function Utils.CompareByName(a, b)

    -- by name
    return a.name < b.name

end

-- split the note "dps:x - tank:y - heal:z" -> {dps: x, tank: y, heal: z}
function Utils.ParsePublicNote(note)

    local result = {};
    note = note:lower();

    -- parse every role
    for pair in note:gmatch("%s*([^-]+)%s*") do

        -- parse
        local key, value = pair:match("(%a+):([^%-]+)")

        -- check if is valid
        if key == nil or value == nil then
            return nil
        end

        -- extract them
        key = Utils.TrimString(key)
        value = Utils.TrimString(value)

        -- validate
        if key ~= "tank" and key ~= "heal" and key ~= "dps" then
            return nil
        end

        -- save it
        result[key] = value

    end

    -- if it has no role
    if next(result) == nil then
        result = nil;
    end

    return result;

end

-- parse the officer note -> main | mainName
function Utils.ParseOfficerNote(note)

    note = note:lower();

    -- it's main
    if(note == "main") then
        return "main";
    end

    -- it's alt
    local mainName = note:match("alt%s*:%s*(.+)");
    if(mainName == nil) then return nil end

    -- get the byte of first char. Special chars use more than 1 byte
    local firstCharSize;
    local firstCharByte = string.byte(mainName, 1);
    if firstCharByte < 124 then
        firstCharSize = 1;
    elseif firstCharByte < 224 then
        firstCharSize = 2;
    elseif firstCharByte < 240 then
        firstCharSize = 3;
    else
        firstCharSize = 4;
    end

    -- normalize the main name
    local firstChar = string.sub(mainName, 1, firstCharSize);
    local restChars = string.sub(mainName, firstCharSize + 1);
    mainName = firstChar:upper() .. restChars:lower();

    return mainName;

end

-- trim the blank spaces from the beginning and the end of the string
function Utils.TrimString(str)
    return str:match("^%s*(.-)%s*$")
end

-- remove the realm name from the user name
function Utils.RemoveRealm(name)
    local startIndex = string.find(name, "-")
    if startIndex then
        name = Utils.TrimString(string.sub(name, 0, startIndex - 1));
    end
    return name;
end

-- get the last seen text
function Utils.GetLastSeen(memberIndex)

    local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(memberIndex);

    local lastSeen = "";
    if(yearsOffline and yearsOffline > 0) then
        lastSeen = yearsOffline .. " year(s)"
    elseif(monthsOffline and monthsOffline > 0) then
        lastSeen = monthsOffline .. " month(s)"
    elseif(daysOffline and daysOffline > 0) then
        lastSeen = daysOffline .. " day(s)"
    elseif(hoursOffline and hoursOffline > 0) then
        lastSeen = hoursOffline .. " hour(s)"
    else
        lastSeen = "< hour"
    end

    return lastSeen

end

-- count the main, alt, tank, heal, dps
-- exclude the members with errorRoles, errorType, errorMain
function Utils.GetMemberCounts(membersData)

    local mainSize = 0; local altSize = 0;
    local tankSize = 0; local healSize = 0; local dpsSize = 0;

    -- mains
    for _, memberData in ipairs(membersData) do

        -- unknown type/main
        if(memberData.errorType == nil and memberData.errorMain == nil) then

            -- increase main
            mainSize = mainSize + 1;

            -- check roles
            if(memberData.errorRoles == nil) then

                for role in pairs(memberData.roles) do

                    if(role == "dps") then
                        dpsSize = dpsSize + 1;
                    elseif(role == "tank") then
                        tankSize = tankSize + 1;
                    elseif(role == "heal") then
                        healSize = healSize + 1;
                    end

                end

            end

            -- alts
            for _, altData in ipairs(memberData.alts) do

                altSize = altSize + 1;

                -- check roles
                if(altData.errorRoles == nil) then

                    for role in pairs(altData.roles) do

                        if(role == "dps") then
                            dpsSize = dpsSize + 1;
                        elseif(role == "tank") then
                            tankSize = tankSize + 1;
                        elseif(role == "heal") then
                            healSize = healSize + 1;
                        end

                    end

                end

            end

        end

    end

    return {
        main = mainSize,
        alt = altSize,
        tank = tankSize,
        heal = healSize,
        dps = dpsSize
    };

end

function Utils.ContainsIgnoringCase(source, target)
    return string.find(string.lower(source), string.lower(target)) ~= nil
end

function Utils.FilterMembers(membersData, search)

    -- no filter
    if(search == "") then
        return {membersData, false};
    end

    local filteredMembers = {};

    -- iterate mains
    for _, memberData in ipairs(membersData) do

        -- if the name contains the search
        local isInserted = false;
        if(Utils.ContainsIgnoringCase(memberData.name, search)) then
            table.insert(filteredMembers, memberData);
            isInserted = true; -- skip alts
        end

        -- iterate alts
        if(isInserted == false and memberData.alts ~= nil) then
            for _, altData in ipairs(memberData.alts) do

                -- if the alt name contains the search -> insert the main
                if(Utils.ContainsIgnoringCase(altData.name, search)) then
                    table.insert(filteredMembers, memberData);
                    break; -- insert at first occurrence
                end

            end
        end

    end

    return {filteredMembers, true};

end

function Utils.IsInGroup()
    return IsInGroup();
end

function Utils.GetGroupMembers()

    local groupMembers = {};

    -- get the group type
    local groupType = nil;
    if(IsInRaid()) then
        groupType = "raid";
    elseif(IsInGroup()) then
        groupType = "party";
        -- player is not include in the list, for party groups.
        groupMembers[UnitName("player")] = true;
    end

    -- is a group
    if groupType ~= nil then
        for i = 1, GetNumGroupMembers() do
            local name = UnitName(groupType .. i);
            if name then
                groupMembers[name] = true;
            end
        end
    end

    return groupMembers;

end

function Utils.GetClassName(classFile)
    return classNameList[classFile]
end

function Utils.GetMemberIndex(name)

    name = name .. "-" .. GetNormalizedRealmName()
    for i = 1, GetNumGuildMembers() do
        local memberName = GetGuildRosterInfo(i)
        if memberName == name then
            return i;
        end
    end

    error("Member: " .. name .. " not found")

end

-- update the ilvl of the player
function Utils.UpdateMemberILVL(memberIndex, tank, heal, dps)

    local finalNote = "";

    if(tank ~= nil) then
        tank = Utils.TrimString(tank)
        if(tank ~= "") then
            finalNote = finalNote .. " - tank:" .. tank
        end
    end

    if(heal ~= nil) then
        heal = Utils.TrimString(heal)
        if(heal ~= "") then
            finalNote = finalNote .. " - heal:" .. heal
        end
    end

    if(dps ~= nil) then
        dps = Utils.TrimString(dps)
        if(dps ~= "") then
            finalNote = finalNote .. " - dps:" .. dps
        end
    end

    finalNote = string.sub(finalNote, 4)

    GuildRosterSetPublicNote(memberIndex, finalNote);

end

function Utils.UpdateMemberType(memberIndex, type, mainMember)

    local finalNote = "";
    if type == "Main" then
        finalNote = "main"
    elseif type == "Alt" then
        finalNote = "alt : " .. (mainMember ~= nil and mainMember or "")
    end

    GuildRosterSetOfficerNote(memberIndex, finalNote);

end

-- for printing selectable text
function Utils.OutputText(text)

    if not Utils.textFrame then
        local frame = CreateFrame("Frame", "TheEchoesTextFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(350, 250)
        frame:SetPoint("CENTER")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
        frame.title:SetText("Text Output")

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -30)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetFontObject(ChatFontNormal)
        editBox:SetWidth(310)
        editBox:SetAutoFocus(false)

        editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
        editBox:SetScript("OnTextChanged", function(self)
            scrollFrame:UpdateScrollChildRect()
        end)

        scrollFrame:SetScrollChild(editBox)

        frame.scrollFrame = scrollFrame
        frame.editBox = editBox
        Utils.textFrame = frame
    end

    Utils.textFrame.editBox:SetText(text or "")
    Utils.textFrame.editBox:HighlightText()
    Utils.textFrame:Show()
end