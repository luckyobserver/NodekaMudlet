export ^
export doSpeedWalk

export mudlet
mudlet = mudlet or {}
mudlet.mapper_script = true

Map.walking = false

profilePath = getMudletHomeDir!
mapFolder = string.gsub(profilePath, "\\", "/").."/NodekaMudlet"

-- Configuration variables
Map.config = {
    mode: "normal",
    max_search_distance: 1,
    debug: false,
    recall: {},
}

config = ->
    if io.exists(mapFolder.."/map_config.dat")
        table.load(mapFolder.."/map_config.dat", Map.config)
    Map.LoadMap!
    return

-- variables
move_queue = {}
lines = {}
walking = false
exitmap = {
    n: 'north',    ne: 'northeast',   nw: 'northwest',   e: 'east',
    w: 'west',     s: 'south',        se: 'southeast',   sw: 'southwest',
    u: 'up',       d: 'down',         ["in"]: 'in',      out: 'out',
    l: 'look'
}
short = {}
for k,v in pairs(exitmap)
    short[v] = k

stubmap = {
    north: 1,      northeast: 2,      northwest: 3,      east: 4,
    west: 5,       south: 6,          southeast: 7,      southwest: 8,
    up: 9,         down: 10,          ["in"]: 11,        out: 12,
    [1]: "north",  [2]: "northeast",  [3]: "northwest",  [4]: "east",
    [5]: "west",   [6]: "south",      [7]: "southeast",  [8]: "southwest",
    [9]: "up",     [10]: "down",      [11]: "in",        [12]: "out",
}

coordmap = {
    [1]: {0,1,0},      [2]: {1,1,0},      [3]: {-1,1,0},     [4]: {1,0,0},
    [5]: {-1,0,0},     [6]: {0,-1,0},     [7]: {1,-1,0},     [8]: {-1,-1,0},
    [9]: {0,0,1},      [10]: {0,0,-1},    [11]: {0,0,0},     [12]: {0,0,0},
}

reverse_dirs = {
    north: "south", south: "north", west: "east", east: "west", up: "down",
    down: "up", northwest: "southeast", northeast: "southwest", southwest: "northeast",
    southeast: "northwest", ["in"]: "out", out: "in",
}

get_room_stubs = (roomID) ->
    -- turns stub info into table similar to exit table
    stubs = getExitStubs(roomID)
    if type(stubs) != "table"
        stubs = {}
    exits = {}
    for k, v in pairs(stubs) do
        exits[stubmap[v]] = 0
    return exits

Map.CheckDoors = (roomID, exits) ->
    Map.debug("Map.CheckDoors")
    -- looks to see if there are doors in designated directions
    -- used for room comparison, can also be used for pathing purposes
    if type(exits) == "string"
        exits = {exits}
    statuses = {}
    doors = getDoors(roomID)
    for k, v in pairs(exits) do
        dir = short[k] or short[v]
        if table.contains({'u', 'd'}, dir)
            dir = exitmap[dir]
        if not doors[dir] or doors[dir] == 0
            return false
        else
            statuses[dir] = doors[dir]
    return statuses

check_room = (roomID, name, exits, onlyName) ->
    Map.debug("check_room: "..(roomID or "none").." " ..(name or "none").." "..(table.concat(exits, " ") or "none"))
    -- check to see if room name and exits match expecations
    if not roomID
        Map.error("Check Room Error: No ID")
        return true
    if name != getRoomName(roomID)
        Map.error("Unexpected room name: "..(name or "none").." "..roomID)
        return false
    if onlyName then return true
    t_exits = table.union(getRoomExits(roomID), get_room_stubs(roomID))
    for k,v in ipairs(exits)
        if short[v] and not table.contains(t_exits,v) then return false
        t_exits[v] = nil
    return table.is_empty(t_exits) or Map.CheckDoors(roomID,t_exits)

--############################################################### MOVE TRACKING

add_door = (roomID, dir, doorName, status) ->
    -- create or remove a door in the designated direction
    -- consider options for adding pickable and passable information
    dir = exitmap[dir] or dir
    if not table.contains(exitmap, dir)
        Map.error("Add Door: invalid direction.")
    if type(status) != "number"
        status = assert(
            table.index_of(
                {"none", "open", "closed", "locked"},
                status),
            "Add Door: Invald status, must be none, open, closed, or locked"
        )-1
    exits = getRoomExits(roomID)
    if exits[dir]
        if doorName == ""
            Map.debug("Trying to get door: "..dir)
            doorName = getRoomUserData(exits[dir], "door."..reverse_dirs[dir])
    if not table.contains({'u', 'd'}, short[dir])
        setDoor(roomID, short[dir], status)
        setRoomUserData(roomID, "door." .. short[dir], doorName)
    else
        setDoor(roomID, dir, status)
        setRoomUserData(roomID, "door." .. dir, doorName)
    Map.echo("Adding door: "..dir.." "..doorName.." "..status)
    return


