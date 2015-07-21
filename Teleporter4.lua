local Tp4Class = ZO_Object:Subclass()
local Tp4=Tp4Class:New()

Tp4.addonName = "Teleporter4"
Tp4.defaults = {}
Tp4.memberdata = {}
Tp4.groupUnitTags = {}

ZO_CreateStringId("TP4_NAME", "Teleporter4")

local TP4_RIGHTPANE = nil
local TP4_SCROLLLIST_DATA = 1
local TP4_ScrollList_SORT_KEYS =
{
    ["playerName"] = { },
    ["zoneName"] = {  tiebreaker = "playerName" },
}

local function hook(baseFunc,newFunc)
    return function(...)
        return newFunc(baseFunc,...)
    end
end

local function isInGroup(playerName)
    for idx = 1, GetGroupSize() do
        local groupUnitTag = GetGroupUnitTagByIndex(idx)
        local unitName = GetUnitName(groupUnitTag)
        local rawUnitName = GetRawUnitName(groupUnitTag)
        local uniqueName = GetUniqueNameForCharacter(unitName)
        if playerName == unitName then
                return true
        end
    end
    return false
end

local function getGuildMemberInfo(tabletopopulate)
    local numGuilds = GetNumGuilds()
    local punitFaction = GetUnitAlliance("player")
    local punitName = GetUnitName("player")
    local prawUnitName = GetRawUnitName("player")
    local guildnum
    local inlist = {}

    for guildnum = 1, numGuilds do
        local guildID = GetGuildId(guildnum)
        local numMembers = GetNumGuildMembers(guildID)
        local member -- memberindex

        for member = 1, numMembers do
            local mi = {} --mi == "member info"
            mi.guildid = guildID
            mi.guildname = GetGuildName(guildID)
            mi.name, mi.note, mi.rankindex, mi.status, mi.secsincelastseen =
                GetGuildMemberInfo(guildID,member)
            if mi.status == 1 then -- only collect info for online players
                mi.hasCh, mi.chname, mi.zone, mi.class, mi.alliance, mi.level, mi.vr =
                    GetGuildMemberCharacterInfo(guildID, member)
                mi.unitname = mi.chname:gsub("%^.*$", "") -- Strips all after ^
                --d("mi.name:" .. mi.name)
                --d("mi.note:" .. mi.note)
                --d("mi.rankindex:" .. mi.rankindex)
                --d("mi.status:" .. mi.status)
                --d("mi.secsincelastseen:" .. mi.secsincelastseen)
                --d("mi.hasCh:" .. tostring(mi.hasCh))
                --d("mi.chname:" .. mi.chname)
                --d("mi.unitname:" .. mi.unitname)
                --d("mi.zone:".. mi.zone)
                --d("mi.class:" .. mi.class)
                --d("mi.alliance:" .. mi.alliance)
                --d("mi.level:" .. mi.level)
                --d("mi.vr:"  .. mi.vr)
                --d("mi.guildname:"  .. mi.guildname)
                -- Don't display user, other factions, or players in Cyrodiil
                if mi.chname ~= prawUnitName and mi.zone ~= "Cyrodiil" and mi.alliance == punitFaction then
                    table.insert(tabletopopulate, mi)
                    inlist[mi.unitname] = 1
                end
            end
        end
    end
    -- This should catch group members that aren't in a guild the player is in
    for idx = 1, GetGroupSize() do
        local mi = {}
        local groupUnitTag = GetGroupUnitTagByIndex(idx)
        mi.unitname = GetUnitName(groupUnitTag)
        if inlist[mi.unitname] ~= nil and groupUnitTag ~= nil and IsUnitOnline(groupUnitTag) and mi.unitname ~= punitName then
            mi.zone = GetUnitZone(groupUnitTag)
            mi.class = GetUnitClass(groupUnitTag)
            mi.level = GetUnitLevel(groupUnitTag)
            mi.vr = GetUnitVeteranRank(groupUnitTag)

            table.insert(tabletopopulate, mi)
            inlist[mi.unitname] = 1
        end
    end
end

