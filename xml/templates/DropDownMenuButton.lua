local _, Addon = ...;

TheEchoesDropDownMenuButtonMixin = {}
TheEchoesDropDownMenuButtonMixin.enable = true

-- need implementation after the creation of the button. this function is used to get the data for population of dropdownmenu
TheEchoesDropDownMenuButtonMixin.getData = nil
TheEchoesDropDownMenuButtonMixin.callBack = nil

function TheEchoesDropDownMenuButtonMixin:OnLoad()

    local width = self:GetWidth()
    local height = self:GetHeight()

    local textureWidth = math.floor((height*128) / 114) --default size of texture is w114 h128
    self:GetHighlightTexture():SetSize(width, height)
    self.LeftBackground:SetSize(textureWidth, height)
    self.RightBackground:SetSize(textureWidth, height)
    self.MiddleBackground:SetHeight(height)
    self.LeftPressBackground:SetSize(textureWidth, height)
    self.RightPressBackground:SetSize(textureWidth, height)
    self.MiddlePressBackground:SetHeight(height)
    self.LeftDisableBackground:SetSize(textureWidth, height)
    self.RightDisableBackground:SetSize(textureWidth, height)
    self.MiddleDisableBackground:SetHeight(height)
    self:GetFontString():SetWidth(width - 30)

end

function TheEchoesDropDownMenuButtonMixin:OnMouseDown()
    if(self.enable) then
        self.LeftBackground:Hide()
        self.RightBackground:Hide()
        self.MiddleBackground:Hide()
        self.Arrow:Hide()
        self.LeftPressBackground:Show()
        self.RightPressBackground:Show()
        self.MiddlePressBackground:Show()
        self.ArrowPress:Show()
    end
end

function TheEchoesDropDownMenuButtonMixin:OnMouseUp()
    if(self.enable) then
        self.LeftBackground:Show()
        self.RightBackground:Show()
        self.MiddleBackground:Show()
        self.Arrow:Show()
        self.LeftPressBackground:Hide()
        self.RightPressBackground:Hide()
        self.MiddlePressBackground:Hide()
        self.ArrowPress:Hide()
    end
end

function TheEchoesDropDownMenuButtonMixin:SetEnable(enable)
    if(enable) then
        self.enable = true
        self:Enable()
        self.LeftBackground:Show()
        self.RightBackground:Show()
        self.MiddleBackground:Show()
        self.Arrow:Show()
        self.LeftDisableBackground:Hide()
        self.RightDisableBackground:Hide()
        self.MiddleDisableBackground:Hide()
        self.ArrowDisable:Hide()
    else
        self.enable = false
        self:Disable()
        self.LeftBackground:Hide()
        self.RightBackground:Hide()
        self.MiddleBackground:Hide()
        self.Arrow:Hide()
        self.LeftDisableBackground:Show()
        self.RightDisableBackground:Show()
        self.MiddleDisableBackground:Show()
        self.ArrowDisable:Show()
    end
end

function TheEchoesDropDownMenuButtonMixin:OnClick()

    -- get the ddmenu
    local ddMenu = TheEchoesDropDownMenu


    -- if the menu is visible and the parent is self -> only hide the menu
    if(ddMenu:IsVisible() and ddMenu:GetParent() == self) then
        ddMenu:Hide()
        return
    end

    -- hide to clear the content
    ddMenu:Hide()

    -- set the position and sizes
    ddMenu:SetParent(self)
    ddMenu:ClearAllPoints()
    ddMenu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 7, -6)

    -- get data
    local data = self.getData();

    -- get infos for sizing
    local dataSize = Addon.Utils.size(data)
    local maxWidth = Addon.Utils.getMaxWidth(data)

    -- calculate the sizes
    local contentHeight = 82; -- minimum
    local contentWidth = maxWidth + 10;
    if dataSize >= 25 then
        contentHeight = 460
    elseif dataSize > 4 then
        contentHeight = (dataSize * 18) + 10
    end
    if contentWidth < 85 then
        contentWidth = 85 -- minimum
    end

    -- set the sizes
    ddMenu:SetSize(contentWidth + 5, contentHeight + 5)
    ddMenu.ScrollFrame.Content:SetSize(contentWidth, contentHeight)

    -- populate ddmenu
    for i, v in ipairs(self.getData()) do

        -- calculate the current y position
        local currentY = -((i-1)*18)

        -- get the frame and set it
        local menuElement = Addon.DropDownMenuElementPool:Acquire()
        menuElement:SetWidth(contentWidth)
        menuElement:SetPoint("TOPLEFT", 2, currentY)
        menuElement.text:SetText(v)
        menuElement:Show()

        -- background style
        if self:GetText() == v then -- selected element
            menuElement.background:SetColorTexture(0, 0.5, 1, 0.2)
            menuElement:SetScript("OnEnter", nil)
            menuElement:SetScript("OnLeave", nil)
        else -- else apply hover effect
            menuElement.background:SetColorTexture(0, 0, 0, 0) -- default background
            menuElement:SetScript("OnEnter", function() -- on mouse enter
                menuElement.background:SetColorTexture(0.4, 0.4, 0.4, 0.2) -- white
            end)
            menuElement:SetScript("OnLeave", function() -- on mouse leave
                menuElement.background:SetColorTexture(0, 0, 0, 0) -- go to default
            end)
        end

        -- on click -> hide menu, set text and callback
        menuElement:SetScript("OnMouseDown", function(_, mouseButton)
            if mouseButton == "LeftButton" then

                ddMenu:Hide()
                self:SetText(v)
                if self.callBack ~= nil then self.callBack() end

            end
        end)

    end

    -- show the menu
    ddMenu:Show()

end