find_room = (name, area) ->
    -- looks for rooms with a particular name, and if given, in a specific area
    rooms = searchRoom(name)
    if tonumber(area) then area = tonumber(area)
    elseif area then area = Map.GetAreaID(area)

    for k, v in pairs(rooms) do
        if string.lower(v) != string.lower(name)
            rooms[k] = nil
        elseif area and getRoomArea(k) != area
            rooms[k] = nil
    return rooms

connect_rooms = (ID1, ID2, dir1, dir2, no_check) ->
    -- makes a connection between rooms
    -- can make backwards connection without a check
    Map.echo("Connect rooms: " .. ID1 .. " " .. ID2 .. " " .. dir1)
    match = false
    if not ID1 and ID2 and dir1
        Map.error("Connect Rooms: Missing Required Arguments.", 2)
    dir2 = dir2 or reverse_dirs[dir1]
    if stubmap[dir1] <= 12
        setExit(ID1, ID2, stubmap[dir1])
    else
        setRoomUserData(ID1, "exit " .. dir1, ID2)
    doors1, doors2 = getDoors(ID1), getDoors(ID2)
    dstatus1 = doors1[short[dir1]] or doors1[dir1]
    dstatus2 = doors2[short[dir2]] or doors2[dir2]
    if dstatus1 != dstatus2
        if not table.contains({'u', 'd'}, short[dir])
            doorName = getRoomUserData(ID1, "door." .. short[dir1])
        else
            doorName = getRoomUserData(ID1, "door." .. dir1)
        if not dstatus1
            add_door(ID1, dir1, doorName, dstatus2)
        elseif not dstatus2
            add_door(ID2, dir2, doorName, dstatus1)
    if Map.config.mode != "complex"
        stubs = get_room_stubs(ID2)
        if stubs[dir2]
            match = true
        if (match or no_check)
            if stubmap[dir1] <= 12
                setExit(ID2, ID1, stubmap[dir2])
    return

create_room = (name, exits, dir, coords) ->
  -- makes a new room with captured name and exits
  -- links with other rooms as appropriate
  -- links to adjacent rooms in direction of exits if in simple mode
    if not Map.mapping then return
    Map.echo "New Room: "..name
    newID = createRoomID()
    addRoom(newID)
    setRoomArea(newID, Map.currentArea)
    setRoomName(newID, name)
    for k, v in ipairs(exits) do
        if stubmap[v]
            if stubmap[v] <= 12
                setExitStub(newID, stubmap[v], true)
    if dir
        connect_rooms(Map.currentRoom, newID, dir)
    setRoomCoordinates(newID, unpack(coords))
    pos_rooms = getRoomsByPosition(Map.currentArea, unpack(coords))
    if Map.config.mode == "simple"
        x, y, z = unpack(coords)
        dx, dy, dz, rooms
        for k, v in ipairs(exits) do
            if stubmap[v]
                dx, dy, dz = unpack(coordmap[stubmap[v]])
                rooms = getRoomsByPosition(Map.currentArea, x + dx, y + dy, z + dz)
                if table.size(rooms) == 1
                    connect_rooms(newID, rooms[0], v)
    Map.SetRoom(newID)
    return

find_area_limits = (areaID) ->
    -- used to find min and max coordinate limits for an area
    if not areaID
        Map.error("Find Limits: Missing area ID")
        return
    rooms = getAreaRooms(areaID)
    minx, miny, minz = getRoomCoordinates(rooms[0])
    maxx, maxy, maxz = minx, miny, minz
    local x,y,z
    for k,v in pairs(rooms) do
        x,y,z = getRoomCoordinates(v)
        minx = math.min(x,minx)
        maxx = math.max(x,maxx)
        miny = math.min(y,miny)
        maxy = math.max(y,maxy)
        minz = math.min(z,minz)
        maxz = math.max(z,maxz)
    return minx, maxx, miny, maxy, minz, maxz


find_link = (name, exits, dir, max_distance) ->
    -- search for matching room in desired direction
    -- in lazy mode check_room search only by name
    x,y,z = getRoomCoordinates(Map.currentRoom)
    if Map.mapping and x
        if max_distance < 1
            max_distance = nil
        else
            max_distance = max_distance - 1
        if not stubmap[dir] or not coordmap[stubmap[dir]] then return
        dx,dy,dz = unpack(coordmap[stubmap[dir]])
        minx, maxx, miny, maxy, minz, maxz = find_area_limits(Map.currentArea)
        local rooms, match, stubs
        if max_distance
            minx, maxx = x - max_distance, x + max_distance
            miny, maxy = y - max_distance, y + max_distance
            minz, maxz = z - max_distance, z + max_distance
        while true
            x, y, z = x + dx, y + dy, z + dz
            rooms = getRoomsByPosition(Map.currentArea,x,y,z)
            break if (x > maxx or x < minx or y > maxy or y < miny or z > maxz or z < minz or not table.is_empty(rooms))
        for k,v in pairs(rooms) do
            if check_room(v,name,exits,false)
                match = v
                break
            elseif Map.config.mode == "lazy" and check_room(v,name,exits,true)
                match = v
                break
        if match
            connect_rooms(Map.currentRoom, match, dir)
            Map.SetRoom(match)
        else
            x,y,z = getRoomCoordinates(Map.currentRoom)
            create_room(name, exits, dir,{x+dx,y+dy,z+dz})
    return

