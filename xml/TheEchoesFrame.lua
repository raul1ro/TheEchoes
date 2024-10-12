local _, Addon = ...;

function InitTheEchoesFrame()

    -- Frame
    if TheEchoesUIPosition == nil then
        TheEchoesUIPosition = {"CENTER", nil, "CENTER", 0, 0}
    end
    TheEchoesFrame:SetPoint(unpack(TheEchoesUIPosition))
    TheEchoesFrame.CloseButton:SetScript("OnClick", function() TheEchoesUI.close() end)
    TheEchoesFrame:SetMovable(true)
    TheEchoesFrame:RegisterForDrag("LeftButton")
    TheEchoesFrame:SetScript("OnDragStart", TheEchoesFrame.StartMoving)
    TheEchoesFrame:SetScript("OnDragStop", function()
        TheEchoesFrame:StopMovingOrSizing()
        --save the position
        TheEchoesUIPosition = {TheEchoesFrame:GetPoint(0)}
    end)
    TheEchoesFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            TheEchoesUI.close();
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    TheEchoesFrame:SetScript("OnHide", function()
        TheEchoesFrame.EditGMFrame:Hide()
        TheEchoesFrame.EditMemberFrame:Hide()
    end)

    -- Search
    TheEchoesFrame.SearchInput:SetScript("OnKeyUp", function(self, key)
        if key == "ESCAPE" then
            self:ClearFocus()
        end
    end)
    TheEchoesFrame.SearchInput:SetScript("OnTextChanged", function(self)
        if(self:GetText() ~= "") then
            self.ClearButton:Show()
        else
            self.ClearButton:Hide()
        end
        TheEchoesUI.refreshUI()
    end)


    -- Hide Off Alts
    local hideOffAlts = TheEchoesFrame.HideOffAltsCheckButton
    hideOffAlts:GetCheckedTexture():SetDesaturated(true)
    hideOffAlts:SetScript("OnClick", function()
        TheEchoesUI.refreshUI()
    end)

    -- Guild Info
    local guildInfoFrame = TheEchoesFrame.GuildInfoFrame
    local guildInfoInput = guildInfoFrame.ScrollFrame:GetScrollChild()
    local guildInfoSaveButton = guildInfoFrame.SaveButton
    Addon.Utils.positionScrollBar(guildInfoFrame.ScrollFrame)
    TheEchoesFrame.GuildInfoButton:SetScript("OnClick", function()
        if(guildInfoFrame:IsVisible()) then
            guildInfoFrame:Hide()
        else
            guildInfoInput:SetText(GetGuildInfoText())
            if(CanEditGuildInfo())then
                guildInfoSaveButton:SetEnable(true)
            else
                guildInfoSaveButton:SetEnable(false)
            end
            guildInfoFrame:Show()
        end
    end)
    guildInfoFrame:SetScript("OnHide", function()
        guildInfoInput:SetText("")
    end)
    guildInfoFrame.CloseButton:SetScript("OnClick", function()
        guildInfoFrame:Hide()
    end)
    guildInfoInput:SetScript("OnKeyDown", function(_, key)
        if(key == "ESCAPE")then
            guildInfoFrame:Hide()
        end
    end)
    guildInfoSaveButton:SetScript("OnClick", function()
        SetGuildInfoText(guildInfoInput:GetText())
        guildInfoFrame:Hide()
    end)

    -- get references
    local editGMButton = TheEchoesFrame.EditGMButton
    local exportDataButton = TheEchoesFrame.ExportDataButton;

    -- Invite member
    if(CanGuildInvite()) then
        TheEchoesFrame.InviteMemberButton:Show()
    else
        -- reposition the button after
        TheEchoesFrame.InviteMemberButton:SetWidth(1)
        local point, relativeTo, relativePoint, _, yOfs = editGMButton:GetPoint(1)
        editGMButton:ClearAllPoints()
        editGMButton:SetPoint(point, relativeTo, relativePoint, 0, yOfs)
    end

    -- Edit GM
    if(CanEditMOTD()) then

        local editGMFrame = TheEchoesFrame.EditGMFrame
        local editGMInput = editGMFrame.EditGMInput
        local editGMSave = editGMFrame.EditGMSave

        -- set the button
        editGMButton:Show()
        editGMButton:SetScript("OnClick", function()
            if(editGMFrame:IsVisible()) then
                editGMFrame:Hide()
            else
                editGMFrame:Show()
            end
        end)

        -- frame
        editGMFrame:SetScript("OnShow", function()
            editGMInput:SetText(GetGuildRosterMOTD())
        end)
        editGMFrame:SetScript("OnHide", function()
            editGMInput:SetText("")
        end)
        editGMFrame.CloseButton:SetScript("OnClick", function()
            editGMFrame:Hide()
        end)

        -- input
        editGMInput:SetScript("OnKeyDown", function(_, key)
            if key == "ENTER" then
                editGMSave:Click()
            elseif key == "ESCAPE" then
                editGMFrame:Hide() -- hide at esc
            end
        end)

        -- save button
        editGMSave:SetScript("OnClick", function()
            GuildSetMOTD(editGMInput:GetText())
            editGMFrame:Hide()
        end)

    else
        -- reposition the button after
        editGMButton:SetWidth(1)
        local point, relativeTo, relativePoint, _, yOfs = exportDataButton:GetPoint(1)
        exportDataButton:ClearAllPoints()
        exportDataButton:SetPoint(point, relativeTo, relativePoint, 0, yOfs)
    end

    -- export
    local exportDataFrame = TheEchoesFrame.ExportDataFrame;
    local exportDataInput = exportDataFrame.ScrollFrame:GetScrollChild()
    Addon.Utils.positionScrollBar(exportDataFrame.ScrollFrame)
    exportDataButton:SetScript("OnClick", function()
        if(exportDataFrame:IsVisible()) then
            exportDataFrame:Hide()
        else
            exportDataInput:SetText(Addon.Utils.exportData())
            exportDataInput:SetCursorPosition(0)
            exportDataInput:HighlightText()
            exportDataFrame:Show()
        end
    end)
    exportDataFrame.CloseButton:SetScript("OnClick", function()
        exportDataFrame:Hide()
    end)
    exportDataInput:SetScript("OnKeyDown", function(_, key)
        if(key == "ESCAPE") then exportDataFrame:Hide() end
    end)
    exportDataFrame:SetScript("OnHide", function()
        exportDataInput:SetText("")
    end)

    -- init the dropdownmenu
    InitTheEchoesDropDownMenu()

    -- reposition the scrollbar
    Addon.Utils.positionScrollBar(TheEchoesFrame.ScrollFrame)


