local _, Addon = ...;

local ColumnsData = {
    NAME = { startPoint = 5, width = 145, showTitle = true },
    TANK = { startPoint = 155, width = 40, showTitle = true },
    HEAL = { startPoint = 200, width = 40, showTitle = true },
    DPS = { startPoint = 245, width = 30, showTitle = true },
    EDIT = { startPoint = 280, width = 50, showTitle = false },
    TYPE = { startPoint = 335, width = 35, showTitle = true },
    LEVEL = { startPoint = 375, width = 40, showTitle = true },
    RANK = { startPoint = 420, width = 60, showTitle = true },
    ACTIONS = { startPoint = 485, width = 135, showTitle = false },
    ZONE = { startPoint = 615, width = 140, showTitle = true }
    --TOGGLEALTS = {startPoint = 0, width = 18, showTitle = false }
}

-- constants
local ContentFrame = TheEchoesFrame.Body.Content
local StatsLabel = TheEchoesFrame.InfoFrame.Stats
local MemoryUsageLabel = TheEchoesFrame.InfoFrame.MemoryUsage
local ErrorFrame = TheEchoesFrame.ErrorFrame;
local EditFrame = TheEchoesFrame.EditMemberFrame

-- setup TheEchoesFrame
local function setupTheEchoesFrame()

    -- get the columns frame
    local columnsFrame = TheEchoesFrame.ColumnsFrame

    -- calculate the total width
    local width = 98
    for k, v in pairs(ColumnsData) do

        width = width + v.width

        -- draw the title only if
        if v.showTitle then

            local text = columnsFrame:CreateFontString(k, "OVERLAY", "TheEchoesFontWhite")
            text:SetPoint("LEFT", v.startPoint, 0)
            text:SetText(k)
            text:SetWidth(v.width)
            text:SetJustifyH("LEFT");

        end

    end
    TheEchoesFrame:SetWidth(width)

    -- set the width of body#content
    ContentFrame:SetWidth(width - 42)

    -- set the scroll bar of body
    local body = TheEchoesFrame.Body;
    Addon.Utils.positionScrollBar(body);
    local scrollBar = body.ScrollBar;
    scrollBar:SetValue(0) -- Set initial scroll position
    ContentFrame:SetScript("OnMouseWheel", function(_, delta)
        scrollBar:SetValue(scrollBar:GetValue() - (delta * 27)) -- the step
    end)

    -- set the scroll bar of error frame
    local bodyError = ErrorFrame.Body;
    Addon.Utils.positionScrollBar(bodyError);
    local scrollBarError = bodyError.ScrollBar;
    scrollBarError:SetValue(0) -- Set initial scroll position
    bodyError.Content:SetScript("OnMouseWheel", function(_, delta)
        scrollBarError:SetValue(scrollBarError:GetValue() - (delta * 25)) -- the step
    end)

end

