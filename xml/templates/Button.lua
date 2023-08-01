TheEchoesButtonMixin = {}
TheEchoesButtonMixin.enable = true

function TheEchoesButtonMixin:Size(width, height)
    self:SetSize(width, height)
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
    self:GetFontString():SetWidth(width*0.9)
end

function TheEchoesButtonMixin:OnMouseDown()
    if(self.enable) then
        self.LeftBackground:Hide()
        self.RightBackground:Hide()
        self.MiddleBackground:Hide()
        self.LeftPressBackground:Show()
        self.RightPressBackground:Show()
        self.MiddlePressBackground:Show()
    end
end

function TheEchoesButtonMixin:OnMouseUp()
    if(self.enable) then
        self.LeftBackground:Show()
        self.RightBackground:Show()
        self.MiddleBackground:Show()
        self.LeftPressBackground:Hide()
        self.RightPressBackground:Hide()
        self.MiddlePressBackground:Hide()
    end
end

function TheEchoesButtonMixin:SetEnable(enable)
    if(enable) then
        self.enable = true
        self:Enable()
        self.LeftBackground:Show()
        self.RightBackground:Show()
        self.MiddleBackground:Show()
        self.LeftDisableBackground:Hide()
        self.RightDisableBackground:Hide()
        self.MiddleDisableBackground:Hide()
    else
        self.enable = false
        self:Disable()
        self.LeftBackground:Hide()
        self.RightBackground:Hide()
        self.MiddleBackground:Hide()
        self.LeftDisableBackground:Show()
        self.RightDisableBackground:Show()
        self.MiddleDisableBackground:Show()
    end
end