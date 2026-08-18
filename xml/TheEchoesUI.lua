local _, Addon = ...;

local playerName;
local isOpen;
local memberRowPool;
local columnsOrder = {"NAME", "TANK", "HEAL", "DPS", "EDIT", "TYPE", "LVL", "RANK", "INV", "WHISP", "ZONE", "PNOTE"}
local columnsData = {
    NAME = { margin = 5, width = 135, showTitle = true },
    TANK = { margin = 5, width = 40, showTitle = true },
    HEAL = { margin = 5, width = 40, showTitle = true },
    DPS = { margin = 5, width = 30, showTitle = true },
    EDIT = { margin = 0, width = 30, showTitle = false },
    TYPE = { margin = 5, width = 35, showTitle = true },
    LVL = { margin = 7, width = 30, showTitle = true },
    RANK = { margin = 7, width = 60, showTitle = true },
    INV = { margin = 0, width = 30, showTitle = false },
    WHISP = { margin = 0, width = 30, showTitle = false},
    ZONE = { margin = 5, width = 150, showTitle = true },
    PNOTE = { margin = 0, width = 30, showTitle = false }
}
local contentWidth = 0;

TheEchoesUIMixin = {}

function TheEchoesUIMixin:Init()

    -- calculate startPoint of every column
    local startPoint = 0;
    for _, key in ipairs(columnsOrder) do
        local columnData = columnsData[key];
        local newPoint = startPoint + columnData["margin"];
        columnData["startPoint"] = newPoint;
        startPoint = newPoint + columnData["width"];
    end
    contentWidth = startPoint + 5; -- the last value is the total width.

    -- initial state
    self:Hide();
    isOpen = false;

    -- initial position
    TheEchoesUIPosition = nil;
    if(TheEchoesUIPosition == nil) then -- default value
        TheEchoesUIPosition = {"CENTER", nil, "CENTER", 0, 0};
    end
    self:SetPoint(unpack(TheEchoesUIPosition));

    -- movable
    self:SetClampedToScreen(true);
    self:SetMovable(true);
    self:RegisterForDrag("LeftButton");
    self:SetScript("OnDragStart", self.StartMoving)
    self:SetScript("OnDragStop", function()
        self:StopMovingOrSizing()
        --save the position
        TheEchoesUIPosition = {self:GetPoint(0)}
    end);

    -- close button
    self.CloseButton:SetScript("OnClick", function() self:Close() end)

    -- esc key
    self:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then
            self:Close();
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- capture on show/hide
    self:SetScript("OnShow", function()
        isOpen = true;
        Addon.GuildData.StartListening(); -- listen for guild events
    end);
    self:SetScript("OnHide", function()

        isOpen = false;
        Addon.GuildData.StopListening(); -- stop listen for guild events

        -- hide all the sub frames
        self.EditMemberFrame:Hide();
        self.SettingsFrame:Hide();
        self.GuildInfoFrame:Hide();
        self.EditGMFrame:Hide();
        self.ExportFrame:Hide();
        self.PersonalNoteFrame:Hide();

    end);

    -- references for body and content
    local body = self.Body;
    local bodyScrollBar = body.ScrollBar;
    local bodyContent = body.Content;

    -- setup de scrollbar
    Addon.Utils.PositionScrollBar(body);
    bodyContent:SetScript("OnMouseWheel", function(_, delta)
        bodyScrollBar:SetValue(bodyScrollBar:GetValue() - (delta * 27)) -- the height of one member row
    end)

    -- initialize the drop down menu
    Addon.DropDownMenu:Init();

    -- get the player name;
    playerName = UnitName("player");

    -- initialize the pool of frames
    memberRowPool = CreateFramePool("FRAME", bodyContent, "TheEchoesMemberRow", function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame.Background:SetColorTexture(0, 0, 0, 0)
        frame.Tank:SetText("");
        frame.Heal:SetText("");
        frame.DPS:SetText("");
        frame.Edit:SetScript("OnClick", nil)
        frame.Invite:SetScript("OnClick", nil)
        frame.Invite:Hide()
        frame.Whisper:SetScript("OnClick", nil)
        frame.Whisper:Hide()
    end)

    -- print the titles and calculate total width
    local columnsFrame = self.ColumnsFrame;
    for k, v in pairs(columnsData) do
        -- draw the title only if
        if v.showTitle then
            local text = columnsFrame:CreateFontString(k, "OVERLAY", "TheEchoesFontWhite")
            text:SetPoint("LEFT", v.startPoint, 0)
            text:SetText(k)
            text:SetWidth(v.width)
            text:SetJustifyH("LEFT");
        end
    end

    -- set the content width
    bodyContent:SetWidth(contentWidth);

    -- set the width of the ui
    -- right-left-padding(5+5) + scrollbar(16) + space between content and bar (3)
    self:SetWidth(contentWidth + 29);

    -- initialize the settings
    TheEchoesUI.SettingsFrame:Init();