-- set the row for member
local MemberRowPool
local function setMember(rowIndex, memberData, memberType)

    local row = MemberRowPool:Acquire()
    row:SetPoint("TOP", 0, -(rowIndex*27))
    row:SetSize(ContentFrame:GetWidth(), 25)

    -- prepare few with multiple usages data
    local memberOnline = memberData.online
    local textAlpha
    if(memberOnline) then
        textAlpha = 1
    else
        textAlpha = 0.4
    end

    -- set background color
    if memberData.name == TheEchoes.PlayerName then
        row.Background:SetColorTexture(0, 0.75, 1, 0.17) -- blue
    elseif memberData.isSameGroup then
        row.Background:SetColorTexture(1, 0.55, 0, 0.17) -- green
    elseif memberOnline then -- is online
        row.Background:SetColorTexture(0.4, 0.4, 0.4, 0.17) -- less transparent online
    elseif memberType == "Main" then -- is offline main
        row.Background:SetColorTexture(0.4, 0.4, 0.4, 0.03) -- more transparent offline
    end

    -- set toggle alts button
    --[[local toggleAlts = row.ToggleAlts;
    if memberType == "Alt" then
        toggleAlts:Hide();
    else
        local isToggleAlts = memberData["toggleAlts"];
        local icon = toggleAlts.ArrowIcon;
        if isToggleAlts == true then
            icon:SetTexCoord(0.95, 0.63, 0.95, 0, 0, 0.63, 0, 0)
            icon:SetSize(15, 10);
            memberData["toggleAlts"] = false;
        else
            icon:SetTexCoord(0, 0.63, 0.95, 0.63, 0, 0, 0.95, 0 );
            icon:SetSize(10, 15);
            memberData["toggleAlts"] = true;
        end
        toggleAlts:Show();
        toggleAlts:SetScript("OnClick", function()
            isToggleAlts = memberData["toggleAlts"];
            print(isToggleAlts);
            if isToggleAlts == true then
                icon:SetTexCoord(0.95, 0.63, 0.95, 0, 0, 0.63, 0, 0)
                icon:SetSize(15, 10);
                memberData["toggleAlts"] = false;
            else
                icon:SetTexCoord(0, 0.63, 0.95, 0.63, 0, 0, 0.95, 0 );
                icon:SetSize(10, 15);
                memberData["toggleAlts"] = true;
            end
        end)
    end]]

    -- get the column data for name
    local columnDataName = ColumnsData.NAME

    -- get the frame for icon+name
    local nameFrame = row.Name

    -- set the icon and name
    local nameIcon = nameFrame.Icon;
    local nameText = nameFrame.Text;
    local className = memberData.class;
    nameIcon:SetTexture("Interface\\TargetingFrame\\UI-CLASSES-CIRCLES")
    nameIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[className]))
    nameText:SetText(memberData.name)

    local r, g, b = GetClassColor(className)
    nameText:SetTextColor(r, g, b, textAlpha)

    -- set the position of row
    if memberType == "Main" then
        nameFrame:SetSize(columnDataName.width, 27)
        nameFrame:SetPoint("LEFT", columnDataName.startPoint, 0)
        nameText:SetWidth(columnDataName.width - 20)
    else
        nameFrame:SetSize(columnDataName.width - 10, 27)
        nameFrame:SetPoint("LEFT", columnDataName.startPoint + 10, 0)
        nameText:SetWidth(columnDataName.width - 30)
    end

    -- roles of the member
    local memberRoles = memberData.roles

    -- set the tank
    local tankText = row.Tank
    tankText:SetText(memberRoles.TANK)
    tankText:SetWidth(ColumnsData.TANK.width)
    tankText:SetAlpha(textAlpha)

    -- set the heal
    local healText = row.Heal
    healText:SetText(memberRoles.HEAL)
    healText:SetWidth(ColumnsData.HEAL.width)
    healText:SetAlpha(textAlpha)

    -- set the dps
    local dpsText = row.DPS
    dpsText:SetText(memberRoles.DPS)
    dpsText:SetWidth(ColumnsData.DPS.width)
    dpsText:SetAlpha(textAlpha)

    -- set the edit button only if it exists
    local editButton = row.Edit
    if(editButton ~= nil) then
        editButton:Size(ColumnsData.EDIT.width-5, 20)
        editButton:SetScript("OnClick", function()
            EditFrame:Open(
                    memberData.name, memberOnline, memberData.lastOnline, className, memberData.level,
                    memberData.rank, memberData.rankIndex, memberRoles.TANK, memberRoles.HEAL, memberRoles.DPS,
                    memberType, memberData.main, memberData.note, memberData.officerNote
            );
        end)
        editButton:Show()
    end

    -- set the type
    local typeText = row.Type
    typeText:SetText(memberType)
    typeText:SetWidth(ColumnsData.TYPE.width)
    typeText:SetAlpha(textAlpha)

    -- set the level
    local levelText = row.Level
    levelText:SetText(memberData.level)
    levelText:SetWidth(ColumnsData.LEVEL.width)
    levelText:SetAlpha(textAlpha)

    -- set the rank
    local rankText = row.Rank
    rankText:SetText(memberData.rank)
    rankText:SetWidth(ColumnsData.RANK.width)
    rankText:SetAlpha(textAlpha)

    if memberData.online and memberData.name ~= TheEchoes.PlayerName then

        -- set the invite button
        local inviteButton = row.Invite
        inviteButton:Size((ColumnsData.ACTIONS.width * 0.44) - 5, 20)
        inviteButton:SetScript("OnClick", function()
            InviteUnit(memberData.name)
        end)
        inviteButton:Show()

        -- set the whisper button
        local whisperButton = row.Whisper
        whisperButton:Size((ColumnsData.ACTIONS.width * 0.56) - 5, 20)
        whisperButton:SetScript("OnClick", function()
            ChatFrame_SendTell(memberData.name)
        end)
        whisperButton:Show()

    end

    -- set the zone
    local zoneText = row.Zone
    zoneText:SetWidth(ColumnsData.ZONE.width)
    zoneText:SetAlpha(textAlpha)
    zoneText:SetPoint("LEFT", rankText, "RIGHT", ColumnsData.ACTIONS.width, 0)
    if(memberOnline) then
        zoneText:SetText(memberData.zone)
    else
        zoneText:SetText("Seen: " .. memberData.lastOnline)
    end

    row:Show()

