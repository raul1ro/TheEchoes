local _, Addon = ...;

-- Bindings.xml globals
BINDING_HEADER_THE_ECHOES_UI = "User Interface"
BINDING_NAME_THE_ECHOES_TOGGLE = "Toggle Open/Close"

-- constants
local TheEchoesButton

local function getData()

    local guildData = Addon.Utils.getGuildData() -- membersData, errorMembers, onlineSize, totalSize

    local membersData = Addon.Utils.sortMembers(guildData.membersData, false)
    local totalSize = guildData.totalSize
    local onlineSize = guildData.onlineSize
    local mainSize = Addon.Utils.size(membersData)
    local altSize = totalSize - mainSize

    return { membersData, totalSize, onlineSize, mainSize, altSize, guildData.tankSize, guildData.healSize, guildData.dpsSize, guildData.errorMembers }

end

local function init()

    -- Create square button
    TheEchoesButton = CreateFrame("Button", "TheEchoesButton", UIParent)
    TheEchoesButton:SetSize(32, 32)
    if TheEchoesButtonPosition == nil then
        TheEchoesButtonPosition = {"CENTER", nil, "CENTER", 0, 0}
    end
    TheEchoesButton:SetPoint(unpack(TheEchoesButtonPosition))
    TheEchoesButton:Hide()

    -- Set the background
    TheEchoesButton:SetNormalTexture("Interface\\AddOns\\TheEchoes\\images\\logo_circle_32.tga");
    TheEchoesButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1);
    TheEchoesButton:GetNormalTexture():SetBlendMode("BLEND");

    -- Add Border
    local border = TheEchoesButton:CreateTexture(nil, "BACKGROUND");
    border:SetTexture("Interface\\AddOns\\TheEchoes\\images\\circle.tga"); -- Example border texture, change to your own
    border:SetSize(34, 34); -- Adjust size to make it slightly bigger than the button
    border:SetPoint("CENTER", TheEchoesButton, "CENTER");
    border:SetVertexColor(0.6, 0.6, 0.6); -- Set border color, (1, 1, 1) for white

    -- Add Shadow
    local shadow = TheEchoesButton:CreateTexture(nil, "BACKGROUND");
    shadow:SetTexture("Interface\\AddOns\\TheEchoes\\images\\circle.tga"); -- Replace with your shadow texture if needed
    shadow:SetSize(36, 36); -- Shadow should be a little larger than the button
    shadow:SetPoint("CENTER", TheEchoesButton, "CENTER", 0, -1); -- Slight offset for shadow effect
    shadow:SetVertexColor(0, 0, 0, 0.3); -- Black shadow with 50% transparency

    -- Make the button movable
    TheEchoesButton:SetMovable(true)
    TheEchoesButton:EnableMouse(true)
    TheEchoesButton:RegisterForDrag("LeftButton")
    TheEchoesButton:SetScript("OnDragStart", TheEchoesButton.StartMoving)
    TheEchoesButton:SetScript("OnDragStop", function()
        TheEchoesButton:StopMovingOrSizing()
        --save the position
        TheEchoesButtonPosition = {TheEchoesButton:GetPoint(0)}
    end)

    -- Visual effect on click down
    TheEchoesButton:SetScript("OnMouseDown", function(self)
        self:GetNormalTexture():SetVertexColor(0.7, 0.7, 0.7)
    end)
    TheEchoesButton:SetScript("OnMouseUp", function(self)
        self:GetNormalTexture():SetVertexColor(1, 1, 1)
    end)
    TheEchoesButton:SetScript("OnLeave", function(self)
        self:GetNormalTexture():SetVertexColor(1, 1, 1)
    end)

end

-- guild event listener
TheEchoes = {
    PlayerName = UnitName("player"),
    getGuildData = getData,
    init = false;
}

-- call inits only after load
local addonLoadedFrame = CreateFrame("FRAME")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(_, event , ...)

    if (event == "ADDON_LOADED") and (... == "TheEchoes") then

        -- init the ui, only after got guild info
        local function initUI(tries)

            if(IsInGuild()) then

                if(CanViewOfficerNote()) then

                    init(); -- init the main part

                    -- init ui
                    TheEchoesUI.init();

                    -- set flag
                    TheEchoes.init = true;

                    -- show the E button
                    TheEchoesButton:Show()
                    TheEchoesButton:SetScript("OnClick", function(_, button)
                        if button == "LeftButton" then
                            TheEchoesUI.toggle()
                        end
                    end)
                    print("|cff00bfffTheEchoes init.|r")
                else
                    print("|cffff0000TheEchoes require view access to officer notes.|r")
                end

                return

            end

            if tries > 0 then
                C_Timer.After(1, function()
                    initUI(tries - 1)
                end)
            else
                print("|cffff0000TheEchoes failed to init. Type `/reload ui` to retry.|r")
            end

        end
        initUI(60)

    end

end)