end

function TheEchoesUIMixin:Close()
    self:Hide();
    collectgarbage("collect"); -- clear the garbage;
end
function TheEchoesUIMixin:Open()
    self:Show();
end
function TheEchoesUIMixin:Toggle()
    if(isOpen) then
        self:Close();
    else
        self:Open();
    end
end

--- RETRIEVE ----
function TheEchoesUIMixin:IsOpen()
    return isOpen;
end
function TheEchoesUIMixin:GetSearch()
    return Addon.Utils.TrimString(
            self.SearchFrame.Input:GetText()
    );
end
function TheEchoesUIMixin:IsHideOffAlts()
    return self.SettingsFrame.HideOffAlts:GetChecked();
end
function TheEchoesUIMixin:IsIgnoreErrorParsing()
    return self.SettingsFrame.IgnoreErrorParsing:GetChecked();
end

--- UPDATE ---
function TheEchoesUIMixin:UpdateGuildMessage()
    self.GuildMessageFrame.Text:SetText(GetGuildRosterMOTD());
end
function TheEchoesUIMixin:UpdateInfo(onlineSize, totalSize, mainSize, altSize, tankSize, healSize, dpsSize)

    local infoFrame = self.InfoFrame;

    --- STATS ---
    infoFrame.Stats:SetText(
            "Online members: " .. onlineSize .. "/" .. totalSize ..
                    " (main: " .. mainSize .. ", alt: " .. altSize .. ")" ..
                    " (tank: " .. tankSize .. ", heal: " .. healSize .. ", dps: " .. dpsSize .. ")"
    )

    --- MEMORY ---
    UpdateAddOnMemoryUsage()
    local memoryUsageMB = tonumber(string.format("%.3f", (GetAddOnMemoryUsage("TheEchoes")/1024)))

    -- call gc
    if(memoryUsageMB >= 5) then
        collectgarbage("collect")
    end

    -- set the message
    local memoryLabel = infoFrame.MemoryUsage;
    if(memoryUsageMB >= 10) then -- if reaches here and never decrease, it means there is a problem
        memoryLabel:SetTextColor(255, 0, 0, 1)
        memoryLabel:SetText("Contact the author! Memory usage: " .. memoryUsageMB .. " MB")
    else
        if(memoryUsageMB >= 7) then
            memoryLabel:SetTextColor(255, 255, 0, 1)
        else
            memoryLabel:SetTextColor(1, 1, 1, 1)
        end
        memoryLabel:SetText("Memory usage: " .. memoryUsageMB .. " MB")
    end

