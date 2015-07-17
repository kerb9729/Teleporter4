--- local mylibrary = LibStub:GetLibrary("mylibraryname")
--

local Tp4Class = ZO_Object:Subclass()
local Tp4=Tp4Class:New()

Tp4.addonName = "Teleporter4"
Tp4.chatWasMinimized = false
Tp4.defaults = { }
Tp4.memberdata = {}

ZO_CreateStringId("TP4_NAME", "Teleporter4")

local Tp4_TLW = nil
local TP4_RIGHTPANE = nil
local TP4_LOCATION_DATA = 1
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

local function getGuildMemberInfo()
    local numGuilds = GetNumGuilds()
    d( "numGuilds:" .. numGuilds )

    local guildnum
    for guildnum = 1, numGuilds do
        local guildID = GetGuildId(guildnum)
        local numMembers = GetNumGuildMembers(guildID)
        d("guildID:" .. guildID)
        d("numMembers:" .. numMembers)
        --[[
        --GetGuildMemberInfo(integer guildId, integer memberIndex)
              Returns: string name, string note, integer rankIndex, integer playerStatus, integer secsSinceLogoff
          GetGuildMemberCharacterInfo(integer guildId, integer memberIndex)
              Returns: boolean hasCharacter, string characterName, string zoneName, integer classType, integer alliance, integer level, integer veteranRank
        --]]
        local member -- memberindex
        for member = 1, numMembers do
            local mi = {} --mi == "member info"
            mi.guildname = GetGuildName(guildID)
            mi.name, mi.note, mi.rankindex, mi.status, mi.secsincelastseen =
                GetGuildMemberInfo(guildID,member)
            if mi.status == 1 then
                mi.hasCh, mi.chname, mi.zone, mi.class, mi.alliance, mi.level, mi.vr =
                    GetGuildMemberCharacterInfo(guildID, member)
                d("mi.name:" .. mi.name .. "\n" ..
                  "mi.note:" .. mi.note .. "\n" ..
                  "mi.rankindex:" .. mi.rankindex .. "\n" ..
                  "mi.status:" .. mi.status .. "\n" ..
                  "mi.secsincelastseen:" .. mi.secsincelastseen .. "\n" ..
                  "mi.hasCh:" .. tostring(mi.hasCh) .. "\n" ..
                  "mi.chname:" .. mi.chname .. "\n" ..
                  "mi.zone:".. mi.zone .. "\n" ..
                  "mi.class:" .. mi.class .. "\n" ..
                  "mi.alliance:" .. mi.alliance .. "\n" ..
                  "mi.level:" .. mi.level .. "\n" ..
                  "mi.vr:"  .. mi.vr .. "\n" )
                table.insert(Tp4.memberdata, mi)
            end
        end
    end
end

local function populateScrollList(listdata)
    local displayed = {}
    displayed[GetUnitName("player")] = 1
    local scrollData = ZO_ScrollList_GetDataList(TP4_RIGHTPANE.ScrollList)
    ZO_ClearNumericallyIndexedTable(scrollData)

    for k, player in ipairs(listdata) do
        if displayed[player.name] == nil then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(TP4_LOCATION_DATA,
                {
                    playerName = player.name,
                    zoneName = player.zone
                }
                )
            )
            displayed[player.name] = 1
        end
    end
    ZO_ScrollList_Commit(TP4_RIGHTPANE.ScrollList)
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
    TP4_RIGHTPANE.Headers.Location:SetDimensions(150,32)
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

end


function Tp4:EVENT_ADD_ON_LOADED(eventCode, addonName, ...)
    if addonName == Tp4.addonName then
        Tp4.SavedVariables = ZO_SavedVars:New("Tp4_SavedVariables", 2, nil, Tp4.defaults)
        createTp4RightPane()

        --SLASH_COMMANDS["/tp4"] = processSlashCommands

        --
        -- Unregister events we are not using anymore
        --
        EVENT_MANAGER:UnregisterForEvent( Tp4.addonName, EVENT_ADD_ON_LOADED )
        -- LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, function(...) return Tp4:OnLinkClicked(...) end)
    end
end


function Tp4:EVENT_PLAYER_ACTIVATED(...)
    d("|cFF2222Teleporter4|r addon loaded")
    getGuildMemberInfo()
    populateScrollList(Tp4.memberdata)
    --
    -- Only once so unreg is from further events
    --
    EVENT_MANAGER:UnregisterForEvent( Tp4.addonName, EVENT_PLAYER_ACTIVATED )
end


function Tp4_OnInitialized()
    EVENT_MANAGER:RegisterForEvent(Tp4.addonName, EVENT_ADD_ON_LOADED, function(...) Tp4:EVENT_ADD_ON_LOADED(...) end )
    EVENT_MANAGER:RegisterForEvent(Tp4.addonName, EVENT_PLAYER_ACTIVATED, function(...) Tp4:EVENT_PLAYER_ACTIVATED(...) end)
end

function nameOnMouseUp(self, button, upInside)
    d("MouseUp:" .. self:GetText() .. ":" .. tostring(button) .. ":" .. tostring(upInside) )
    JumpToGuildMember(self:GetText())
end

function nameOnClicked(self, button)
    d("Clicked:" .. self:GetText() .. ":" .. button)
end
