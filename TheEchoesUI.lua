-- Bindings.xml globals
BINDING_HEADER_THE_ECHOES_UI = "User Interfece"
BINDING_NAME_THE_ECHOES_TOGGLE = "Toggle Open/Close"

local ColumnsData = {
    NAME = { startPoint = 5, width = 145, showTitle = true },
    TANK = { startPoint = 0, width = 50, showTitle = true },
    HEAL = { startPoint = 0, width = 50, showTitle = true },
    DPS = { startPoint = 0, width = 35, showTitle = true },
    EDIT = { startPoint = 0, width = 60, showTitle = false },
    TYPE = { startPoint = 0, width = 40, showTitle = true },
    LEVEL = { startPoint = 0, width = 40, showTitle = true },
    RANK = { startPoint = 0, width = 60, showTitle = true },
    ACTIONS = { startPoint = 0, width = 150, showTitle = false },
    ZONE = { startPoint = 0, width = 200, showTitle = true },
}

-- constants
local ContentFrame = TheEchoesFrame.ScrollFrame.Content
local StatsLabel = TheEchoesFrame.InfoFrame.Stats
local MemoryUsageLabel = TheEchoesFrame.InfoFrame.MemoryUsage
local ErrorFrame = TheEchoesFrame.ErrorFrame
local EditFrame = TheEchoesFrame.EditMemberFrame

-- setup TheEchoesFrame
local function setupTheEchoesFrame()

    -- calculate the width
    local width = 98
    for _, v in pairs(ColumnsData) do
        width = width + v.width
    end
    -- if the player is not mod, subtract the width of edit
    if isMod() == false  then
        width = width - ColumnsData.EDIT.width
    end
    TheEchoesFrame:SetWidth(width)

    -- prepare the columns
    local columnsText
    if isMod() then
        columnsText = { "NAME", "TANK", "HEAL", "DPS", "EDIT", "TYPE", "LEVEL", "RANK", "ACTIONS", "ZONE"}
    else
        columnsText = { "NAME", "TANK", "HEAL", "DPS", "TYPE", "LEVEL", "RANK", "ACTIONS", "ZONE"}
    end

    -- get the columns frame
    local columnsFrame = TheEchoesFrame.ColumnsFrame

    -- create columns frame
    for i, v in ipairs(columnsText) do

        local columnData = ColumnsData[v];

        -- set the startPoint equal with prev column startPoint + width
        if i > 1 then
            local previousColumnData = ColumnsData[columnsText[i-1]];
            columnData.startPoint = previousColumnData.startPoint + previousColumnData.width + 5
        end

        -- draw the title only if
        if columnData.showTitle then

            local text = columnsFrame:CreateFontString(v, "OVERLAY", "FontWhite")
            text:SetPoint("LEFT", columnData.startPoint, 0)
            text:SetTextColor(1, 1, 1, 1)
            text:SetText(v)
            text:SetWidth(columnData.width)
            text:SetJustifyH("LEFT");

        end

    end

    -- set the width of scrollframe#content
    ContentFrame:SetWidth(width - 42)
    local scrollBar = TheEchoesFrame.ScrollFrame.ScrollBar
    scrollBar:SetMinMaxValues(0, 503) -- the height of scrollFrame
    scrollBar:SetValue(0) -- Set initial scroll position
    ContentFrame:SetScript("OnMouseWheel", function(_, delta)
        scrollBar:SetValue(scrollBar:GetValue() - (delta * 25)) -- the step
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
        row.Background:SetColorTexture(0, 0.75, 1, 0.2) -- blue
    elseif memberOnline then -- is online
        row.Background:SetColorTexture(0.4, 0.4, 0.4, 0.2) -- less transparent online
    elseif memberType == "Main" then -- is offline main
        row.Background:SetColorTexture(0.4, 0.4, 0.4, 0.07) -- more transparent offline
    end

    -- get the column data for name
    local columnDataName = ColumnsData.NAME

    -- get the frame for icon+name
    local nameFrame = row.Name

    -- set the icon and name
    local nameIcon = nameFrame.Icon;
    local nameText = nameFrame.Text;
    nameIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    nameIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[memberData.class]))
    nameText:SetText(memberData.name)
    nameText:SetAlpha(textAlpha)

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
            EditFrame:Open(memberData.name, memberRoles.TANK, memberRoles.HEAL, memberRoles.DPS, memberType, memberData.main, false)
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
        inviteButton:Size((ColumnsData.ACTIONS.width/2) - 5, 20)
        inviteButton:SetScript("OnClick", function()
            InviteUnit(memberData.name)
        end)
        inviteButton:Show()

        -- set the whisper button
        local whisperButton = row.Whisper
        whisperButton:Size((ColumnsData.ACTIONS.width/2) - 5, 20)
        whisperButton:SetScript("OnClick", function()
            ChatFrame_SendTell(memberData.name)
        end)
        whisperButton:Show()

    end

    -- set the zone
    local zoneText = row.Zone
    zoneText:SetWidth(ColumnsData.ZONE.width)
    zoneText:SetAlpha(textAlpha)
    zoneText:ClearAllPoints()
    zoneText:SetPoint("LEFT", rankText, "RIGHT", ColumnsData.ACTIONS.width + 10, 0)
    if(memberOnline) then
        zoneText:SetText(memberData.zone)
    else
        zoneText:SetText("Last online: " .. memberData.lastOnline .. " ago")
    end

    row:Show()