end
function TheEchoesUIMixin:UpdateMembers(membersData, isSearch)

    -- clear the rows
    memberRowPool:ReleaseAll();

    -- apply hide off alts only if is no search
    local isHideOffAlts = self:IsHideOffAlts() and (isSearch == false);

    -- error parsing
    local isIgnoreErrorParsing = self:IsIgnoreErrorParsing();
    local errorMembers;
    if(isIgnoreErrorParsing == false) then
        errorMembers = {}; -- initialize only if requires.
    end

    -- iterate every member/alt and add the rows
    local indexRow = 0;
    for _, memberData in ipairs(membersData) do

        -- if not ignore and has any error
        if(isIgnoreErrorParsing == false and (memberData.errorRoles or memberData.errorType or memberData.errorMain)) then

            -- put it in the error table
            table.insert(errorMembers, memberData);

            -- add all the alts too
            local alts = memberData.alts;
            if(alts ~= nil) then
                for _, altData in ipairs(alts) do
                    table.insert(errorMembers, altData);
                end
            end

        else

            -- mains
            self:SetMember(indexRow, memberData, "Main");
            indexRow = indexRow + 1;

            -- alts
            local alts = memberData.alts;
            if(alts ~= nil) then
                for _, altData in ipairs(alts) do

                    -- if not ignore and has any error
                    if(isIgnoreErrorParsing == false and (altData.errorRoles or altData.errorType or altData.errorMain)) then

                        -- put it in the error table
                        table.insert(errorMembers, altData);

                    else

                        -- print only online alts
                        if(isHideOffAlts) then
                            if(altData.isOnline == true) then
                                self:SetMember(indexRow, altData, "Alt");
                                indexRow = indexRow + 1;
                            end
                        else -- print all alts
                            self:SetMember(indexRow, altData, "Alt");
                            indexRow = indexRow + 1;
                        end

                    end

                end
            end

        end

    end

    -- set the height of content
    self.Body.Content:SetHeight(27 * memberRowPool:GetNumActive()) -- 27 per row. Check in setMember

    -- print errors
    if(errorMembers ~= nil) then
        self.ErrorFrame:SetErrorMembers(errorMembers);
    else
        self.ErrorFrame:Hide()
    end

end
function TheEchoesUIMixin:SetMember(indexRow, memberData, type)

    -- get the row
    local row = memberRowPool:Acquire();
    row:SetPoint("TOP", 0, -(indexRow*27));
    row:SetSize(contentWidth, 25);

    -- references
    local isOnline = memberData.isOnline;
    local textAlpha;
    if(isOnline) then
        textAlpha = 1;
    else
        textAlpha = 0.4;
    end

    -- set background color
    if memberData.name == playerName then
        row.Background:SetColorTexture(0, 0.75, 1, 0.17); -- blue
    elseif memberData.isInGroup then
        row.Background:SetColorTexture(1, 0.55, 0, 0.17); -- orange
    elseif isOnline then -- is online
        row.Background:SetColorTexture(0.4, 0.4, 0.4, 0.17); -- less transparent online
    elseif type == "Main" then -- is offline main
        row.Background:SetColorTexture(0.4, 0.4, 0.4, 0.03); -- more transparent offline
    end

    -- get the frame for icon+name
    local nameFrame = row.Name;

    -- set the icon and name
    local nameIcon = nameFrame.Icon;
    local nameText = nameFrame.Text;
    local className = memberData.class;
    nameIcon:SetTexture("Interface\\TargetingFrame\\UI-CLASSES-CIRCLES");
    nameIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[className]));
    nameText:SetText(memberData.name);
    local r, g, b = GetClassColor(className)
    nameText:SetTextColor(r, g, b, textAlpha)

    -- set the position of row
    local columnDataName = columnsData.NAME;
    if type == "Main" then
        nameFrame:SetSize(columnDataName.width, 27);
        nameFrame:SetPoint("LEFT", columnDataName.startPoint, 0);
        nameText:SetWidth(columnDataName.width - 20);
    else -- position 10 points to right
        nameFrame:SetSize(columnDataName.width - 10, 27);
        nameFrame:SetPoint("LEFT", columnDataName.startPoint + 10, 0);
        nameText:SetWidth(columnDataName.width - 30);
    end


    -- set the tank
    local columnDataTank = columnsData.TANK;
    local tankText = row.Tank;
    tankText:SetPoint("LEFT", columnDataTank.startPoint, 0);
    tankText:SetWidth(columnDataTank.width);
    tankText:SetAlpha(textAlpha);

    -- set the heal
    local columnDataHeal = columnsData.HEAL;
    local healText = row.Heal;
    healText:SetPoint("LEFT", columnDataHeal.startPoint, 0);
    healText:SetWidth(columnDataHeal.width);
    healText:SetAlpha(textAlpha);

    -- set the dps
    local columnDataDps = columnsData.DPS;
    local dpsText = row.DPS;
    dpsText:SetPoint("LEFT", columnDataDps.startPoint, 0);
    dpsText:SetWidth(columnDataDps.width);
    dpsText:SetAlpha(textAlpha);

    -- roles of the member
    if(memberData.errorRoles == nil) then

        local memberRoles = memberData.roles;

        tankText:SetText(memberRoles.tank);
        healText:SetText(memberRoles.heal);
        dpsText:SetText(memberRoles.dps);

    end

    -- set the edit button only if it exists
    local columnDataEdit = columnsData.EDIT;
    local editButton = row.Edit;
    editButton:SetPoint("LEFT", columnDataEdit.startPoint, 0);
    editButton:Size(columnDataEdit.width, 22);
    editButton:SetScript("OnClick", function()
        self.EditMemberFrame:Open(memberData);
    end);

    -- set the type
    local columnDataType = columnsData.TYPE;
    local typeText = row.Type;
    if(memberData.errorRoles or memberData.errorType or memberData.errorMain) then
        type = "?";
    end
    typeText:SetText(type);
    typeText:SetPoint("LEFT", columnDataType.startPoint, 0);
    typeText:SetWidth(columnDataType.width);
    typeText:SetAlpha(textAlpha);

    -- set the level
    local columnDataLvl = columnsData.LVL;
    local levelText = row.Level;
    levelText:SetText(memberData.level);
    levelText:SetPoint("LEFT", columnDataLvl.startPoint, 0);
    levelText:SetWidth(columnDataLvl.width);
    levelText:SetAlpha(textAlpha);

    -- set the rank
    local columnDataRank = columnsData.RANK;
    local rankText = row.Rank;
    rankText:SetText(memberData.rank);
    rankText:SetPoint("LEFT", columnDataRank.startPoint, 0);
    rankText:SetWidth(columnDataRank.width);
    rankText:SetAlpha(textAlpha);

    -- set the invite/whisper buttons
    if isOnline and memberData.name ~= playerName then

        -- set the invite button
        local columnDataInv = columnsData.INV;
        local inviteButton = row.Invite;
        inviteButton:SetPoint("LEFT", columnDataInv.startPoint, 0);
        inviteButton:Size(columnDataInv.width, 22);
        inviteButton:SetScript("OnClick", function()
            InviteUnit(memberData.name);
        end);
        inviteButton:Show();

        -- set the whisper button
        local columnDataWhisp = columnsData.WHISP;
        local whisperButton = row.Whisper;
        whisperButton:SetPoint("LEFT", columnDataWhisp.startPoint, 0);
        whisperButton:Size(columnDataWhisp.width, 22);
        whisperButton:SetScript("OnClick", function()
            ChatFrame_SendTell(memberData.name);
        end);
        whisperButton:Show();

    end

    -- set the zone
    local columnDataZone = columnsData.ZONE;
    local zoneText = row.Zone;
    zoneText:SetPoint("LEFT", columnDataZone.startPoint, 0);
    zoneText:SetWidth(columnDataZone.width);
    zoneText:SetAlpha(textAlpha);
    if(isOnline) then
        zoneText:SetText(memberData.zone);
    else
        zoneText:SetText("Seen: " .. memberData.lastSeen);
    end

    -- set the pnote
    local columnDataPNote = columnsData.PNOTE;
    local pNote = row.PNote;
    pNote:SetPoint("LEFT", columnDataPNote.startPoint, 0);
    pNote:Size(columnDataPNote.width, 22);
    pNote:SetScript("OnClick", function()
        self.PersonalNoteFrame:Open(memberData.name);
    end);

    row:Show();

