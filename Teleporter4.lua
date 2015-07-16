--- local mylibrary = LibStub:GetLibrary("mylibraryname")
--

local Tp4Class = ZO_Object:Subclass()
local Tp4=Tp4Class:New()

Tp4.addonName = "Teleporter4"
Tp4.chatWasMinimized = false
Tp4.defaults = { }

ZO_CreateStringId("TP4_NAME", "Teleporter4")

local Tp4_TLW = nil
local TP4_RIGHTPANE = nil
local TP4_LOCATION_DATA = 1
local playerData = {"Dummyplayer", "dummyzone"}
local TP4_ScrollList_SORT_KEYS =
{
    ["playerName"] = { },
    ["zoneName"] = {  tiebreaker = "playerName" },
}

--[[
local function showTp4Windows(toggle)
    --- Tp4_LootWindow:SetHidden( not toggle )
    --- Tp4_Map:SetHidden( not toggle )
    Tp4_TLW:SetHidden( not toggle )
    if not toggle then
        if not Tp4.chatWasMinimized then
            CHAT_SYSTEM:Maximize()
        end
    end
end
--]]
local function populateScrollList()
    local scrollData = ZO_ScrollList_GetDataList(TP4_RIGHTPANE.ScrollList)
    ZO_ClearNumericallyIndexedTable(scrollData)

    table.insert(scrollData, ZO_ScrollList_CreateDataEntry(TP4_LOCATION_DATA,
        {
            playerName = "Test Name",
            zoneName = "Test Zone"
        }
        )
    )
end

