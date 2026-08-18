local _, Addon = ...;

local DropDownMenu = {}
Addon.DropDownMenu = DropDownMenu;

-- have a pool of elements which are listed in drop down menu
DropDownMenu.ElementPool = nil;

function DropDownMenu.Init()

    -- create the pool
    DropDownMenu.ElementPool = CreateFramePool("FRAME", TheEchoesDropDownMenu.Body.Content, "TheEchoesDropDownMenuElement", function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame.text:SetText("")
        frame.background:SetColorTexture(0, 0, 0, 0)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
    end)

    -- get the scroll bar
    local DDMenuScrollBar = TheEchoesDropDownMenu.Body.ScrollBar

    -- dropdownmenu - onhide -> release elements and set scroll top
    TheEchoesDropDownMenu:SetScript("OnHide", function()
        DropDownMenu.ElementPool:ReleaseAll()
        DDMenuScrollBar:SetValue(0)
    end)

    -- set the scroll step
    TheEchoesDropDownMenu.Body.Content:SetScript("OnMouseWheel", function(_, delta)
        DDMenuScrollBar:SetValue(DDMenuScrollBar:GetValue() - (delta * 18)) -- the step
    end)

    -- reposition the scrollbar
    Addon.Utils.PositionScrollBar(TheEchoesDropDownMenu.Body);

end

function DropDownMenu.Hide()
    TheEchoesDropDownMenu:Hide();
end

function DropDownMenu.GetElement()
    return DropDownMenu.ElementPool:Acquire()
end