end

------- SEARCH -------
TheEchoesSearchMixin = {};
function TheEchoesSearchMixin:Init()

    self.Input:SetScript("OnKeyUp", function(self, key)
        if key == "ESCAPE" then
            self:ClearFocus()
        end
    end)
    self.Input:SetScript("OnTextChanged", function(self)
        if(self:GetText() ~= "") then
            self.ClearButton:Show()
        else
            self.ClearButton:Hide()
        end
        Addon.Controller.RefreshUI()
    end)

end

------- GUILD INFO -------
TheEchoesGuildInfoMixin = {}
function TheEchoesGuildInfoMixin:Init()

    -- references
    local input = self.Body:GetScrollChild();
    local saveButton = self.SaveButton;

    -- position the scroll bar of body
    Addon.Utils.PositionScrollBar(self.Body)

    -- on show
    self:SetScript("OnShow", function()

        -- set the guild info
        input:SetText(GetGuildInfoText());

        -- enable/disable save button
        if(CanEditGuildInfo())then
            saveButton:SetEnable(true);
        else
            saveButton:SetEnable(false);
        end

    end);

    -- clear the text on hide
    self:SetScript("OnHide", function()
        input:SetText("");
    end);

    -- hide the frame on close button
    self.CloseButton:SetScript("OnClick", function()
        self:Hide();
    end);

    -- limit the characters
    input:SetMaxLetters(500);

    -- esc key
    input:SetScript("OnKeyDown", function(_, key)
        if(key == "ESCAPE")then
            self:Hide();
        end
    end);

    -- save button click
    saveButton:SetScript("OnClick", function()
        -- set the guild info
        SetGuildInfoText(input:GetText());
        self:Hide();
    end);