move_map = ->
    Map.debug("move_map")
    -- tries to move the map to the next room
    move = table.remove(move_queue, 1)
    if move --or random_move
        Map.debug("move_map: " .. move)
        exits = (Map.currentRoom and getRoomExits(Map.currentRoom)) or {}
        if move == "recall" and Map.config.recall[Map.character]
            Map.debug("move_map: recalled")
            Map.SetRoom(Map.config.recall[Map.character])
        elseif move == "look" and Map.currentRoom and check_room(Map.currentRoom, Map.currentName, Map.currentExits)
            Map.debug("move_map: looking")
            Map.SetRoom(Map.currentRoom)
        else
            if exits[move] and check_room(exits[move], Map.currentName, Map.currentExits)
                Map.SetRoom(exits[move])
            else
                if Map.mapping and move
                    find_link(Map.currentName, Map.currentExits, move, Map.config.max_search_distance)
                else
                    Map.FindMe(Map.currentName, Map.currentExits, move)
    return

Map.Untag = (tagname="", roomID=Map.currentRoom) ->
    if tagname == ""
        clearRoomUserDataItem(roomID, "tag")
        Map.echo("Cleared user data for room: "..roomID)
        return
    if roomID
        rooms = {roomID}
    else
        rooms = searchRoomUserData("tag", tagname)
    for id in *rooms
        tags = getRoomUserData(id, "tag")
        tags[tagname] = nil
        setRoomUserData("tag", tags)
        name = getRoomName(roomID)
        Map.echo("Removed tag '"..tagname.."' from room: "..name.." ["..roomID.."]")
    return

storeRoom = 0
Map.Store = ->
  storeRoom = Map.currentRoom
  Map.echo("Storing room ID: " .. storeRoom)
  return

Map.Link = (dir, roomID=storeRoom) ->
  connect_rooms(Map.currentRoom, roomID, dir, reverse_dirs[dir], true)
  return

Map.MarkNoRun = ->
    roomID = Map.currentRoom
    if not getRoomUserData(roomID, "norun") == "true"
        setRoomUserData(roomID, "norun", "true")
    Map.echo("Marked room " .. roomID .. " as NoRun")
    return

Map.ClearNoRun = ->
    roomID = Map.currentRoom
    if getRoomUserData(roomID, "norun") == "true"
        clearRoomUserDataItem(roomID, "norun")
        Map.echo("Cleared norun flag from room")
    return

Map.GetAreaID = (areaName) ->
    areas = getAreaTable!
    for name, id in pairs areas
        if string.lower(name) == string.lower(areaName)
            return name
    return

Map.GetAreaName = (roomID) ->
    areaID = getRoomArea(roomID)
    areaTable = getAreaTable()
    for name, id in pairs(areaTable) do
        if string.lower(id) == string.lower(areaID)
            return name
    return

Map.Tag = (tagname, roomID=Map.currentRoom, multitag=false) ->
    tagname = string.trim(tagname)
    if tagname != ""
        -- Add a new tag to this room
        match = searchRoomUserData("tag", tagname)
        if #match > 0 and not multitag
            Map.echo("Tag ".." is in use by room "..match[1].." to tag multiple rooms use 'map multitag <tag>'")
            return
        else
            setRoomUserData(roomID, "tag", tagname)
            Map.echo("Tagged room " .. roomID .. " as: " .. tagname)
    else
        -- Get the tag for the room and show them
        tags = getRoomUserData(Map.currentRoom, "tag")
        if tags
            Map.echo("Room tagged as:")
            for tag in *tags
                Map.echo(tag)
        else
            Map.echo("Room is not currently tagged")
    return

-- Iterates over all rooms with the given tag and returns the ID of the closest
Map.GetTag = (tagname) ->
    rooms = searchRoomUserData("tag", tagname)
    if rooms
        dist = math.huge
        target = nil
        for room in *rooms
            if room == Map.currentRoom
                cost = 0
                target = room
                return target
            else
                possible, cost = getPath(Map.currentRoom, room)
                if cost < dist
                    dist = cost
                    target = room
        return target
    return

-- walks to the nearest room with the given tag
Map.goto = (tagname) ->
    tagname = string.trim(tagname)
    -- Find a room with the matching tag and get a path to it
    if not Map.currentRoom
        Map.error("I don't know where you are, unable to find a path.")
        return
    if tagname != ""
            target = Map.GetTag(tagname)
            doSpeedWalk(target)
    elseif tonumber(tagname)
        doSpeedWalk(tonumber(tagname))
    else
        Map.echo("Unable to find the room you want.")
    return