end

-- EDIT FRAME --
TheEchoesEditMemberFrameMixin = {}

function TheEchoesEditMemberFrameMixin:OnLoad()

    self.CloseButton:SetScript("OnClick", function() self:Hide()  end)

    local formFrame = self.FormFrame
    local typeMainsFrame = self.TypeMainsFrame

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

    -- set dropdownmenu buttons from edit member
    local typeDDButton = typeMainsFrame.TypeButton
    local mainsDDButton = typeMainsFrame.MainsButton
    typeDDButton.getData = function() return {"Main", "Alt"} end
    typeDDButton.callBack = function()
        if typeDDButton:GetText() == "Main" then
            mainsDDButton:SetEnable(false)
            mainsDDButton:SetText("")
        else
            mainsDDButton:SetEnable(true)
        end
    end
    mainsDDButton.getData = function()

        local mainMembers = {}
        for _, v in ipairs(TheEchoesUI.GuildData[1]) do
            table.insert(mainMembers, v.name)
        end

        table.sort(mainMembers)

        return mainMembers

    end

    -- set the save button
    local editMemberSaveButton = self.SaveButton
    editMemberSaveButton:SetScript("OnClick", function()
        local memberIndex = Addon.Utils.getMemberIndex(self.Name:GetText())
        Addon.Utils.updateMemberILVL(memberIndex, formFrame.TankInput:GetText(), formFrame.HealInput:GetText(), formFrame.DPSInput:GetText())
        Addon.Utils.updateMemberType(memberIndex, typeDDButton:GetText(), mainsDDButton:GetText())
        self:Hide()
    end)

    self:Hide()

end

function TheEchoesEditMemberFrameMixin:Open(name, isOnline, lastSeen, class, level, rank, rankIndex, tankValue, healValue, dpsValue, type, main, isNotes, note, officerNote)

    self:Hide()

    local formFrame = self.FormFrame
    local typeMainsFrame = self.TypeMainsFrame;

    -- isOnline
    local onlineStatusFontString = self.OnlineStatus
    if(isOnline) then
        onlineStatusFontString:SetText("Online")
        onlineStatusFontString:SetTextColor(0.4, 1, 0.4, 1)
    else
        onlineStatusFontString:SetText("Offline - " .. lastSeen)
        onlineStatusFontString:SetTextColor(1, 0.4, 0.4, 1)
    end

    -- char info
    self.CharInfo:SetText(Addon.Utils.getClassName(class) .. " - " .. level)

    -- rank
    self.Rank:SetText(rankIndex .. ". " .. rank)

    -- name
    self.Name:SetText(name)

    -- values
    if(tankValue ~= nil) then formFrame.TankInput:SetText(tankValue) end
    if(healValue ~= nil) then formFrame.HealInput:SetText(healValue) end
    if(dpsValue ~= nil) then formFrame.DPSInput:SetText(dpsValue) end
    if(CanEditPublicNote()) then
        formFrame.TankInput:Enable();
        formFrame.HealInput:Enable();
        formFrame.DPSInput:Enable();
    else
        formFrame.TankInput:Disable();
        formFrame.HealInput:Disable();
        formFrame.DPSInput:Disable();
    end

    -- type
    typeMainsFrame.TypeButton:SetText(type)
    if(CanEditOfficerNote()) then
        typeMainsFrame.TypeButton:SetEnable(true)
        if(type == "Alt") then
            typeMainsFrame.MainsButton:SetText(main)
            typeMainsFrame.MainsButton:SetEnable(true)
        else
            typeMainsFrame.MainsButton:SetEnable(false)
        end
    else
        typeMainsFrame.TypeButton:SetEnable(false)
        typeMainsFrame.MainsButton:SetEnable(false)
    end

    -- notes
    if(isNotes == true) then
        if note == nil or note == "" then
            note = "-"
        end
        self.Notes.Note:SetText(note)
        if officerNote == nil or note == "" then
            officerNote = "-"
        end
        self.Notes.OfficerNote:SetText(officerNote)
        self.Notes:Show()
    else
        self.Notes:Hide()
    end

    self:Show()

end

function TheEchoesEditMemberFrameMixin:OnHide()

    local formFrame = self.FormFrame
    local typeMainsFrame = self.TypeMainsFrame

    self.index = nil
    self.OnlineStatus:SetText("")
    self.Rank:SetText("")
    self.Name:SetText("")
    formFrame.TankInput:SetText("")
    formFrame.HealInput:SetText("")
    formFrame.DPSInput:SetText("")
    typeMainsFrame.TypeButton:SetText("")
    typeMainsFrame.MainsButton:SetText("")
    TheEchoesDropDownMenu:Hide()

end