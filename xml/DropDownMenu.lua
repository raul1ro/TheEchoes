local _, Addon = ...;

Addon.DropDownMenuElementPool = nil;

function InitTheEchoesDropDownMenu()

    -- create the pool
    Addon.DropDownMenuElementPool = CreateFramePool("FRAME", TheEchoesDropDownMenu.ScrollFrame.Content, "TheEchoesDropDownMenuElement", function(_, frame)
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
        Addon.DropDownMenuElementPool:ReleaseAll()
        DDMenuScrollBar:SetValue(0)
    end)

    -- set the scroll step
    TheEchoesDropDownMenu.ScrollFrame.Content:SetScript("OnMouseWheel", function(_, delta)
        DDMenuScrollBar:SetValue(DDMenuScrollBar:GetValue() - (delta * 27)) -- the step
    end)

    -- reposition the scrollbar
    Addon.Utils.positionScrollBar(TheEchoesDropDownMenu.ScrollFrame)

end