end

-- Print the memory usage
local function setMemoryUsage()

    UpdateAddOnMemoryUsage()
    local memoryUsageMB = tonumber(string.format("%.3f", (GetAddOnMemoryUsage("TheEchoes")/1024)))

    -- call gc
    if(memoryUsageMB >= 2) then
        collectgarbage("collect")
    end

    -- set the message
    if(memoryUsageMB >= 10) then -- if reaches here and never decrease, it means there is a problem
        MemoryUsageLabel:SetTextColor(255, 0, 0, 1)
        MemoryUsageLabel:SetText("Contact the author! Unless you exported data - Memory usage: " .. memoryUsageMB .. " MB")
    else
        if(memoryUsageMB >= 5) then
            MemoryUsageLabel:SetTextColor(255, 255, 0, 1)
        else
            MemoryUsageLabel:SetTextColor(1, 1, 1, 1)
        end
        MemoryUsageLabel:SetText("Memory usage: " .. memoryUsageMB .. " MB")
    end

end

-- create a button for every member which couldn't been parsed.
local function setErrorMembers(errorMembers)

    local errorContent = ErrorFrame.Body.Content;

    -- clear the content
    for _, childFrame in ipairs({errorContent:GetChildren()}) do
        childFrame:SetParent(nil)
        childFrame:ClearAllPoints()
        childFrame:SetScript("OnClick", nil)
        childFrame:Hide()
    end

    -- if exist error members
    if Addon.Utils.size(errorMembers) > 0 then

        local startPoint = 5;
        local maxWidth = 0;
        for _, member in ipairs(errorMembers) do

            local name = member.name;

            local button = CreateFrame("Button", "button", errorContent, "TheEchoesButtonDesaturatedTemplate");
            button:SetPoint("TOPLEFT", 5, -startPoint);
            button:SetText(name);
            button:SetHeight(24);
            button:OnLoad(); -- trigger onload

            -- make the text green if the player is online
            if(member.online) then
                button.Text:SetTextColor(0.2, 0.9, 0.2);
            end

            local width = button:GetWidth();
            if(width > maxWidth) then
                maxWidth = width;
            end

            button:SetScript("OnClick", function()
                    EditFrame:Open(name, member.online, member.lastOnline, member.class, member.level, member.rank, member.rankIndex, nil, nil, nil, nil, nil, member.note, member.officerNote)
            end)

            -- starting point of the next button, more easy this way than anchoring.
            startPoint = startPoint + 25;

        end

        -- set the height of the content
        errorContent:SetHeight(startPoint + 5);

        -- set the frame height
        local totalHeight = startPoint + 29 -- top(5) + title(12) + space(5) + bottom(2) + space(5);
        if(totalHeight > 350) then -- heigh of theechoes frame
            totalHeight = 350;
        end

        maxWidth = maxWidth + 10 + ErrorFrame.Body.ScrollBar:GetWidth(); -- left(5) + right(5) + scrollWidth.
        ErrorFrame:SetSize(maxWidth, totalHeight);
        --errorContent:SetWidth(maxWidth);

        ErrorFrame:Show()

    else
        ErrorFrame:Hide()
    end

end

-- listening the guild events and update the interface
local guildEventListener = CreateFrame("Frame", "TheEchoesGuildEventListener")
local threadTriggerGuildEvent;
local function startListening()

    -- start a tread which is triggering guild events
    GuildRoster();
    threadTriggerGuildEvent = C_Timer.NewTicker(10.1, function()
        GuildRoster();
    end)

    -- register the listener for guild event
    guildEventListener:RegisterEvent("GUILD_ROSTER_UPDATE")
    guildEventListener:SetScript("OnEvent", function(_, listenerEvent)
        if listenerEvent == "GUILD_ROSTER_UPDATE" then
            TheEchoesUI.GuildData = TheEchoes.getGuildData()
            TheEchoesUI.refreshUI()
        end
    end)

    -- get the actual data
    TheEchoesUI.GuildData = TheEchoes.getGuildData()
    TheEchoesUI.refreshUI()