end

-- Print the memory usage
local function setMemoryUsage()

    UpdateAddOnMemoryUsage()
    local memoryUsageMB = tonumber(string.format("%.3f", (GetAddOnMemoryUsage("TheEchoes")/1024)))
    MemoryUsageLabel:SetText("Memory usage: " .. memoryUsageMB .. " MB")
    if(memoryUsageMB > 10) then -- if reaches here and never decrease, it means there is a problem
        collectgarbage("collect")
        MemoryUsageLabel:SetTextColor(255, 0, 0, 1)
        MemoryUsageLabel:SetText("Tell to Doomfury!!! - Memory usage: " .. memoryUsageMB .. " MB")
    elseif(memoryUsageMB > 5) then
        collectgarbage("collect")
        MemoryUsageLabel:SetTextColor(255, 255, 0, 1)
    else
        MemoryUsageLabel:SetTextColor(1, 1, 1, 1)
    end

end

-- create a button for every member which couldn't been parsed.
local function setErrorMembers(errorMembers)

    -- clear the frame
    for _, childFrame in ipairs({ErrorFrame:GetChildren()}) do
        childFrame:SetParent(nil)
        childFrame:ClearAllPoints()
        childFrame:SetScript("OnClick", nil)
        childFrame:Hide()
    end

    -- if exist error members
    if size(errorMembers) > 0 then

        local startPoint = 0;
        for _, member in ipairs(errorMembers) do

            local name = member.name;

            local width = (string.len(name) * 10) + 20;

            local button = CreateFrame("Button", "button", ErrorFrame, "TheEchoesButtonRedTemplate")
            button:SetPoint("LEFT", startPoint, 0)
            button:Size(width, 24)
            button:SetText(name)
            button:SetScript("OnClick", function()

                if(isMod()) then
                    EditFrame:Open(name, nil, nil, nil, nil, nil, true, member.note, member.officerNote)
                end

            end)

            startPoint = startPoint + width + 5

        end

        ErrorFrame:Show()
        return true

    else
        ErrorFrame:Hide()
        return false
    end

end

TheEchoesUI = {

    -- init function
    init = function()

        InitTheEchoesFrame() -- method from TheEchoesFrame.lua
        setupTheEchoesFrame()

        TheEchoesUI.close()

        -- create the poll
        if isMod() then
            MemberRowPool = CreateFramePool("FRAME", ContentFrame, "TheEchoesModMemberRow", function(_, frame)
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
        else
            MemberRowPool = CreateFramePool("FRAME", ContentFrame, "TheEchoesMemberRow", function(_, frame)
                frame:Hide()
                frame:ClearAllPoints()
                frame.Background:SetColorTexture(0, 0, 0, 0)
                frame.Invite:SetScript("OnClick", nil)
                frame.Invite:Hide()
                frame.Whisper:SetScript("OnClick", nil)
                frame.Whisper:Hide()
            end)
        end

    end,

    -- the stats of ui
    isOpen = function()
        return TheEchoesFrame:IsVisible()
    end,

    -- open the ui
    -- and start things
    open = function()
        TheEchoes.startAutoUpdate()
        TheEchoesFrame:Show()
    end,

    -- close the ui
    -- and stop things
    close = function()
        TheEchoesFrame:Hide()
        TheEchoes.stopAutoUpdate()
    end,

    -- toggle the ui
    toggle = function()
        if(TheEchoesUI.isOpen()) then
            TheEchoesUI.close()
        else
            TheEchoesUI.open()
        end
        return TheEchoesUI.isOpen()
    end,

    -- set the date in ui
    setData = function(membersData, totalSize, onlineSize, mainSize, altSize, errorMembers)

        -- set the guild message
        local guildMessage = GetGuildRosterMOTD()
        TheEchoesFrame.GuildMessageFrame.Text:SetText(guildMessage)

        -- reset the rows
        MemberRowPool:ReleaseAll()

        -- set the rows
        local index = 0
        for _, memberData in ipairs(membersData) do

            setMember(index, memberData, "Main")
            index = index+1

            local isHideOffAlts = TheEchoesFrame.HideOffAltsCheckButton:GetChecked()

            for _, altData in ipairs(memberData.alts) do

                if(isHideOffAlts == false or altData.online) then

                    setMember(index, altData, "Alt")
                    index = index+1

                end

            end

        end

        -- set the size of scrollContent
        ContentFrame:SetHeight(27 * MemberRowPool:GetNumActive()) -- 27 per row. Check in setMember

        -- set the stats
        StatsLabel:SetText("Online members: " .. onlineSize .. "/" .. totalSize .. " (main: " .. mainSize .. ", alt: " .. altSize .. ")")

        -- set the memory usage
        setMemoryUsage()

        -- default height, without member errors.
        local mainFrameHeight = 740

        -- set the error members
        local isError = setErrorMembers(errorMembers)
        if(isError) then mainFrameHeight = 765 end

        -- set the heigh of mainFrame
        TheEchoesFrame:SetHeight(mainFrameHeight)

    end

}