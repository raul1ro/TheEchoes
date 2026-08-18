local _, Addon = ...;

local name = nil;
local isEditGuildInfo = false;
local isEditPublicNote = false;
local isEditOfficerNote = false;
local isGuildInvite = false;
local isEditMOTD = false;

local listener = CreateFrame("FRAME");
listener:SetScript("OnEvent", function()

    -- unregister after first event
    listener:UnregisterEvent("GUILD_ROSTER_UPDATE");
    listener = nil;

    -- get the data
    name = UnitName("player");
    isEditGuildInfo = CanEditGuildInfo();
    isEditPublicNote = CanEditPublicNote();
    isEditOfficerNote = CanEditOfficerNote();
    isGuildInvite = CanGuildInvite();
    isEditMOTD = CanEditMOTD();

end);
-- GUILD_ROSTER_UPDATE
listener:RegisterEvent("GUILD_ROSTER_UPDATE");

local PlayerData = {};
Addon.PlayerData = PlayerData;

function PlayerData.GetName()
    return name;
end
function PlayerData.IsEditGuildInfo()
    return CanEditGuildInfo();
end
function PlayerData.IsEditPublicNote()
    return CanEditPublicNote();
end
function PlayerData.IsEditOfficerNote()
    return CanEditOfficerNote();
end
function PlayerData.IsGuildInvite()
    return CanGuildInvite();
end
function PlayerData.IsEditMOTD()
    return CanEditMOTD();
end