local function populateScrollList(listdata)
    local displayed = {}
    local scrollData = ZO_ScrollList_GetDataList(TP4_RIGHTPANE.ScrollList)

    ZO_ClearNumericallyIndexedTable(scrollData)

    for _, player in ipairs(listdata) do
        if displayed[player.unitname] == nil then
            if player.name ~= nil then
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(TP4_SCROLLLIST_DATA,
                    {
                        playerName = player.unitname,
                        zoneName = player.zone,
                        playerClass = player.class,
                        playerLevel = player.level,
                        playerVr = player.vr,
                        playeratName = player.name,
                    }
                )
                )
            else
                table.insert(scrollData, ZO_ScrollList_CreateDataEntry(TP4_SCROLLLIST_DATA,
                    {
                        playerName = player.unitname,
                        zoneName = player.zone,
                        playerClass = player.class,
                        playerLevel = player.level,
                        playerVr = player.vr,
                        playeratName = player.unitname,
                    }
                )
                )
            end
            displayed[player.unitname] = 1
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

    -- Create Sort Headers
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

    -- Add a datatype to the scrollList
    ZO_ScrollList_AddDataType(TP4_RIGHTPANE.ScrollList, TP4_SCROLLLIST_DATA, "Tp4Row", 23,
        function(control, data)

            local nameLabel = control:GetNamedChild("Name")
            local locationLabel = control:GetNamedChild("Location")

            local friendColor = ZO_ColorDef:New(0.3, 1, 0, 1)
            local groupColor = ZO_ColorDef:New(0.46, .73, .76, 1)
            local selectedColor = ZO_ColorDef:New(0.7, 0, 0, 1)

            local displayedlevel = nil

            nameLabel:SetText(data.playerName)

            if data.playerLevel < 50 then
                displayedlevel = data.playerLevel
            else
                displayedlevel = "VR" .. data.playerVr
            end

            nameLabel.tooltipText = data.playeratName .. "\n" .. displayedlevel .. " " .. GetClassName(1, data.playerClass)

            locationLabel:SetText(data.zoneName)

            if isInGroup(data.playerName) then
                ZO_SelectableLabel_SetNormalColor(nameLabel, groupColor)
                ZO_SelectableLabel_SetNormalColor(locationLabel, groupColor)

            elseif IsFriend(data.playerName) then
                ZO_SelectableLabel_SetNormalColor(nameLabel, friendColor)
                ZO_SelectableLabel_SetNormalColor(locationLabel, friendColor)

            else
                ZO_SelectableLabel_SetNormalColor(nameLabel, ZO_NORMAL_TEXT)
                ZO_SelectableLabel_SetNormalColor(locationLabel, ZO_NORMAL_TEXT)
            end
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

        --SLASH_COMMANDS["/tp"] = processSlashCommands

        --
        -- Unregister events we are not using anymore
        --
        EVENT_MANAGER:UnregisterForEvent( Tp4.addonName, EVENT_ADD_ON_LOADED )
    end
end


function Tp4:EVENT_PLAYER_ACTIVATED(...)
    d("|cFF2222Teleporter4|r addon loaded")
    --getGuildMemberInfo(Tp4.memberdata)
    --populateScrollList(Tp4.memberdata)

    --
    -- Only once so unreg is from further events
    --
    EVENT_MANAGER:UnregisterForEvent(Tp4.addonName, EVENT_PLAYER_ACTIVATED)
end


function Tp4_OnInitialized()
    EVENT_MANAGER:RegisterForEvent(Tp4.addonName, EVENT_ADD_ON_LOADED, function(...) Tp4:EVENT_ADD_ON_LOADED(...) end )
    EVENT_MANAGER:RegisterForEvent(Tp4.addonName, EVENT_PLAYER_ACTIVATED, function(...) Tp4:EVENT_PLAYER_ACTIVATED(...) end)
    ZO_WorldMap.SetHidden = hook(ZO_WorldMap.SetHidden,function(base,self,value)
        base(self,value)
        if value == false then
            Tp4.memberdata = {}
            getGuildMemberInfo(Tp4.memberdata)
            populateScrollList(Tp4.memberdata)
        end
    end)
end

function nameOnMouseUp(self, button, upInside)
    --d("MouseUp:" .. self:GetText() .. ":" .. tostring(button) .. ":" .. tostring(upInside) )
    local sButton = tostring(button)

    if sButton == "1" then -- left
        JumpToGuildMember(self:GetText())

    elseif sButton == "2" then -- right
        ZO_ScrollList_RefreshVisible(TP4_RIGHTPANE.ScrollList)

    else -- middle
        Tp4.memberdata = {}
        getGuildMemberInfo(Tp4.memberdata)
        populateScrollList(Tp4.memberdata)
    end
end
--[[
EVENT_GROUP_MEMBER_JOINED (integer eventCode, string memberName)
EVENT_GROUP_MEMBER_LEFT (integer eventCode, string memberName, integer reason, bool wasLocalPlayer)

--]]
