local _, Addon = ...;

local GuildData = {};
Addon.GuildData = GuildData;

-- about guild
local data;

local scheduledThreadPing;
local listener = CreateFrame("FRAME");
listener:SetScript("OnEvent", function()

    data = Addon.Utils.GetGuildData();
    Addon.Controller.RefreshUI();

end)

function GuildData.GetData()
    return data;
end

function GuildData.GetMainNames()

    local mainNames = {};
    for _, memberData in ipairs(data.membersData) do

        -- exclude members with `errorMain` - theoretically is alt
        -- errorRoles - doesn't matter
        -- errorType - ? might be main, or not
        if(memberData.errorMain == nil) then
            table.insert(mainNames, memberData.name);
        end

    end

    -- sort
    table.sort(mainNames);

    return mainNames;

end

function GuildData.StartListening()

    -- register to the event
    listener:RegisterEvent("GUILD_ROSTER_UPDATE");

    -- initial data
    data = Addon.Utils.GetGuildData();
    Addon.Controller.RefreshUI();

    -- initial ping
    GuildRoster();

    -- schedule a thread every 10 seconds to ping for data.
    scheduledThreadPing = C_Timer.NewTicker(10.1, function()
        GuildRoster();
    end)

end

function GuildData.StopListening()

    -- unregister
    listener:UnregisterEvent("GUILD_ROSTER_UPDATE");

    -- drop the table
    data = nil;

    -- stop pinging
    scheduledThreadPing:Cancel();
    scheduledThreadPing = nil;

end