capture_move_cmd = (dir,priority) ->
    Map.debug("capture_move_cmd:"..(dir or "dir")..":"..(priority or "priority"))
    dir = dir or "recall"
    dir = string.lower(dir)
    if dir == "clear"
        move_queue = {}
        return
    if table.contains(exitmap,dir) then dir = (exitmap[dir] or dir)
    elseif table.contains({"rec","reca","recal","recall"}, dir) then dir = "recall"
    elseif table.contains({"l","lo","loo","look"}, dir) then dir = "look"
    else dir = false
    if dir
        if priority
            Map.debug("Inserting priority move: "..dir)
            table.insert(move_queue,1,dir)
        else
            Map.debug("Inserting move: "..dir)
            table.insert(move_queue,dir)
    return

--deduplicate_exits = (exits) ->
  --Map.debug("deduplicate_exits")
  --deduplicated_exits = {}
  --for _, v in ipairs(exits)
      --deduplicated_exits[v] = true
  --return table.keys(deduplicated_exits)

capture_room_info = (name, exits) ->
    -- captures room info, and tries to move map to match
    Map.debug("capture_room_exits")
    if name and exits
        Map.prevName = Map.currentName
        Map.prevExits = Map.currentExits
        name = string.trim(name)
        Map.currentName = name
        Map.currentExits = {}
        for w in string.gmatch(exits,"%a+") do
            table.insert(Map.currentExits,w)
    --undupeExits = deduplicate_exits(Map.currentExits)
    --Map.currentExits = undupeExits
    Map.debug(string.format("Exits Captured: %s (%s)",exits, table.concat(Map.currentExits, " ")))
    move_map()
    return

find_area = (name, create) ->
    -- searches for the named area, and creates it if necessary
    areaID = Map.GetAreaID(name)
    if not areaID then areaID = addAreaName(name)
    if not areaID and create
        Map.error("Invalid Area. No such area found, and area could not be added.")
    else
        -- Couldn't find the area, and don't want to create it
        return nil
    Map.currentArea = areaID
    return

Map.LoadMap = (path) ->
    if not path or path == "" then path = mapFolder.."/map.dat"
    loadMap(path)
    if io.exists(mapFolder.."/map_config.dat")
        table.load(mapFolder.."/map_config.dat", Map.config)
    Map.echo("Map reloaded from "..path..".")
    return

Map.Backup = ->
    time = getTime(true)
    path = mapFolder.."/backup/"..time.."_map.dat"
    Map.echo("Making backup copy: "..path)
    saveMap(mapFolder.."/backup/"..time.."_map.dat")

Map.SaveMap = (path) ->
    path = path or mapFolder.."/map.dat"
    Map.Backup!
    Map.echo("Saving map: "..mapFolder.."/map.dat")
    table.save(mapFolder .. "/map_config.dat", Map.config)
    saveMap(mapFolder.."/map.dat")
    return

Map.SetExit = (dir,roomID) ->
    -- used to set unusual exits from the room you are standing in
    if not Map.mapping then return
    roomID = tonumber(roomID)
    if not roomID
        Map.error("Set Exit: Invalid Room ID")
        return
    if not table.contains(exitmap,dir) and not string.starts(dir, "-p ")
        Map.error("Set Exit: Invalid Direction")
        return
    if not string.starts(dir, "-p ")
        if stubmap[exitmap[dir] or dir] <= 12
            exit = short[exitmap[dir] or dir]
            setExit(Map.currentRoom,roomID,exit)
        Map.echo("Exit " .. dir .. " now goes to roomID " .. roomID)
    return

Map.ExportArea = (name) ->
    -- used to export a single area to a file
    areas = getAreaTable()
    name = string.lower(name)
    for k,v in pairs(areas)
        if name == string.lower(k) then name = k
    if not areas[name]
        Map.error("No such area.")
        return
    rooms = getAreaRooms(areas[name])
    tmp = {}
    for k,v in pairs(rooms)
        tmp[v] = v
    rooms = tmp
    tbl = {}
    tbl.name = name
    tbl.rooms = {}
    tbl.exits = {}
    tbl.special = {}
    local rname, exits, stubs, doors, special, portals, door_up, door_down, coords
    for k,v in pairs(rooms)
        rname = getRoomName(v)
        exits = getRoomExits(v)
        stubs = getExitStubs(v)
        doors = getDoors(v)
        special = getSpecialExitsSwap(v)
        portals = getRoomUserData(v,"portals") or ""
        coords = {getRoomCoordinates(v)}
        tbl.rooms[v] = {
            name: rname, :coords, :exits, :stubs, :doors, :door_up,
            :door_down, :door_in, :door_out, :special, :portals,
        }
        tmp: {}
        for k1,v1 in pairs(exits)
            if not table.contains(rooms,v1)
                tmp[k1] = {v1, getRoomName(v1)}
        if not table.is_empty(tmp)
            tbl.exits[v] = tmp
        tmp = {}
        for k1,v1 in pairs(special)
            if not table.contains(rooms,v1)
                tmp[k1] = {v1, getRoomName(v1)}
        if not table.is_empty(tmp)
            tbl.special[v] = tmp
    path = mapFolder.."/saved_areas/"..string.gsub(string.lower(name),"%s","_")..".dat"
    table.save(path,tbl)
    Map.echo("Area " .. name .. " exported to " .. path)
    return

