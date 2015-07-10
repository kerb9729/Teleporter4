--- local mylibrary = LibStub:GetLibrary("mylibraryname")
--

local Tp4Class = ZO_Object:Subclass()
local Tp4=Tp4Class:New()

Tp4.addonName = "Teleporter4"
-- Tp4.testvar = GetUnitName("player")
Tp4.chatWasMinimized = false
Tp4.defaults = { }

ZO_CreateStringId("TP4_NAME", "Teleporter4")

local Tp4_TLW = nil
local TP4_RIGHTPANE = nil


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

    TP4_RIGHTPANE.Headers.Name = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Name",TP4_RIGHTPANE.Headers,"ZO_SortHeaderIcon")
    TP4_RIGHTPANE.Headers.Name:SetDimensions(70,32)
    TP4_RIGHTPANE.Headers.Name:SetAnchor( TOPLEFT, TP4_RIGHTPANE.Headers, TOPLEFT, 8, 0 )
    ZO_SortHeader_InitializeArrowHeader(TP4_RIGHTPANE.Headers.Name, "nameHeader", ZO_SORT_ORDER_UP)
    ZO_SortHeader_SetTooltip(TP4_RIGHTPANE.Headers.Name, "Sort on Name")

    TP4_RIGHTPANE.Headers.Location = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)Location",TP4_RIGHTPANE.Headers,"ZO_SortHeader")
    TP4_RIGHTPANE.Headers.Location:SetDimensions(160,32)
    TP4_RIGHTPANE.Headers.Location:SetAnchor( LEFT, TP4_RIGHTPANE.Headers.Name, RIGHT, 18, 0 )
    ZO_SortHeader_Initialize(TP4_RIGHTPANE.Headers.Location, "Location List", "locationName", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
    ZO_SortHeader_SetTooltip(TP4_RIGHTPANE.Headers.Location, "Sort on Location")

    local sortHeaders = ZO_SortHeaderGroup:New(TP4_RIGHTPANE:GetNamedChild("Headers"), SHOW_ARROWS)

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
    ZO_PreHookHandler(TP4_RIGHTPANE     , "OnHide", function() showTp4Windows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapLocations, "OnShow", function() ZO_WorldMap:SetHidden( false ) showTp4Windows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapFilters  , "OnShow", function() ZO_WorldMap:SetHidden( false ) showTp4Windows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapKey      , "OnShow", function() ZO_WorldMap:SetHidden( false ) showTp4Windows( false ) end)
    ZO_PreHookHandler(ZO_WorldMapQuests   , "OnShow", function() ZO_WorldMap:SetHidden( false ) showTp4Windows( false ) end)
    ZO_PreHookHandler(TP4_RIGHTPANE     , "OnShow", function() Tp4.chatWasMinimized = CHAT_SYSTEM:IsMinimized() end)
end


local function createTp4Interface()
    --
    -- This object should hold everything ...
    --
---    local x,y = ZO_WorldMap:GetDimensions()
---    x = x + 500
---    y = y + 80

    Tp4_TLW = WINDOW_MANAGER:CreateTopLevelWindow(nil)
    Tp4_TLW:SetMovable( false )
    Tp4_TLW:SetClampedToScreen(true)
    Tp4_TLW:SetDimensions( x , y )
    Tp4_TLW:SetAnchor( TOPRIGHT, ZO_WorldMap, TOPRIGHT, 40, -40 )
    Tp4_TLW:SetHidden( true )
    --
    -- Define a label that holds the addonName and show it on top of the TLW
    --
    Tp4_TLW.title = WINDOW_MANAGER:CreateControl(nil, Tp4_TLW, CT_LABEL)
    Tp4_TLW.title:SetColor(0.8, 0.8, 0.8, 1)
    Tp4_TLW.title:SetFont("ZoFontAlert")
    Tp4_TLW.title:SetScale(1.5)
    Tp4_TLW.title:SetWrapMode(TEX_MODE_CLAMP)
    Tp4_TLW.title:SetDrawLayer(2)
    Tp4_TLW.title:SetText("Teleporter4")
    Tp4_TLW.title:SetAnchor(TOP, Tp4_TLW, nil, 110, -10)
    Tp4_TLW.title:SetDimensions(200,25)
    --
---    -- Define a texture that holds the faction of the dungeon
---    --
---    Tp4_TLW.factionTextureLeft = WINDOW_MANAGER:CreateControl(nil, Tp4_TLW, CT_TEXTURE)
---    Tp4_TLW.factionTextureLeft:SetDimensions(x-240,y-500)
---    Tp4_TLW.factionTextureLeft:SetAnchor(TOPLEFT, Tp4_TLW, TOPLEFT, 40, 0)
---
---    Tp4_TLW.factionTextureRight = WINDOW_MANAGER:CreateControl(nil, Tp4_TLW, CT_TEXTURE)
---    Tp4_TLW.factionTextureRight:SetDimensions(400,y-500)
---    Tp4_TLW.factionTextureRight:SetAnchor(TOPRIGHT, Tp4_TLW, TOPRIGHT, 200, 0)
---    --
---    -- Define a divider above the faction textures
---    --
---    Tp4_TLW.titledividerLeft = WINDOW_MANAGER:CreateControl(nil,  Tp4_TLW, CT_TEXTURE)
---    Tp4_TLW.titledividerLeft:SetDimensions(x-100,4)
---    Tp4_TLW.titledividerLeft:SetAnchor(TOPLEFT, Tp4_TLW, TOPLEFT, 50, 6)
---    Tp4_TLW.titledividerLeft:SetTexture("/esoui/art/guild/sectiondivider_left.dds")
---
---    Tp4_TLW.titledividerRight = WINDOW_MANAGER:CreateControl(nil,  Tp4_TLW, CT_TEXTURE)
---    Tp4_TLW.titledividerRight:SetDimensions(100,4)
---    Tp4_TLW.titledividerRight:SetAnchor(TOPLEFT, Tp4_TLW.titledividerLeft, TOPRIGHT, 0, 0)
---    Tp4_TLW.titledividerRight:SetTextureCoords(0, 1, 0, 0.391)
---    Tp4_TLW.titledividerRight:SetTexture("/esoui/art/guild/sectiondivider_right.dds")
---    --
---    -- Add a faction texture
---    --
---    Tp4_TLW.NameHeaderIconTexture = WINDOW_MANAGER:CreateControl(nil,  Tp4_TLW, CT_TEXTURE)
---    Tp4_TLW.NameHeaderIconTexture:SetDimensions(120,120)
---    Tp4_TLW.NameHeaderIconTexture:SetAnchor(TOP, Tp4_TLW, nil, (x/2)-140, 50)
---    Tp4_TLW.factionTextureLeft:SetTexture("/esoui/art/campaign/overview_scoringbg_daggerfall_left.dds")
---    Tp4_TLW.factionTextureRight:SetTexture("/esoui/art/campaign/overview_scoringbg_daggerfall_right.dds")
---    Tp4_TLW.NameHeaderIconTexture:SetTexture("/esoui/art/compass/ava_borderkeep_pin_daggerfall.dds")
---    Tp4_TLW.NameHeaderIconTexture:SetHidden(false)

---    Tp4_TLW.NameHeaderIconTexture:SetTexture("")	--Will be set when zone gets determined


    createTp4RightPane()
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
        createTp4Interface()


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