end

------ SETTINGS -------
TheEchoesSettingsMixin = {};
function TheEchoesSettingsMixin:Init()

    -- close button
    self.CloseButton:SetScript("OnClick", function()
        self:Hide();
    end);

    -- hide off alts
    local hideOffAlts = self.HideOffAlts;
    hideOffAlts:GetCheckedTexture():SetDesaturated(true);
    hideOffAlts:SetScript("OnClick", function()
        Addon.Controller.RefreshUI();
    end);

    -- ignore error parsing
    if(TheEchoesIgnoreErrorParsing == nil) then
        TheEchoesIgnoreErrorParsing = true; -- give an initial value
    end
    local ignoreErrorParsing = self.IgnoreErrorParsing;
    ignoreErrorParsing:GetCheckedTexture():SetDesaturated(true);
    ignoreErrorParsing:SetChecked(TheEchoesIgnoreErrorParsing);
    ignoreErrorParsing:SetScript("OnClick", function()
        TheEchoesIgnoreErrorParsing = ignoreErrorParsing:GetChecked();
        Addon.Controller.RefreshUI();
    end);

    -- group members first
    if(TheEchoesGroupMembersFirst == nil) then
        TheEchoesGroupMembersFirst = true; -- initial value
    end
    local groupMembersFirst = self.GroupMembersFirst;
    groupMembersFirst:GetCheckedTexture():SetDesaturated(true);
    groupMembersFirst:SetChecked(TheEchoesGroupMembersFirst);
    groupMembersFirst:SetScript("OnClick", function()
        TheEchoesGroupMembersFirst = groupMembersFirst:GetChecked();
        Addon.Controller.RefreshUI();
    end);

end

------- GUILD MESSAGE -------
TheEchoesGuildMessageMixin = {};
function TheEchoesGuildMessageMixin:Init()

    -- references
    local input = self.Input
    local saveButton = self.SaveButton

    -- on show
    self:SetScript("OnShow", function()
        -- set the guild info
        input:SetText(GetGuildRosterMOTD());
    end);

    -- clear the text on hide
    self:SetScript("OnHide", function()
        input:SetText("");
    end);

    -- hide the frame on close button
    self.CloseButton:SetScript("OnClick", function()
        self:Hide();
    end);

    -- esc key
    input:SetScript("OnKeyDown", function(_, key)
        if key == "ENTER" then
            saveButton:Click();
        elseif key == "ESCAPE" then
            self:Hide();
        end
    end)

    -- save button click
    saveButton:SetScript("OnClick", function()
        -- set the guild info
        GuildSetMOTD(input:GetText());
        self:Hide();
    end);

end