Map.ImportArea = (name) ->
    name = mapFolder .. "/saved_areas/" .. string.gsub(string.lower(name),"%s","_") .. ".dat"
    tbl = {}
    table.load(name,tbl)
    if table.is_empty(tbl)
        Map.error("No file found")
        return
    areas = getAreaTable()
    areaID = areas[tbl.name] or addAreaName(tbl.name)
    rooms = {}
    local ID
    for k,v in pairs(tbl.rooms)
        ID = createRoomID()
        rooms[k] = ID
        addRoom(ID)
        setRoomName(ID,v.name)
        setRoomArea(ID,areaID)
        setRoomCoordinates(ID,unpack(v.coords))
        if type(v.stubs) == "table"
            for i,j in pairs(v.stubs)
                setExitStub(ID,j,true)
        for i,j in pairs(v.doors)
            setDoor(ID,i,j)
        setRoomUserData(ID,"portals",v.portals)
    for k,v in pairs(tbl.rooms)
        for i,j in pairs(v.exits)
            if rooms[j]
                connect_rooms(rooms[k],rooms[j],i)
        for i,j in pairs(v.special)
            if rooms[j]
                addSpecialExit(rooms[k],rooms[j],i)
    for k,v in pairs(tbl.exits)
        for i,j in pairs(v)
            if getRoomName(j[1]) == j[2]
                connect_rooms(rooms[k],j[1],i)
    for k,v in pairs(tbl.special)
        for i,j in pairs(v)
            addSpecialExit(k,j[1],i)
    Map.echo("Area " .. tbl.name .. " imported from " .. name)
    return

Map.SetRecall = ->
    -- assigned the current room to be recall for the current character
    Map.config.recall[Map.character] = Map.currentRoom
    table.save(mapFolder .. "/map_config.dat", Map.config)
    Map.echo("Recall room set to: " .. getRoomName(Map.currentRoom) .. ".")
    return

Map.SetMode = (mode) ->
    -- switches mapping modes
    if not table.contains({"simple","normal","complex"},mode)
        Map.error("Invalid Map Mode, must be 'simple', 'normal', or 'complex'.")
        return
    Map.config.mode = mode
    Map.echo("Current mode set to: " .. mode)
    return

Map.StartMapping = (area_name) ->
    -- starts mapping, and sets the current area to the given one, or uses the current one
    Map.Backup!
    if not Map.currentName
        Map.error("Room detection not yet working, see <yellow>map basics<reset> for guidance.")
        return
    move_queue = {}
    area_name = area_name != "" and area_name or nil
    if Map.currentArea and not area_name
        areas = getAreaTableSwap()
        area_name = areas[Map.currentArea]
    if not area_name
        Map.error("You haven't started mapping yet, how should the first area be called? Set it with: <yellow>start mapping <area name><reset>")
        return
    Map.echo("Now mapping in area: " .. area_name)
    Map.mapping = true
    find_area(area_name, true)
    rooms = find_room(Map.currentName, Map.currentArea)
    if table.is_empty(rooms)
        if Map.currentRoom and getRoomName(Map.currentRoom) == Map.currentName
            Map.SetArea(area_name)
        else
            create_room(Map.currentName, Map.currentExits, nil, {0,0,0})
    elseif Map.currentRoom and Map.currentArea != getRoomArea(Map.currentRoom)
        Map.SetArea(area_name)
    return

Map.StopMapping = ->
    Map.mapping = false
    Map.echo("Mapping off.")
    return

Map.ClearMoves = ->
    commands_in_queue = #move_queue
    move_queue = {}
    Map.echo("Move queue cleared, "..commands_in_queue.." commands removed.")
    return

Map.ShowMoves = ->
    Map.echo("Moves: "..(move_queue and table.concat(move_queue, ', ') or '(queue empty)'))
    return

Map.SetArea = (name) ->
    -- assigns the current room to the area given, creates the area if necessary
    if not Map.mapping then return
    find_area(name, true)
    if Map.currentRoom and getRoomArea(Map.currentRoom) != Map.currentArea
        setRoomArea(Map.currentRoom,Map.currentArea)
        Map.SetRoom(Map.currentRoom)
    return

Map.OpenedDoor = (dir, doorName, status, one_way) ->
    doors = getDoors(Map.currentRoom)
    if not doors[dir] and not doors[short[dir]]
        Map.SetDoor(dir,doorName,status,"no")
    elseif doors[dir] == 2 or doors[short[dir]] == 2 and status == "locked"
        Map.SetDoor(dir,doorName,status,"no")
    return

