-- constants
local TheEchoesButton

local function getData()

    local guildData = getGuildData() -- membersData, errorMembers, onlineSize, totalSize

    local membersData = sortMembers(guildData.membersData)
    local totalSize = guildData.totalSize
    local onlineSize = guildData.onlineSize
    local mainSize = size(membersData)
    local altSize = totalSize - mainSize

    return { membersData, totalSize, onlineSize, mainSize, altSize, guildData.errorMembers }

end

local function init()

    -- Create square button
    TheEchoesButton = CreateFrame("Button", "TheEchoesButton", UIParent)
    TheEchoesButton:SetSize(32, 32)
    TheEchoesButton:SetPoint("CENTER", 0, 0)
    TheEchoesButton:Hide()

    -- Set the background
    TheEchoesButton:SetNormalTexture("Interface\\AddOns\\TheEchoes\\images\\logo_circle_32.tga")
    TheEchoesButton:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
    TheEchoesButton:GetNormalTexture():SetBlendMode("BLEND")

    -- Make the button movable
    TheEchoesButton:SetMovable(true)
    TheEchoesButton:EnableMouse(true)
    TheEchoesButton:RegisterForDrag("LeftButton")
    TheEchoesButton:SetScript("OnDragStart", TheEchoesButton.StartMoving)
    TheEchoesButton:SetScript("OnDragStop", TheEchoesButton.StopMovingOrSizing)
    TheEchoesButton:SetUserPlaced(true)

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
local guildEventListener = CreateFrame("Frame")
local guildRoasterTrigger
TheEchoes = {

    PlayerName = UnitName("player"),

    -- listen for guild events
    startAutoUpdate = function()

        -- register listener for guild events
        guildEventListener:RegisterEvent("GUILD_ROSTER_UPDATE")
        guildEventListener:SetScript("OnEvent", function(_, event)
            if event == "GUILD_ROSTER_UPDATE" then
                TheEchoesUI.setData(unpack(getData()))
            end
        end)

        -- prevent to create more threads
        if(guildRoasterTrigger ~= nil) then return end

        -- trigger guild event
        GuildRoster()
        -- re-trigger it at every 10 seconds
        guildRoasterTrigger = C_Timer.NewTicker(10, function()
            GuildRoster()
        end)

    end,

    -- stop listening
    stopAutoUpdate = function()

        guildEventListener:UnregisterEvent("GUILD_ROSTER_UPDATE")
        guildEventListener:SetScript("OnEvent", nil)

        if(guildRoasterTrigger == nil) then return end
        guildRoasterTrigger:Cancel()
        guildRoasterTrigger = nil

    end,

    triggerUpdate = function()
        TheEchoesUI.setData(unpack(getData()))
    end

}

-- call inits only after load
local addonLoadedFrame = CreateFrame("FRAME")
addonLoadedFrame:RegisterEvent("ADDON_LOADED")
addonLoadedFrame:SetScript("OnEvent", function(_, event , ...)

    if (event == "ADDON_LOADED") and (... == "TheEchoes") then

        init() -- init the main part

        -- init the ui, only after got guild info
        local function initUI(tries)

            if(IsInGuild()) then

                GuildRoster()

                local guildData = getData()
                if(guildData[3] > 0) then --totalSize

                    TheEchoesUI.init()
                    TheEchoesUI.setData(unpack(guildData))

                    print("|cff00bfffTheEchoes init|r")

                    -- Event on click, toggle the ui
                    TheEchoesButton:Show()
                    TheEchoesButton:SetScript("OnClick", function(_, button)
                        if button == "LeftButton" then
                            TheEchoesUI.toggle()
                        end
                    end)

                    return

                end

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