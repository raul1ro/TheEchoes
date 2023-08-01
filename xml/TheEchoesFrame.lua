function InitTheEchoesFrame()

    -- Frame
    if UIPoint == nil then
        UIPoint = "CENTER"
        UIRelativeTo = nil
        UIRelativPoint = "CENTER"
        UIXOffset = 0
        UIYOffset = 0
    end
    TheEchoesFrame:SetPoint(UIPoint, UIRelativeTo, UIRelativPoint, UIXOffset, UIYOffset)
    TheEchoesFrame.CloseButton:SetScript("OnClick", function() TheEchoesUI.close() end)
    TheEchoesFrame:SetMovable(true)
    TheEchoesFrame:RegisterForDrag("LeftButton")
    TheEchoesFrame:SetScript("OnDragStart", TheEchoesFrame.StartMoving)
    TheEchoesFrame:SetScript("OnDragStop", function()
        TheEchoesFrame:StopMovingOrSizing()
        --save the position
        UIPoint, UIRelativeTo, UIRelativPoint, UIXOffset, UIYOffset = TheEchoesFrame:GetPoint(0);
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

    -- Hide Off Alts
    local hideOffAlts = TheEchoesFrame.HideOffAltsCheckButton
    hideOffAlts:GetCheckedTexture():SetDesaturated(true)
    hideOffAlts:SetScript("OnClick", function()
        TheEchoes.triggerUpdate()
    end)

    -- Invite member
    if(CanGuildInvite()) then
        local inviteMemberButton = TheEchoesFrame.InviteMemberButton
        inviteMemberButton:Size(120, 24)
        inviteMemberButton:Show()
    end

    -- Edit GM
    if(CanEditMOTD()) then

        local editGMButton = TheEchoesFrame.EditGMButton
        local editGMFrame = TheEchoesFrame.EditGMFrame
        local editGMInput = editGMFrame.EditGMInput
        local editGMSave = editGMFrame.EditGMSave

        -- set the button
        editGMButton:Size(150, 24)
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
        editGMSave:Size(75, 24)
        editGMSave:SetScript("OnClick", function()
            GuildSetMOTD(editGMInput:GetText())
            editGMFrame:Hide()
        end)

    end

    -- set dropdownmenu buttons from edit member
    local editMemberFrame = TheEchoesFrame.EditMemberFrame
    local typeDDButton = editMemberFrame.TypeButton
    local mainsDDButton = editMemberFrame.MainsButton
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
        for _, v in pairs({TheEchoesFrame.ScrollFrame.Content:GetChildren()}) do
            if v:IsVisible() and v.Type:GetText() == "Main" then
                table.insert(mainMembers, v.Name.Text:GetText())
            end
        end

        table.sort(mainMembers)

        return mainMembers

    end

    -- init the dropdownmenu
    InitTheEchoesDropDownMenu()

    -- set the save button
    local editMemberSaveButton = editMemberFrame.SaveButton
    editMemberSaveButton:Size(75, 24)
    editMemberSaveButton:SetScript("OnClick", function()
        local memberName = editMemberFrame.Title:GetText()
        updateMemberILVL(memberName, editMemberFrame.TankInput:GetText(), editMemberFrame.HealInput:GetText(), editMemberFrame.DPSInput:GetText())
        updateMemberType(memberName, editMemberFrame.TypeButton:GetText(), editMemberFrame.MainsButton:GetText())
        editMemberFrame:Hide()
    end)

end

-- EDIT FRAME --
EditMemberFrameMixin = {}

function EditMemberFrameMixin:OnLoad()

    self.Title:SetJustifyH("CENTER")
    self.CloseButton:SetScript("OnClick", function() self:Hide()  end)

    -- implement ENTER, TAB and ESCAPE for the all 3 inputs
    self.TankInput:SetScript("OnKeyDown", function(_, key)
        if key == "ENTER" then
            self.SaveButton:Click()
        elseif key == "TAB" then
            if IsShiftKeyDown() then
                self.DPSInput:SetFocus()
            else
                self.HealInput:SetFocus()
            end
        elseif key == "ESCAPE" then
            self:Hide() -- hide at esc
        end
    end)
    self.HealInput:SetScript("OnKeyDown", function(_, key)
        if key == "ENTER" then
            self.SaveButton:Click()
        elseif key == "TAB" then
            if IsShiftKeyDown() then
                self.TankInput:SetFocus()
            else
                self.DPSInput:SetFocus()
            end
        elseif key == "ESCAPE" then
            self:Hide() -- hide at esc
        end
    end)
    self.DPSInput:SetScript("OnKeyDown", function(_, key)
        if key == "ENTER" then
            self.SaveButton:Click()
        elseif key == "TAB" then
            if IsShiftKeyDown() then
                self.HealInput:SetFocus()
            else
                self.TankInput:SetFocus()
            end
        elseif key == "ESCAPE" then
            self:Hide() -- hide at esc
        end
    end)

    -- implement on show -> focus tank input and set mainsbutton
    self:SetScript("OnShow", function()

        if(self.TypeButton:GetText() == "Alt") then
            self.MainsButton:SetEnable(true)
        else
            self.MainsButton:SetEnable(false)
        end

    end)

    self:Hide()

end

function EditMemberFrameMixin:Open(title, tankValue, healValue, dpsValue, type, main, isNotes, note, officerNote)

    self:Hide()

    -- title
    self.Title:SetText(title)

    -- values
    if(tankValue ~= nil) then self.TankInput:SetText(tankValue) end
    if(healValue ~= nil) then self.HealInput:SetText(healValue) end
    if(dpsValue ~= nil) then self.DPSInput:SetText(dpsValue) end

    -- type
    self.TypeButton:SetText(type)
    if(type == "Alt") then self.MainsButton:SetText(main) end

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

function EditMemberFrameMixin:OnHide()
    self.Title:SetText("")
    self.TankInput:SetText("")
    self.HealInput:SetText("")
    self.DPSInput:SetText("")
    self.TypeButton:SetText("")
    self.MainsButton:SetText("")
    TheEchoesDropDownMenu:Hide()
end