Map.SetDoor = (dir,doorName,status,one_way) ->
    -- adds a door on a given exit
    Map.echo("Set door: " .. dir .. " " .. doorName)
    if not Map.mapping then return
    if not Map.currentRoom
        Map.error("Make Door: I don't know where you are.")
        return
    dir = exitmap[dir] or dir
    if not stubmap[dir]
        Map.error("Make Door: Invalid direction.")
        return
    status = (status != "" and status) or "closed"
    one_way = (one_way != "" and one_way) or "no"
    if not table.contains({"yes","no"},one_way)
        Map.error("Make Door: Invalid one-way status, must be yes or no.")
        return
    exits = getRoomExits(Map.currentRoom)
    target_room = exits[dir]
    if target_room
        exits = getRoomExits(target_room)
    if one_way == "no" and (target_room and exits[reverse_dirs[dir]] == Map.currentRoom)
        add_door(target_room,reverse_dirs[dir],doorName,status)
    add_door(Map.currentRoom,dir,doorName,status)
    Map.echo(string.format("Adding %s door to the %s", status, dir))
    return

Map.ShiftRoom = (dir) ->
    -- shifts a room around on the map
    if not Map.mapping then return
    dir = exitmap[dir] or (table.contains(exitmap,dir) and dir)
    if not dir
        Map.error("Shift Room: Exit not found")
        return
    x,y,z = getRoomCoordinates(Map.currentRoom)
    dir = stubmap[dir]
    coords = coordmap[dir]
    x = x + coords[1]
    y = y + coords[2]
    z = z + coords[3]
    setRoomCoordinates(Map.currentRoom,x,y,z)
    centerview(Map.currentRoom)
    Map.echo("Shifting room",true)
    return

check_link = (firstID, secondID, dir) ->
    Map.debug("check_link")
    -- check to see if two rooms are connected in a given direction
    if not firstID
        Map.error("Check Link Error: No first ID")
        return
    if not secondID
        Map.error("Check Link Error: No second ID")
        return
    name = getRoomName(firstID)
    exits1 = table.union(getRoomExits(firstID),get_room_stubs(firstID))
    exits2 = table.union(getRoomExits(secondID),get_room_stubs(secondID))
    checkID = exits2[reverse_dirs[dir]]
    exits = {}
    for k,v in pairs(exits1) do
        table.insert(exits,k)
    return checkID and check_room(checkID,name,exits)

Map.MergeRooms = ->
    -- used to combine essentially identical rooms with the same coordinates
    -- typically, these are generated due to mapping errors
    if not Map.mapping then return
    Map.echo("Merging rooms")
    x,y,z = getRoomCoordinates(Map.currentRoom)
    rooms = getRoomsByPosition(Map.currentArea,x,y,z)
    exits, portals, room, cmd, curportals
    room_count = 1
    for k,v in pairs(rooms)
        if v != Map.currentRoom
            if getRoomName(v) == getRoomName(Map.currentRoom)
                room_count = room_count + 1
                for k1,v1 in pairs(getRoomExits(v))
                    setExit(Map.currentRoom,v1,stubmap[k1])
                    exits = getRoomExits(v1)
                    if exits[reverse_dirs[k1]] == v
                        setExit(v1,Map.currentRoom,stubmap[reverse_dirs[k1]])
                for k1,v1 in pairs(getDoors(v))
                    setDoor(Map.currentRoom,k1,v1)
                for k1,v1 in pairs(getSpecialExitsSwap(v))
                    addSpecialExit(Map.currentRoom,v1,k1)
                portals = getRoomUserData(v,"portals") or ""
                if portals != ""
                    portals = string.split(portals,",")
                    for k1,v1 in ipairs(portals)
                        room,cmd = unpack(string.split(v1,":"))
                        addSpecialExit(tonumber(room),Map.currentRoom,cmd)
                        curportals = getRoomUserData(Map.currentRoom,"portals") or ""
                        if not string.find(curportals,room)
                            curportals = curportals .. "," .. room .. ":" .. cmd
                            setRoomUserData(Map.currentRoom,"portals",curportals)
                deleteRoom(v)
    if room_count > 1
        Map.echo(room_count .. " rooms merged")
    return

