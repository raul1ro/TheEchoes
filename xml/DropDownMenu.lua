DropDownMenuElementPool = nil;
function InitTheEchoesDropDownMenu()

    -- create the pool
    DropDownMenuElementPool = CreateFramePool("FRAME", TheEchoesDropDownMenu.ScrollFrame.Content, "TheEchoesDropDownMenuElement", function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame.text:SetText("")
        frame.background:SetColorTexture(0, 0, 0, 0)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
    end)

    -- get the scroll bar
    local DDMenuScrollBar = TheEchoesDropDownMenu.ScrollFrame.ScrollBar

    -- dropdownmenu - onhide -> release elements and set scroll top
    TheEchoesDropDownMenu:SetScript("OnHide", function()
        DropDownMenuElementPool:ReleaseAll()
        DDMenuScrollBar:SetValue(0)
    end)

    -- set the scroll step
    TheEchoesDropDownMenu.ScrollFrame.Content:SetScript("OnMouseWheel", function(_, delta)
        DDMenuScrollBar:SetValue(DDMenuScrollBar:GetValue() - (delta * 25)) -- the step
    end)

end