end
local function cancelListening()

    -- unregister the listener
    guildEventListener:UnregisterEvent("GUILD_ROSTER_UPDATE")
    guildEventListener:SetScript("OnEvent", nil)

    -- cancel the thread
    if(threadTriggerGuildEvent ~= nil) then
        threadTriggerGuildEvent:Cancel()
        threadTriggerGuildEvent = nil
    end

    -- clear guild data
    TheEchoesUI.GuildData = nil

end

TheEchoesUI = {

    GuildData = nil,

    -- init function
    init = function()

        InitTheEchoesFrame() -- method from TheEchoesFrame.lua
        setupTheEchoesFrame()

        TheEchoesUI.close()

        -- create the poll
        MemberRowPool = CreateFramePool("FRAME", ContentFrame, "TheEchoesMemberRow", function(_, frame)
            frame:Hide()
            frame:ClearAllPoints()
            frame.Background:SetColorTexture(0, 0, 0, 0)
            frame.Edit:SetScript("OnClick", nil)
            frame.Edit:Hide()
            frame.Invite:SetScript("OnClick", nil)
            frame.Invite:Hide()
            frame.Whisper:SetScript("OnClick", nil)
            frame.Whisper:Hide()
        end)

    end,

    -- the stats of ui
    isOpen = function()
        return TheEchoesFrame:IsVisible()
    end,

    -- open the ui
    -- and start things
    open = function()
        TheEchoesFrame:Show()
        startListening()
    end,

    -- close the ui
    -- and stop things
    close = function()
        TheEchoesFrame:Hide()
        cancelListening()
    end,

    -- toggle the ui
    toggle = function()
        if(TheEchoes.init) then
            if(TheEchoesUI.isOpen()) then
                TheEchoesUI.close()
            else
                TheEchoesUI.open()
            end
            return TheEchoesUI.isOpen()
        else
            print("TheEchoes is not init.")
        end
    end,

    -- set the date in ui
    refreshUI = function()

        local membersData, totalSize, onlineSize, mainSize, altSize, tankSize, healSize, dpsSize, errorMembers = unpack(TheEchoesUI.GuildData)

        -- set the guild message
        local guildMessage = GetGuildRosterMOTD()
        TheEchoesFrame.GuildMessageFrame.Text:SetText(guildMessage)

        -- reset the rows
        MemberRowPool:ReleaseAll()

        -- filters
        local isHideOffAlts = TheEchoesFrame.HideOffAltsCheckButton:GetChecked()
        local searchValue = Addon.Utils.trimString(TheEchoesFrame.SearchInput:GetText())

        -- apply search
        if(string.len(searchValue) > 0) then

            local index = 0
            for _, memberData in ipairs(membersData) do

                -- if the main was set
                local isMain = false

                -- main name contains
                if(Addon.Utils.containsIgnoringCase(memberData.name, searchValue)) then

                    -- set member
                    setMember(index, memberData, "Main")
                    index = index+1
                    isMain = true

                    -- set all alts
                    for _, altData in ipairs(memberData.alts) do

                        setMember(index, altData, "Alt")
                        index = index+1

                    end

                end

                -- search through alts only if main was not set
                if(isMain == false) then

                    for _, altData in ipairs(memberData.alts) do

                        if(Addon.Utils.containsIgnoringCase(altData.name, searchValue)) then

                            -- set main only once
                            if(isMain == false) then
                                setMember(index, memberData, "Main")
                                index = index+1
                                isMain = true
                            end

                            setMember(index, altData, "Alt")
                            index = index+1

                        end

                    end

                end

            end

        else -- print normally

            local index = 0
            for _, memberData in ipairs(membersData) do

                setMember(index, memberData, "Main")
                index = index+1

                for _, altData in ipairs(memberData.alts) do

                    -- if not hide alts or is online
                    if(isHideOffAlts == false or altData.online) then
                        setMember(index, altData, "Alt")
                        index = index+1
                    end

                end

            end

        end

        -- set the size of scrollContent
        ContentFrame:SetHeight(27 * MemberRowPool:GetNumActive()) -- 27 per row. Check in setMember

        -- set the stats
        StatsLabel:SetText(
                "Online members: " .. onlineSize .. "/" .. totalSize ..
                " (main: " .. mainSize .. ", alt: " .. altSize .. ")" ..
                " (tank: " .. tankSize .. ", heal: " .. healSize .. ", dps: " .. dpsSize .. ")"
        )

        -- set the memory usage
        setMemoryUsage()

        -- set the error members
        setErrorMembers(errorMembers);

    end

}