Map.FindAreaID = (areaname, exact) ->
    areaname = string.lower(areaname)
    list = getAreaTable()

    -- iterate over the list of areas, matching them with substring match.
    -- if we get match a single area, return it's ID, otherwise return
    -- 'false' and a message that there are than one are matches
    returnid, fullareaname, multipleareas = nil, nil, {}
    for area, id in pairs(list)
        if (not exact and string.find(string.lower(area), areaname, 1, true)) or (exact and areaname == string.lower(area))
            returnid = id
            fullareaname = area
            multipleareas[#multipleareas+1] = area
    if #multipleareas == 1
        return returnid, fullareaname
    else
        return nil, nil, multipleareas
    return

Map.EchoRoomList = (areaname, exact) ->
    local areaid, msg, multiples
    listcolor, othercolor = "DarkSlateGrey","LightSlateGray"
    if tonumber(areaname)
        areaid = tonumber(areaname)
        msg = getAreaTableSwap()[areaid]
    else
        areaid, msg, multiples = Map.FindAreaID(areaname, exact)
    if areaid
        roomlist = getAreaRooms(areaid) or {}
        result = {}

        -- obtain a room list for each of the room IDs we got
        getRoomName = getRoomName
        for _, id in pairs(roomlist)
            result[id] = getRoomName(id)

        roomlist[#roomlist+1], roomlist[0] = roomlist[0], nil
        -- sort room IDs so we can display them in order
        table.sort(roomlist)
        echoLink, format, fg, echo = echoLink, string.format, fg, cecho
        -- now display something half-decent looking
        cecho(format("<%s>List of all rooms in <%s>%s<%s> (areaID <%s>%s<%s> - <%s>%d<%s> rooms):\n",
            listcolor, othercolor, msg, listcolor, othercolor, areaid, listcolor, othercolor, #roomlist, listcolor))
        -- use pairs, as we can have gaps between room IDs
        for _, roomid in pairs(roomlist)
            roomname = result[roomid]
            cechoLink(format("<%s>%7s",othercolor,roomid), 'doSpeedWalk('..roomid..')',
                format("Go to %s (%s)", roomid, tostring(roomname)), true)
            cecho(format("<%s>: <%s>%s<%s>.\n", listcolor, othercolor, roomname, listcolor))

    elseif not areaid and #multiples > 0
        allareas = getAreaTable!
        format = string.format
        countrooms = (areaname) ->
            areaid = allareas[areaname]
            allrooms = getAreaRooms(areaid) or {}
            areac = (#allrooms or 0) + (allrooms[0] and 1 or 0)
            return areac
        Map.echo("For which area would you want to list rooms for?")
        for _, areaname in ipairs(multiples)
            echo("  ")
            setUnderline(true)
            cechoLink(format("<%s>%-40s (%d rooms)", othercolor, areaname, countrooms(areaname)),
                'Map.EchoRoomList("'..areaname..'", true)', "Click to view the room list for "..areaname, true)
            setUnderline(false)
            echo("\n")
    else
        Map.echo(string.format("Don't know of any area named '%s'.", areaname))
    resetFormat()
    return

Map.EchoAreaList = ->
    totalroomcount = 0
    rlist = getAreaTableSwap()
    listcolor, othercolor = "DarkSlateGrey","LightSlateGray"

    -- count the amount of rooms in an area, taking care to count the room in the 0th
    -- index as well if there is one
    -- saves the total room count on the side as well
    countrooms = (areaid) ->
        allrooms = getAreaRooms(areaid) or {}
        areac = (#allrooms or 0) + (allrooms[0] and 1 or 0)
        totalroomcount = totalroomcount + areac
        return areac
    getAreaRooms, cecho, fg, echoLink, format = getAreaRooms, cecho, fg, echoLink, string.format
    cecho(format("<%s>List of all areas we know of (click to view room list):\n",listcolor))
    for id = 1,table.maxn(rlist)
        if rlist[id]
            cecho(format("<%s>%7d ", othercolor, id))
            fg(listcolor)
            echoLink(format("%-40s (%d rooms)",rlist[id],countrooms(id)), 'Map.EchoRoomList("'..id..'", true)',
                "View the room list for "..rlist[id], true)
            echo("\n")
    cecho(string.format("<%s>Total amount of rooms in this map: %s\n", listcolor, totalroomcount))
    return

handle_exits = (name, exits) ->
    --Map.debug("handle_exits:"..(name or "")..":"..(exits or "")..":")
    room = Map.room or name
    exits = Map.exits or exits
    exits = string.lower(exits)
    exits = string.gsub(exits,"%a+", exitmap)
    if room
        Map.debug("Room Name Captured: " .. room)
        room = string.trim(room)
        capture_room_info(room, exits)
        Map.room = nil
        Map.exits = nil
    if not Map.currentRoom
        Map.FindMe!
    return

doSpeedWalk = (roomID) ->
    roomID = roomID or speedWalkPath[#speedWalkPath]
    if roomID == Map.currentRoom
        raiseEvent("onSpeedwalkDone")
        Map.walking = false
        return
    getPath(Map.currentRoom, roomID)
    walkPath = speedWalkPath
    walkDirs = speedWalkDir
    if #speedWalkPath == 0
        Map.echo("No path to chosen room found.")
        return
    table.insert(walkPath, 1, Map.currentRoom)
    -- go through dirs to find doors that need opened, etc
    -- add in necessary extra commands to walkDirs table
    pk = 1
    dk = 1
    while true
        id, dir = walkPath[pk], walkDirs[dk]
        if exitmap[dir] or short[dir]
            door = Map.CheckDoors(id, exitmap[dir] or dir)
            status = door and door[dir]
            doorName = getRoomUserData(id, "door." .. dir) or nil
            if status and status > 1
                -- if locked, unlock door
                cmd = ""
                if status == 3
                    cmd = "unlock " .. (exitmap[dir] or dir) .. "." .. doorName
                    -- This screws up the walkPath... need to fix that later
                    table.insert(walkDirs,dk,cmd)
                    dk += 1
                -- if closed, open door
                cmd = "open " .. (exitmap[dir] or dir) .. "." .. doorName
                -- This screws up the walkPath... need to fix that later
                table.insert(walkDirs,dk,cmd)
                dk += 1
        -- go to next direction
        dk += 1
        pk += 1
        if pk > #walkPath then break
        --break if pk > #walkPath

    -- perform walk
    Map.walking = tonumber(speedWalkPath[#speedWalkPath])
    acc = "speedwalk "
    for _,dir in ipairs(walkDirs) do
        if string.match(dir, "unlock") or string.match(dir, "open")
            if acc != "speedwalk " then send(acc)
            send(dir)
            acc = "speedwalk "
        else
            table.insert(move_queue, (exitmap[dir] or dir))
            acc ..= (short[dir] or dir)
    if acc != "speedwalk " then send(acc)
    return

Map.ShowMap = (shown) ->
    if shown then MapC:show!
    else MapC:hide!
    return


Map.SetRoom = (roomID) ->
    -- moves the map to the new room
    if Map.currentRoom != roomID
        Map.prevRoom = Map.currentRoom
        Map.currentRoom = roomID
    if getRoomName(Map.currentRoom) != Map.currentName
        Map.prevName = Map.currentName
        Map.prevExits = Map.currentExits
        Map.currentName = getRoomName(Map.currentRoom)
        Map.currentExits = getRoomExits(Map.currentRoom)
    Map.currentArea = getRoomArea(Map.currentRoom)
    centerview(Map.currentRoom)
    raiseEvent("onMoveMap", Map.currentRoom)
    if Map.walking and Map.currentRoom == Map.walking
        raiseEvent("onSpeedwalkDone")
        Map.walking = false
    return

last_rooms = {}
lost = false
Map.FindMe = (name, exits, dir) ->
    Map.debug("FindMe")
    -- tries to locate the player using the current room name and exits, and if provided, direction of movement
    -- if direction of movement is given, narrows down possibilities using previous room info
    if move != "recall" then move_queue = {}
    check = dir and Map.currentRoom and table.contains(exitmap, dir)
    name = Map.currentName or name
    exits = Map.currentExits or exits
    if not name and not exits
        Map.error("Room not found, complete room name and exit data not available.")
        return
    rooms = find_room(name)
    match_IDs = [id1 for id1, id2 in pairs rooms when check_room(id1, name, exits)]
    rooms = match_IDs
    match_IDs = {}
    if table.size(rooms) > 1 and check
        Map.debug("Found "..table.size(rooms).." possible matches.")
        match_IDs = [id2 for id1, id2 in pairs rooms when check_link(Map.currentRoom, id2, dir)]
    if table.size(match_IDs) == 0
        match_IDs = rooms
    if table.contains(match_IDs,Map.currentRoom)
        match_IDs = {Map.currentRoom}
    if not table.is_empty(match_IDs)
        Map.SetRoom(match_IDs[1])
        Map.debug("Room found, ID: " .. match_IDs[1])
    elseif table.is_empty(match_IDs)
        Map.echo("Room not found in map database")
    return

Map.RetryWalk = ->
    if Map.walking
        move_queue = {}
        doSpeedWalk(Map.walking)
    return

-- ############################################################# EVENT HANDLING
Map.EventHandler = (event, ...) ->
    if event == "onNewRoom"
        handle_exits(arg[1], arg[2])
        if walking
            continue_walk(true)
    elseif event == "onExits"
        if Map.exits and Map.exits != ""
            raiseEvent("onNewRoom")
    elseif event == "onMoveFail"
        Map.debug("onMoveFail")
        table.remove(move_queue,1)
        if Map.walking
            --registerAnonymousEventHandler("onCommandsCleared", "Map.RetryWalk", true)
            send("clear")
    elseif event == "onForcedMove"
        Map.debug("onForcedMove")
        if arg[1] and arg[1] == "pked"
            cmd = "recall"
        else
            cmd = arg[1]
        capture_move_cmd(cmd,arg[2]=="true")
    elseif event == "sysDataSendRequest"
        capture_move_cmd(arg[1])
    elseif event == "mapStop"
        Map.mapping = false
        Map.walking = false
        Map.echo("Mapping and speedwalking stopped.")
    return

registerAnonymousEventHandler("sysDataSendRequest", "Map.EventHandler")
registerAnonymousEventHandler("onMoveFail", "Map.EventHandler")
registerAnonymousEventHandler("onForcedMove", "Map.EventHandler")
registerAnonymousEventHandler("onNewRoom", "Map.EventHandler")
registerAnonymousEventHandler("mapStop", "Map.EventHandler")
registerAnonymousEventHandler("onExits", "Map.EventHandler")
config!
