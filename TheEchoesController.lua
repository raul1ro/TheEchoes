local _, Addon = ...;

local Controller = {}
Addon.Controller = Controller;

function Controller.Init()

    Controller.InitUI();

    Controller.InitButton();
    Addon.Button:Show();

    -- initialize the private notes
    TheEchoesPersonalNotes = TheEchoesPersonalNotes or {};

    -- clear export data - to prevent to hold unused memory.
    TheEchoesExportData = nil;

    return true;

end

function Controller.InitUI()
    TheEchoesUI:Init();
end

function Controller.InitButton()

    -- Create square button
    local button = CreateFrame("Button", "TheEchoesButton", UIParent)
    button:SetSize(24, 24);
    if TheEchoesButtonPosition == nil then
        TheEchoesButtonPosition = {"CENTER", nil, "CENTER", 0, 0};
    end
    button:SetPoint(unpack(TheEchoesButtonPosition));
    button:Hide();

    -- Set the background
    button:SetNormalTexture("Interface\\AddOns\\TheEchoes\\images\\logo_square_32_24.tga");
    button:GetNormalTexture():SetTexCoord(0, 0.75, 0, 0.75);
    button:GetNormalTexture():SetBlendMode("BLEND");

    -- Make the button movable
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", button.StartMoving)
    button:SetScript("OnDragStop", function()
        button:StopMovingOrSizing()
        --save the position
        TheEchoesButtonPosition = {button:GetPoint(0)}
    end)

    -- Visual effect on click down
    button:SetScript("OnMouseDown", function(self)
        self:GetNormalTexture():SetVertexColor(0.7, 0.7, 0.7);
    end)
    button:SetScript("OnMouseUp", function(self)
        self:GetNormalTexture():SetVertexColor(1, 1, 1);
    end)
    button:SetScript("OnLeave", function(self)
        self:GetNormalTexture():SetVertexColor(1, 1, 1);
    end)

    -- Toggle UI
    button:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            TheEchoesUI:Toggle();
        end
    end)

    Addon.Button = button;

end

function Controller.RefreshUI()

    -- don't execute this if the ui is not open.
    if(TheEchoesUI:IsOpen() == false) then
        return;
    end

    -- guild message
    TheEchoesUI:UpdateGuildMessage();

    -- members data
    local guildData = Addon.GuildData.GetData();
    local membersData = guildData.membersData;

    -- update info
    local onlineSize = guildData.membersOnlineSize;
    local totalSize = guildData.membersSize;
    local counts = Addon.Utils.GetMemberCounts(membersData);
    TheEchoesUI:UpdateInfo(onlineSize, totalSize, counts.main, counts.alt, counts.tank, counts.heal, counts.dps)

    -- filter data by search
    -- [1] array ; [2] boolean
    local filter = Addon.Utils.FilterMembers(membersData, TheEchoesUI:GetSearch());

    -- update members
    TheEchoesUI:UpdateMembers(filter[1], filter[2]); -- membersData, isSearch

end