local function createTp4RightPane()
	local x,y = ZO_WorldMapLocations:GetDimensions()
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ZO_WorldMapLocations:GetAnchor()

	TP4_RIGHTPANE = WINDOW_MANAGER:CreateTopLevelWindow(nil)
	TP4_RIGHTPANE:SetMouseEnabled(true)		
	TP4_RIGHTPANE:SetMovable( false )
	TP4_RIGHTPANE:SetClampedToScreen(true)
	TP4_RIGHTPANE:SetDimensions( x, y )
	TP4_RIGHTPANE:SetAnchor( point, relativeTo, relativePoint, offsetX, offsetY )
	TP4_RIGHTPANE:SetHidden( true )

    --
    -- Create Sort Headers
    --
    TP4_RIGHTPANE.Headers = WINDOW_MANAGER:CreateControl("$(parent)Headers",TP4_RIGHTPANE,nil)
    TP4_RIGHTPANE.Headers:SetAnchor( TOPLEFT, TP4_RIGHTPANE, TOPLEFT, 0, 0 )
    TP4_RIGHTPANE.Headers:SetHeight(32)

    TP4_RIGHTPANE.Headers.Name = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Name",TP4_RIGHTPANE.Headers,"ZO_SortHeader")
    TP4_RIGHTPANE.Headers.Name:SetDimensions(115,32)
    TP4_RIGHTPANE.Headers.Name:SetAnchor( TOPLEFT, TP4_RIGHTPANE.Headers, TOPLEFT, 8, 0 )
    ZO_SortHeader_Initialize(TP4_RIGHTPANE.Headers.Name, "Name", "playerName", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
    ZO_SortHeader_SetTooltip(TP4_RIGHTPANE.Headers.Name, "Sort on player name")

    TP4_RIGHTPANE.Headers.Location = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Location",TP4_RIGHTPANE.Headers,"ZO_SortHeader")
    TP4_RIGHTPANE.Headers.Location:SetDimensions(115,32)
    TP4_RIGHTPANE.Headers.Location:SetAnchor( LEFT, TP4_RIGHTPANE.Headers.Name, RIGHT, 18, 0 )
    ZO_SortHeader_Initialize(TP4_RIGHTPANE.Headers.Location, "Zone", "zoneName", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
    ZO_SortHeader_SetTooltip(TP4_RIGHTPANE.Headers.Location, "Sort on zone")

    local sortHeaders = ZO_SortHeaderGroup:New(TP4_RIGHTPANE:GetNamedChild("Headers"), SHOW_ARROWS)
    sortHeaders:RegisterCallback(
        ZO_SortHeaderGroup.HEADER_CLICKED,
        function(key, order)
            table.sort(
                ZO_ScrollList_GetDataList(TP4_RIGHTPANE.ScrollList),
                function(entry1, entry2)
                    return ZO_TableOrderingFunction(entry1.data, entry2.data, key, TP4_ScrollList_SORT_KEYS, order)
                end)

            ZO_ScrollList_Commit(TP4_RIGHTPANE.ScrollList)
        end)
    sortHeaders:AddHeadersFromContainer()

    -- Create a scrollList
    TP4_RIGHTPANE.ScrollList = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Tp4ScrollList", TP4_RIGHTPANE, "ZO_ScrollList")
    TP4_RIGHTPANE.ScrollList:SetDimensions(x, y-32)
    TP4_RIGHTPANE.ScrollList:SetAnchor(TOPLEFT, TP4_RIGHTPANE.Headers, BOTTOMLEFT, 0, 0)

    --
    -- Add a datatype to the scrollList
    --
    ZO_ScrollList_Initialize(TP4_RIGHTPANE.ScrollList)
    ZO_ScrollList_EnableHighlight(TP4_RIGHTPANE.ScrollList, "ZO_ThinListHighlight")
    ZO_ScrollList_AddDataType(TP4_RIGHTPANE.ScrollList, TP4_LOCATION_DATA, "Tp4Row", 23,
        function(control, data)
            control:GetNamedChild("Name"):SetText(data.playerName)
            control:GetNamedChild("Location"):SetText(data.zoneName)
        end
    )

    populateScrollList()

    local buttonData = {
        normal = "EsoUI/Art/mainmenu/menubar_journal_up.dds",
        pressed = "EsoUI/Art/mainmenu/menubar_journal_down.dds",
        highlight = "EsoUI/Art/mainmenu/menubar_journal_over.dds",
    }

    --
	-- Create a fragment from the window and add it to the modeBar of the WorldMap RightPane
	--
	local tp4Fragment = ZO_FadeSceneFragment:New(TP4_RIGHTPANE)
	WORLD_MAP_INFO.modeBar:Add(TP4_NAME, {tp4Fragment}, buttonData)

    --
    -- Create a few preHookHandlers so that the map shows up back again when hidden
    --     
    --ZO_PreHookHandler(TP4_RIGHTPANE     , "OnHide", function() showTp4Windows( false ) end)
    --ZO_PreHookHandler(ZO_WorldMapLocations, "OnShow", function() ZO_WorldMap:SetHidden( false ) showTp4Windows( false ) end)
    --ZO_PreHookHandler(ZO_WorldMapFilters  , "OnShow", function() ZO_WorldMap:SetHidden( false ) showTp4Windows( false ) end)
    --ZO_PreHookHandler(ZO_WorldMapKey      , "OnShow", function() ZO_WorldMap:SetHidden( false ) showTp4Windows( false ) end)
    --ZO_PreHookHandler(ZO_WorldMapQuests   , "OnShow", function() ZO_WorldMap:SetHidden( false ) showTp4Windows( false ) end)
    --ZO_PreHookHandler(TP4_RIGHTPANE     , "OnShow", function() Tp4.chatWasMinimized = CHAT_SYSTEM:IsMinimized() end)
end


function Tp4:OnLinkClicked(rawLink, mouseButton, linkText, color, linkType, ...)
    ---if linkType == "set" then
    ---    showAtlasLoot(Tp4.lastZoneRequested, rawLink)
    ---    return true
    ---end
end


function Tp4:EVENT_ADD_ON_LOADED(eventCode, addonName, ...)
    if addonName == Tp4.addonName then
        Tp4.SavedVariables = ZO_SavedVars:New("Tp4_SavedVariables", 2, nil, Tp4.defaults)
        createTp4RightPane()


        SLASH_COMMANDS["/tp4"] = processSlashCommands
        --
        -- Unregister events we are not using anymore
        --
        EVENT_MANAGER:UnregisterForEvent( Tp4.addonName, EVENT_ADD_ON_LOADED )

        --- WORLD_MAP_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        ---    if newState == SCENE_SHOWING then
        ---        EVENT_MANAGER:RegisterForUpdate(Tp4.addonName.."MapUpdate", 1000, function() Tp4:ON_MAP_UPDATE() end)
        ---    elseif newState == SCENE_HIDING then
        ---        EVENT_MANAGER:UnregisterForUpdate(Tp4.addonName.."MapUpdate")
        ---    end
        ---end)

        LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, function(...) return Tp4:OnLinkClicked(...) end)
    end
end


function Tp4:EVENT_PLAYER_ACTIVATED(...)
    d("|cFF2222Teleporter4|r addon Loaded, /tp4 for more info")
    --
    -- Only once so unreg is from further events
    --
    EVENT_MANAGER:UnregisterForEvent( Tp4.addonName, EVENT_PLAYER_ACTIVATED )
end


function Tp4_OnInitialized()
    EVENT_MANAGER:RegisterForEvent(Tp4.addonName, EVENT_ADD_ON_LOADED, function(...) Tp4:EVENT_ADD_ON_LOADED(...) end )
    EVENT_MANAGER:RegisterForEvent(Tp4.addonName, EVENT_PLAYER_ACTIVATED, function(...) Tp4:EVENT_PLAYER_ACTIVATED(...) end)
end