--- EDIT MEMBER ---
TheEchoesEditMemberMixin = {}
function TheEchoesEditMemberMixin:OnLoad()

    self.CloseButton:SetScript("OnClick", function() self:Hide()  end)

    local formFrame = self.FormFrame
    local typeMainsFrame = self.TypeMainsFrame

    -- key event in name
    self.Name:SetScript("OnKeyDown", function(_, key)
        if key == "ENTER" then
            self.SaveButton:Click()
        elseif key == "TAB" then
            formFrame.TankInput:SetFocus()
        elseif key == "ESCAPE" then
            self:Hide() -- hide at esc
        end
    end)

    -- implement ENTER, TAB and ESCAPE for the all 3 inputs
    formFrame.TankInput:SetScript("OnKeyDown", function(_, key)
        if key == "ENTER" then
            self.SaveButton:Click()
        elseif key == "TAB" then
            if IsShiftKeyDown() then
                formFrame.DPSInput:SetFocus()
            else
                formFrame.HealInput:SetFocus()
            end
        elseif key == "ESCAPE" then
            self:Hide() -- hide at esc
        end
    end)
    formFrame.HealInput:SetScript("OnKeyDown", function(_, key)
        if key == "ENTER" then
            self.SaveButton:Click()
        elseif key == "TAB" then
            if IsShiftKeyDown() then
                formFrame.TankInput:SetFocus()
            else
                formFrame.DPSInput:SetFocus()
            end
        elseif key == "ESCAPE" then
            self:Hide() -- hide at esc
        end
    end)
    formFrame.DPSInput:SetScript("OnKeyDown", function(_, key)
        if key == "ENTER" then
            self.SaveButton:Click()
        elseif key == "TAB" then
            if IsShiftKeyDown() then
                formFrame.HealInput:SetFocus()
            else
                formFrame.TankInput:SetFocus()
            end
        elseif key == "ESCAPE" then
            self:Hide() -- hide at esc
        end
    end)

    -- references
    local typeDDButton = typeMainsFrame.TypeButton
    local mainsDDButton = typeMainsFrame.MainsButton

    -- type button
    typeDDButton.getData = function() return {"Main", "Alt"} end
    typeDDButton.callBack = function()
        if typeDDButton:GetText() == "Main" then
            mainsDDButton:SetEnable(false)
            mainsDDButton:SetText("")
        else
            mainsDDButton:SetEnable(true)
        end
    end

    -- main button
    mainsDDButton:SetAnchorSide("RIGHT");
    mainsDDButton:SetXOffSet(-5);
    mainsDDButton.getData = function()
        return Addon.GuildData.GetMainNames(); -- give a list with the names of all mains.
    end

    -- set the save button
    self.SaveButton:SetScript("OnClick", function()
        local memberIndex = Addon.Utils.GetMemberIndex(self.Name:GetText())
        Addon.Utils.UpdateMemberILVL(memberIndex, formFrame.TankInput:GetText(), formFrame.HealInput:GetText(), formFrame.DPSInput:GetText())
        Addon.Utils.UpdateMemberType(memberIndex, typeDDButton:GetText(), mainsDDButton:GetText())
        self:Hide()
    end)

    self:Hide()

end
function TheEchoesEditMemberMixin:OnHide()
    self:Clear();
end
function TheEchoesEditMemberMixin:Clear()

    local formFrame = self.FormFrame;
    local typeMainsFrame = self.TypeMainsFrame;

    self.OnlineStatus:SetText("");
    self.CharInfo:SetText("");
    self.Rank:SetText("");
    self.Name:SetText("");
    formFrame.TankInput:SetText("");
    formFrame.HealInput:SetText("");
    formFrame.DPSInput:SetText("");
    typeMainsFrame.TypeButton:SetText("");
    typeMainsFrame.MainsButton:SetText("");
    Addon.DropDownMenu.Hide();

