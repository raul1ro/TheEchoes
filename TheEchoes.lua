local addonName, Addon = ...;

-- Bindings.xml globals
BINDING_HEADER_THE_ECHOES_UI = "User Interface"
BINDING_NAME_THE_ECHOES_TOGGLE = "Toggle Open/Close"

local addonLoadedFrame = CreateFrame("FRAME")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(_, _ , ...)

    -- skip execution if it's not my addon.
    if ... ~= addonName then
        return;
    end

    print("|cff00bfffTheEchoes loading.|r");
    addonLoadedFrame:UnregisterEvent("ADDON_LOADED");

    -- right after loading/reload, the info about guild is not loaded yet.
    -- need to wait a couple of seconds.
    -- run in loop and check until it's true.
    local tries = 0;
    C_Timer.NewTicker(1, function(ticker)

        -- stop retrying
        if(tries >= 15) then
            ticker:Cancel();
            print("|cffff0000TheEchoes failed to init. Guild not found.|r");
            return;
        end

        -- if is in guild init
        if(IsInGuild()) then

            ticker:Cancel();

            if(Addon.Controller:Init()) then
                print("|cff80ff00TheEchoes init.|r");
            else
                print("|cffff0000TheEchoes failed to init. Type `/reload` to retry.|r");
            end

            return;
        end

        tries = tries + 1;

    end)



end);