end
function TheEchoesEditMemberMixin:Open(memberData)

    -- clear the texts (in case it's already open)
    self:Clear();

    local formFrame = self.FormFrame

    -- isOnline
    local onlineStatusFontString = self.OnlineStatus
    if(memberData.isOnline) then
        onlineStatusFontString:SetText("Online")
        onlineStatusFontString:SetTextColor(0.4, 1, 0.4, 1)
    else
        onlineStatusFontString:SetText("Offline - " .. memberData.lastSeen)
        onlineStatusFontString:SetTextColor(1, 0.4, 0.4, 1)
    end

    -- char info
    self.CharInfo:SetText(Addon.Utils.GetClassName(memberData.class) .. " - " .. memberData.level)

    -- rank
    self.Rank:SetText(memberData.rankIndex .. ". " .. memberData.rank)

    -- name
    self.Name:SetText(memberData.name)

    -- ilvl
    if(memberData.errorRoles == nil) then

        -- references
        local roles = memberData.roles;
        local tank = roles.tank;
        local heal = roles.heal;
        local dps = roles.dps;

        if(tank ~= nil) then formFrame.TankInput:SetText(tank) end
        if(heal ~= nil) then formFrame.HealInput:SetText(heal) end
        if(dps ~= nil) then formFrame.DPSInput:SetText(dps) end

    end
    if(CanEditPublicNote()) then
        formFrame.TankInput:Enable();
        formFrame.HealInput:Enable();
        formFrame.DPSInput:Enable();
    else
        formFrame.TankInput:Disable();
        formFrame.HealInput:Disable();
        formFrame.DPSInput:Disable();
    end

    -- references
    local typeMainsFrame = self.TypeMainsFrame;
    local typeButton = typeMainsFrame.TypeButton;
    local mainsButton = typeMainsFrame.MainsButton;

    -- type & mains
    if(memberData.errorType == nil and memberData.errorMain == nil) then
        -- if the data has no main value, it means is main
        local type = memberData.main == nil and "Main" or "Alt"
        typeButton:SetText(type); -- set the type
        if(type == "Alt") then
            mainsButton:SetText(memberData.main) -- set the main
        end
    end
    if(CanEditOfficerNote()) then
        typeButton:SetEnable(true)
        if(typeButton:GetText() == "Alt") then
            mainsButton:SetEnable(true)
        else
            mainsButton:SetEnable(false)
        end
    else
        typeButton:SetEnable(false)
        mainsButton:SetEnable(false)
    end

    -- pubic note
    local publicNote = memberData.publicNote;
    if publicNote == "" then
        publicNote = "-"
    end
    self.Notes.Note:SetText(publicNote)

    -- officer note
    local officerNote = memberData.officerNote;
    if officerNote == "" then
        officerNote = "-"
    end
    self.Notes.OfficerNote:SetText(officerNote)

    self:Show()

end

--- PERSONAL NOTE ---
TheEchoesPersonalNoteFrameMixin = {}
function TheEchoesPersonalNoteFrameMixin:OnLoad()

    -- references
    local input = self.Body:GetScrollChild();
    local saveButton = self.SaveButton;

    -- position the scroll bar of body
    Addon.Utils.PositionScrollBar(self.Body)

    -- clear the text on hide
    self:SetScript("OnHide", function()
        input:SetText("");
    end);

    -- hide the frame on close button
    self.CloseButton:SetScript("OnClick", function()
        self:Hide();
    end);

    -- limit the characters
    input:SetMaxLetters(500);

    -- esc key
    input:SetScript("OnKeyDown", function(_, key)
        if(key == "ESCAPE")then
            self:Hide();
        end
    end);

    -- save button click
    saveButton:SetScript("OnClick", function()
        -- set the note
        local note = input:GetText();
        if(note == "") then
            note = nil;
        end
        TheEchoesPersonalNotes[self.CharName:GetText()] = note;
        self:Hide();
    end);

end
function TheEchoesPersonalNoteFrameMixin:Open(memberName)

    -- set the title
    self.CharName:SetText(memberName);

    -- set the note
    local input = self.Body:GetScrollChild();
    input:SetText(TheEchoesPersonalNoteFrameMixin[memberName] or "");

    -- show
    self:Show();

end

--- ERROR FRAME ---
TheEchoesErrorFrameMixin = {}
function TheEchoesErrorFrameMixin:Init()
    Addon.Utils.PositionScrollBar(self.Body);
end
function TheEchoesErrorFrameMixin:SetErrorMembers(errorMembers)

    local errorContent = self.Body.Content;

    -- clear the content
    for _, childFrame in ipairs({errorContent:GetChildren()}) do
        childFrame:SetParent(nil)
        childFrame:ClearAllPoints()
        childFrame:SetScript("OnClick", nil)
        childFrame:Hide()
    end

    -- check array size
    if Addon.Utils.ArraySize(errorMembers) == 0 then
        self:Hide();
        return;
    end

    -- sort by name
    table.sort(errorMembers, Addon.Utils.CompareByName);

    -- add the members
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
        if(member.isOnline) then
            button.Text:SetTextColor(0.2, 0.9, 0.2);
        end

        -- keep the most widest button.
        local width = button:GetWidth();
        if(width > maxWidth) then
            maxWidth = width;
        end

        -- open edit
        button:SetScript("OnClick", function()
            TheEchoesUI.EditMemberFrame:Open(member);
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

    -- calculate the max width
    maxWidth = maxWidth + 10 + 19; -- left(5) + right(5) + space+bar(3+16).
    self:SetSize(maxWidth, totalHeight);

    self:Show()

end

-- EXPORT DATA --
TheEchoesExportButtonMixin = {}
function TheEchoesExportButtonMixin.Export()
    TheEchoesExportData = Addon.GuildData.GetData();
    ReloadUI();
end