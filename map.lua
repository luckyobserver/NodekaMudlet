mudlet = mudlet or { }
mudlet.mapper_script = true
Map.walking = false
local profilePath = getMudletHomeDir()
local mapFolder = string.gsub(profilePath, "\\", "/") .. "/NodekaMudlet"
Map.config = {
  mode = "normal",
  max_search_distance = 1,
  debug = false,
  recall = { }
}
local config
config = function()
  if io.exists(mapFolder .. "/map_config.dat") then
    table.load(mapFolder .. "/map_config.dat", Map.config)
  end
  Map.LoadMap()
end
local move_queue = { }
local lines = { }
local walking = false
local exitmap = {
  n = 'north',
  ne = 'northeast',
  nw = 'northwest',
  e = 'east',
  w = 'west',
  s = 'south',
  se = 'southeast',
  sw = 'southwest',
  u = 'up',
  d = 'down',
  ["in"] = 'in',
  out = 'out',
  l = 'look'
}
local short = { }
for k, v in pairs(exitmap) do
  short[v] = k
end
local stubmap = {
  north = 1,
  northeast = 2,
  northwest = 3,
  east = 4,
  west = 5,
  south = 6,
  southeast = 7,
  southwest = 8,
  up = 9,
  down = 10,
  ["in"] = 11,
  out = 12,
  [1] = "north",
  [2] = "northeast",
  [3] = "northwest",
  [4] = "east",
  [5] = "west",
  [6] = "south",
  [7] = "southeast",
  [8] = "southwest",
  [9] = "up",
  [10] = "down",
  [11] = "in",
  [12] = "out"
}
local coordmap = {
  [1] = {
    0,
    1,
    0
  },
  [2] = {
    1,
    1,
    0
  },
  [3] = {
    -1,
    1,
    0
  },
  [4] = {
    1,
    0,
    0
  },
  [5] = {
    -1,
    0,
    0
  },
  [6] = {
    0,
    -1,
    0
  },
  [7] = {
    1,
    -1,
    0
  },
  [8] = {
    -1,
    -1,
    0
  },
  [9] = {
    0,
    0,
    1
  },
  [10] = {
    0,
    0,
    -1
  },
  [11] = {
    0,
    0,
    0
  },
  [12] = {
    0,
    0,
    0
  }
}
local reverse_dirs = {
  north = "south",
  south = "north",
  west = "east",
  east = "west",
  up = "down",
  down = "up",
  northwest = "southeast",
  northeast = "southwest",
  southwest = "northeast",
  southeast = "northwest",
  ["in"] = "out",
  out = "in"
}
local get_room_stubs
get_room_stubs = function(roomID)
  local stubs = getExitStubs(roomID)
  if type(stubs) ~= "table" then
    stubs = { }
  end
  local exits = { }
  for k, v in pairs(stubs) do
    exits[stubmap[v]] = 0
  end
  return exits
end
Map.CheckDoors = function(roomID, exits)
  Map.debug("Map.CheckDoors")
  if type(exits) == "string" then
    exits = {
      exits
    }
  end
  local statuses = { }
  local doors = getDoors(roomID)
  for k, v in pairs(exits) do
    local dir = short[k] or short[v]
    if table.contains({
      'u',
      'd'
    }, dir) then
      dir = exitmap[dir]
    end
    if not doors[dir] or doors[dir] == 0 then
      return false
    else
      statuses[dir] = doors[dir]
    end
  end
  return statuses
end
local check_room
check_room = function(roomID, name, exits, onlyName)
  Map.debug("check_room: " .. (roomID or "none") .. " " .. (name or "none") .. " " .. (table.concat(exits, " ") or "none"))
  if not roomID then
    Map.error("Check Room Error: No ID")
    return true
  end
  if name ~= getRoomName(roomID) then
    Map.error("Unexpected room name: " .. (name or "none") .. " " .. roomID)
    return false
  end
  if onlyName then
    return true
  end
  local t_exits = table.union(getRoomExits(roomID), get_room_stubs(roomID))
  for k, v in ipairs(exits) do
    if short[v] and not table.contains(t_exits, v) then
      return false
    end
    t_exits[v] = nil
  end
  return table.is_empty(t_exits) or Map.CheckDoors(roomID, t_exits)
end
local add_door
add_door = function(roomID, dir, doorName, status)
  dir = exitmap[dir] or dir
  if not table.contains(exitmap, dir) then
    Map.error("Add Door: invalid direction.")
  end
  if type(status) ~= "number" then
    status = assert(table.index_of({
      "none",
      "open",
      "closed",
      "locked"
    }, status), "Add Door: Invald status, must be none, open, closed, or locked") - 1
  end
  local exits = getRoomExits(roomID)
  if exits[dir] then
    if doorName == "" then
      Map.debug("Trying to get door: " .. dir)
      doorName = getRoomUserData(exits[dir], "door." .. reverse_dirs[dir])
    end
  end
  if not table.contains({
    'u',
    'd'
  }, short[dir]) then
    setDoor(roomID, short[dir], status)
    setRoomUserData(roomID, "door." .. short[dir], doorName)
  else
    setDoor(roomID, dir, status)
    setRoomUserData(roomID, "door." .. dir, doorName)
  end
  Map.echo("Adding door: " .. dir .. " " .. doorName .. " " .. status)
end
local find_room
find_room = function(name, area)
  local rooms = searchRoom(name)
  if tonumber(area) then
    area = tonumber(area)
  elseif area then
    area = Map.GetAreaID(area)
  end
  for k, v in pairs(rooms) do
    if string.lower(v) ~= string.lower(name) then
      rooms[k] = nil
    elseif area and getRoomArea(k) ~= area then
      rooms[k] = nil
    end
  end
  return rooms
end
local connect_rooms
connect_rooms = function(ID1, ID2, dir1, dir2, no_check)
  Map.echo("Connect rooms: " .. ID1 .. " " .. ID2 .. " " .. dir1)
  local match = false
  if not ID1 and ID2 and dir1 then
    Map.error("Connect Rooms: Missing Required Arguments.", 2)
  end
  dir2 = dir2 or reverse_dirs[dir1]
  if stubmap[dir1] <= 12 then
    setExit(ID1, ID2, stubmap[dir1])
  else
    setRoomUserData(ID1, "exit " .. dir1, ID2)
  end
  local doors1, doors2 = getDoors(ID1), getDoors(ID2)
  local dstatus1 = doors1[short[dir1]] or doors1[dir1]
  local dstatus2 = doors2[short[dir2]] or doors2[dir2]
  if dstatus1 ~= dstatus2 then
    if not table.contains({
      'u',
      'd'
    }, short[dir]) then
      local doorName = getRoomUserData(ID1, "door." .. short[dir1])
    else
      local doorName = getRoomUserData(ID1, "door." .. dir1)
    end
    if not dstatus1 then
      add_door(ID1, dir1, doorName, dstatus2)
    elseif not dstatus2 then
      add_door(ID2, dir2, doorName, dstatus1)
    end
  end
  if Map.config.mode ~= "complex" then
    local stubs = get_room_stubs(ID2)
    if stubs[dir2] then
      match = true
    end
    if (match or no_check) then
      if stubmap[dir1] <= 12 then
        setExit(ID2, ID1, stubmap[dir2])
      end
    end
  end
end
local create_room
create_room = function(name, exits, dir, coords)
  if not Map.mapping then
    return 
  end
  Map.echo("New Room: " .. name)
  local newID = createRoomID()
  addRoom(newID)
  setRoomArea(newID, Map.currentArea)
  setRoomName(newID, name)
  for k, v in ipairs(exits) do
    if stubmap[v] then
      if stubmap[v] <= 12 then
        setExitStub(newID, stubmap[v], true)
      end
    end
  end
  if dir then
    connect_rooms(Map.currentRoom, newID, dir)
  end
  setRoomCoordinates(newID, unpack(coords))
  local pos_rooms = getRoomsByPosition(Map.currentArea, unpack(coords))
  if Map.config.mode == "simple" then
    local x, y, z = unpack(coords)
    local _ = dx, dy, dz, rooms
    for k, v in ipairs(exits) do
      if stubmap[v] then
        local dx, dy, dz = unpack(coordmap[stubmap[v]])
        local rooms = getRoomsByPosition(Map.currentArea, x + dx, y + dy, z + dz)
        if table.size(rooms) == 1 then
          connect_rooms(newID, rooms[0], v)
        end
      end
    end
  end
  Map.SetRoom(newID)
end
local find_area_limits
find_area_limits = function(areaID)
  if not areaID then
    Map.error("Find Limits: Missing area ID")
    return 
  end
  local rooms = getAreaRooms(areaID)
  local minx, miny, minz = getRoomCoordinates(rooms[0])
  local maxx, maxy, maxz = minx, miny, minz
  local x, y, z
  for k, v in pairs(rooms) do
    x, y, z = getRoomCoordinates(v)
    minx = math.min(x, minx)
    maxx = math.max(x, maxx)
    miny = math.min(y, miny)
    maxy = math.max(y, maxy)
    minz = math.min(z, minz)
    maxz = math.max(z, maxz)
  end
  return minx, maxx, miny, maxy, minz, maxz
end
local find_link
find_link = function(name, exits, dir, max_distance)
  local x, y, z = getRoomCoordinates(Map.currentRoom)
  if Map.mapping and x then
    if max_distance < 1 then
      max_distance = nil
    else
      max_distance = max_distance - 1
    end
    if not stubmap[dir] or not coordmap[stubmap[dir]] then
      return 
    end
    local dx, dy, dz = unpack(coordmap[stubmap[dir]])
    local minx, maxx, miny, maxy, minz, maxz = find_area_limits(Map.currentArea)
    local rooms, match, stubs
    if max_distance then
      minx, maxx = x - max_distance, x + max_distance
      miny, maxy = y - max_distance, y + max_distance
      minz, maxz = z - max_distance, z + max_distance
    end
    while true do
      x, y, z = x + dx, y + dy, z + dz
      rooms = getRoomsByPosition(Map.currentArea, x, y, z)
      if (x > maxx or x < minx or y > maxy or y < miny or z > maxz or z < minz or not table.is_empty(rooms)) then
        break
      end
    end
    for k, v in pairs(rooms) do
      if check_room(v, name, exits, false) then
        match = v
        break
      elseif Map.config.mode == "lazy" and check_room(v, name, exits, true) then
        match = v
        break
      end
    end
    if match then
      connect_rooms(Map.currentRoom, match, dir)
      Map.SetRoom(match)
    else
      x, y, z = getRoomCoordinates(Map.currentRoom)
      create_room(name, exits, dir, {
        x + dx,
        y + dy,
        z + dz
      })
    end
  end
end
local move_map
move_map = function()
  Map.debug("move_map")
  local move = table.remove(move_queue, 1)
  if move then
    Map.debug("move_map: " .. move)
    local exits = (Map.currentRoom and getRoomExits(Map.currentRoom)) or { }
    if move == "recall" and Map.config.recall[Map.character] then
      Map.debug("move_map: recalled")
      Map.SetRoom(Map.config.recall[Map.character])
    elseif move == "look" and Map.currentRoom and check_room(Map.currentRoom, Map.currentName, Map.currentExits) then
      Map.debug("move_map: looking")
      Map.SetRoom(Map.currentRoom)
    else
      if exits[move] and check_room(exits[move], Map.currentName, Map.currentExits) then
        Map.SetRoom(exits[move])
      else
        if Map.mapping and move then
          find_link(Map.currentName, Map.currentExits, move, Map.config.max_search_distance)
        else
          Map.FindMe(Map.currentName, Map.currentExits, move)
        end
      end
    end
  end
end
Map.Untag = function(tagname, roomID)
  if tagname == nil then
    tagname = ""
  end
  if roomID == nil then
    roomID = Map.currentRoom
  end
  if tagname == "" then
    clearRoomUserDataItem(roomID, "tag")
    Map.echo("Cleared user data for room: " .. roomID)
    return 
  end
  if roomID then
    local rooms = {
      roomID
    }
  else
    local rooms = searchRoomUserData("tag", tagname)
  end
  local _list_0 = rooms
  for _index_0 = 1, #_list_0 do
    local id = _list_0[_index_0]
    local tags = getRoomUserData(id, "tag")
    tags[tagname] = nil
    setRoomUserData("tag", tags)
    local name = getRoomName(roomID)
    Map.echo("Removed tag '" .. tagname .. "' from room: " .. name .. " [" .. roomID .. "]")
  end
end
local storeRoom = 0
Map.Store = function()
  storeRoom = Map.currentRoom
  Map.echo("Storing room ID: " .. storeRoom)
end
Map.Link = function(dir, roomID)
  if roomID == nil then
    roomID = storeRoom
  end
  connect_rooms(Map.currentRoom, roomID, dir, reverse_dirs[dir], true)
end
Map.MarkNoRun = function()
  local roomID = Map.currentRoom
  if not getRoomUserData(roomID, "norun") == "true" then
    setRoomUserData(roomID, "norun", "true")
  end
  Map.echo("Marked room " .. roomID .. " as NoRun")
end
Map.ClearNoRun = function()
  local roomID = Map.currentRoom
  if getRoomUserData(roomID, "norun") == "true" then
    clearRoomUserDataItem(roomID, "norun")
    Map.echo("Cleared norun flag from room")
  end
end
Map.GetAreaID = function(areaName)
  local areas = getAreaTable()
  for name, id in pairs(areas) do
    if string.lower(name) == string.lower(areaName) then
      return name
    end
  end
end
Map.GetAreaName = function(roomID)
  local areaID = getRoomArea(roomID)
  local areaTable = getAreaTable()
  for name, id in pairs(areaTable) do
    if string.lower(id) == string.lower(areaID) then
      return name
    end
  end
end
Map.Tag = function(tagname, roomID, multitag)
  if roomID == nil then
    roomID = Map.currentRoom
  end
  if multitag == nil then
    multitag = false
  end
  tagname = string.trim(tagname)
  if tagname ~= "" then
    local match = searchRoomUserData("tag", tagname)
    if #match > 0 and not multitag then
      Map.echo("Tag " .. " is in use by room " .. match[1] .. " to tag multiple rooms use 'map multitag <tag>'")
      return 
    else
      setRoomUserData(roomID, "tag", tagname)
      Map.echo("Tagged room " .. roomID .. " as: " .. tagname)
    end
  else
    local tags = getRoomUserData(Map.currentRoom, "tag")
    if tags then
      Map.echo("Room tagged as:")
      for _index_0 = 1, #tags do
        local tag = tags[_index_0]
        Map.echo(tag)
      end
    else
      Map.echo("Room is not currently tagged")
    end
  end
end
Map.GetTag = function(tagname)
  local rooms = searchRoomUserData("tag", tagname)
  if rooms then
    local dist = math.huge
    local target = nil
    for _index_0 = 1, #rooms do
      local room = rooms[_index_0]
      if room == Map.currentRoom then
        local cost = 0
        target = room
        return target
      else
        local possible, cost = getPath(Map.currentRoom, room)
        if cost < dist then
          dist = cost
          target = room
        end
      end
    end
    return target
  end
end
Map.goto = function(tagname)
  tagname = string.trim(tagname)
  if not Map.currentRoom then
    Map.error("I don't know where you are, unable to find a path.")
    return 
  end
  if tagname ~= "" then
    local target = Map.GetTag(tagname)
    doSpeedWalk(target)
  elseif tonumber(tagname) then
    doSpeedWalk(tonumber(tagname))
  else
    Map.echo("Unable to find the room you want.")
  end
end
local capture_move_cmd
capture_move_cmd = function(dir, priority)
  Map.debug("capture_move_cmd:" .. (dir or "dir") .. ":" .. (priority or "priority"))
  dir = dir or "recall"
  dir = string.lower(dir)
  if dir == "clear" then
    move_queue = { }
    return 
  end
  if table.contains(exitmap, dir) then
    dir = (exitmap[dir] or dir)
  elseif table.contains({
    "rec",
    "reca",
    "recal",
    "recall"
  }, dir) then
    dir = "recall"
  elseif table.contains({
    "l",
    "lo",
    "loo",
    "look"
  }, dir) then
    dir = "look"
  else
    dir = false
  end
  if dir then
    if priority then
      Map.debug("Inserting priority move: " .. dir)
      table.insert(move_queue, 1, dir)
    else
      Map.debug("Inserting move: " .. dir)
      table.insert(move_queue, dir)
    end
  end
end
local capture_room_info
capture_room_info = function(name, exits)
  Map.debug("capture_room_exits")
  if name and exits then
    Map.prevName = Map.currentName
    Map.prevExits = Map.currentExits
    name = string.trim(name)
    Map.currentName = name
    Map.currentExits = { }
    for w in string.gmatch(exits, "%a+") do
      table.insert(Map.currentExits, w)
    end
  end
  Map.debug(string.format("Exits Captured: %s (%s)", exits, table.concat(Map.currentExits, " ")))
  move_map()
end
local find_area
find_area = function(name, create)
  local areaID = Map.GetAreaID(name)
  if not areaID then
    areaID = addAreaName(name)
  end
  if not areaID and create then
    Map.error("Invalid Area. No such area found, and area could not be added.")
  else
    return nil
  end
  Map.currentArea = areaID
end
Map.LoadMap = function(path)
  if not path or path == "" then
    path = mapFolder .. "/map.dat"
  end
  loadMap(path)
  if io.exists(mapFolder .. "/map_config.dat") then
    table.load(mapFolder .. "/map_config.dat", Map.config)
  end
  Map.echo("Map reloaded from " .. path .. ".")
end
Map.Backup = function()
  local time = getTime(true)
  local path = mapFolder .. "/backup/" .. time .. "_map.dat"
  Map.echo("Making backup copy: " .. path)
  return saveMap(mapFolder .. "/backup/" .. time .. "_map.dat")
end
Map.SaveMap = function(path)
  path = path or mapFolder .. "/map.dat"
  Map.Backup()
  Map.echo("Saving map: " .. mapFolder .. "/map.dat")
  table.save(mapFolder .. "/map_config.dat", Map.config)
  saveMap(mapFolder .. "/map.dat")
end
Map.SetExit = function(dir, roomID)
  if not Map.mapping then
    return 
  end
  roomID = tonumber(roomID)
  if not roomID then
    Map.error("Set Exit: Invalid Room ID")
    return 
  end
  if not table.contains(exitmap, dir) and not string.starts(dir, "-p ") then
    Map.error("Set Exit: Invalid Direction")
    return 
  end
  if not string.starts(dir, "-p ") then
    if stubmap[exitmap[dir] or dir] <= 12 then
      local exit = short[exitmap[dir] or dir]
      setExit(Map.currentRoom, roomID, exit)
    end
    Map.echo("Exit " .. dir .. " now goes to roomID " .. roomID)
  end
end
Map.ExportArea = function(name)
  local areas = getAreaTable()
  name = string.lower(name)
  for k, v in pairs(areas) do
    if name == string.lower(k) then
      name = k
    end
  end
  if not areas[name] then
    Map.error("No such area.")
    return 
  end
  local rooms = getAreaRooms(areas[name])
  local tmp = { }
  for k, v in pairs(rooms) do
    tmp[v] = v
  end
  rooms = tmp
  local tbl = { }
  tbl.name = name
  tbl.rooms = { }
  tbl.exits = { }
  tbl.special = { }
  local rname, exits, stubs, doors, special, portals, door_up, door_down, coords
  for k, v in pairs(rooms) do
    rname = getRoomName(v)
    exits = getRoomExits(v)
    stubs = getExitStubs(v)
    doors = getDoors(v)
    special = getSpecialExitsSwap(v)
    portals = getRoomUserData(v, "portals") or ""
    coords = {
      getRoomCoordinates(v)
    }
    tbl.rooms[v] = {
      name = rname,
      coords = coords,
      exits = exits,
      stubs = stubs,
      doors = doors,
      door_up = door_up,
      door_down = door_down,
      door_in = door_in,
      door_out = door_out,
      special = special,
      portals = portals
    }
    local _ = {
      tmp = { }
    }
    for k1, v1 in pairs(exits) do
      if not table.contains(rooms, v1) then
        tmp[k1] = {
          v1,
          getRoomName(v1)
        }
      end
    end
    if not table.is_empty(tmp) then
      tbl.exits[v] = tmp
    end
    tmp = { }
    for k1, v1 in pairs(special) do
      if not table.contains(rooms, v1) then
        tmp[k1] = {
          v1,
          getRoomName(v1)
        }
      end
    end
    if not table.is_empty(tmp) then
      tbl.special[v] = tmp
    end
  end
  local path = mapFolder .. "/saved_areas/" .. string.gsub(string.lower(name), "%s", "_") .. ".dat"
  table.save(path, tbl)
  Map.echo("Area " .. name .. " exported to " .. path)
end
Map.ImportArea = function(name)
  name = mapFolder .. "/saved_areas/" .. string.gsub(string.lower(name), "%s", "_") .. ".dat"
  local tbl = { }
  table.load(name, tbl)
  if table.is_empty(tbl) then
    Map.error("No file found")
    return 
  end
  local areas = getAreaTable()
  local areaID = areas[tbl.name] or addAreaName(tbl.name)
  local rooms = { }
  local ID
  for k, v in pairs(tbl.rooms) do
    ID = createRoomID()
    rooms[k] = ID
    addRoom(ID)
    setRoomName(ID, v.name)
    setRoomArea(ID, areaID)
    setRoomCoordinates(ID, unpack(v.coords))
    if type(v.stubs) == "table" then
      for i, j in pairs(v.stubs) do
        setExitStub(ID, j, true)
      end
    end
    for i, j in pairs(v.doors) do
      setDoor(ID, i, j)
    end
    setRoomUserData(ID, "portals", v.portals)
  end
  for k, v in pairs(tbl.rooms) do
    for i, j in pairs(v.exits) do
      if rooms[j] then
        connect_rooms(rooms[k], rooms[j], i)
      end
    end
    for i, j in pairs(v.special) do
      if rooms[j] then
        addSpecialExit(rooms[k], rooms[j], i)
      end
    end
  end
  for k, v in pairs(tbl.exits) do
    for i, j in pairs(v) do
      if getRoomName(j[1]) == j[2] then
        connect_rooms(rooms[k], j[1], i)
      end
    end
  end
  for k, v in pairs(tbl.special) do
    for i, j in pairs(v) do
      addSpecialExit(k, j[1], i)
    end
  end
  Map.echo("Area " .. tbl.name .. " imported from " .. name)
end
Map.SetRecall = function()
  Map.config.recall[Map.character] = Map.currentRoom
  table.save(mapFolder .. "/map_config.dat", Map.config)
  Map.echo("Recall room set to: " .. getRoomName(Map.currentRoom) .. ".")
end
Map.SetMode = function(mode)
  if not table.contains({
    "simple",
    "normal",
    "complex"
  }, mode) then
    Map.error("Invalid Map Mode, must be 'simple', 'normal', or 'complex'.")
    return 
  end
  Map.config.mode = mode
  Map.echo("Current mode set to: " .. mode)
end
Map.StartMapping = function(area_name)
  Map.Backup()
  if not Map.currentName then
    Map.error("Room detection not yet working, see <yellow>map basics<reset> for guidance.")
    return 
  end
  move_queue = { }
  area_name = area_name ~= "" and area_name or nil
  if Map.currentArea and not area_name then
    local areas = getAreaTableSwap()
    area_name = areas[Map.currentArea]
  end
  if not area_name then
    Map.error("You haven't started mapping yet, how should the first area be called? Set it with: <yellow>start mapping <area name><reset>")
    return 
  end
  Map.echo("Now mapping in area: " .. area_name)
  Map.mapping = true
  find_area(area_name, true)
  local rooms = find_room(Map.currentName, Map.currentArea)
  if table.is_empty(rooms) then
    if Map.currentRoom and getRoomName(Map.currentRoom) == Map.currentName then
      Map.SetArea(area_name)
    else
      create_room(Map.currentName, Map.currentExits, nil, {
        0,
        0,
        0
      })
    end
  elseif Map.currentRoom and Map.currentArea ~= getRoomArea(Map.currentRoom) then
    Map.SetArea(area_name)
  end
end
Map.StopMapping = function()
  Map.mapping = false
  Map.echo("Mapping off.")
end
Map.ClearMoves = function()
  local commands_in_queue = #move_queue
  move_queue = { }
  Map.echo("Move queue cleared, " .. commands_in_queue .. " commands removed.")
end
Map.ShowMoves = function()
  Map.echo("Moves: " .. (move_queue and table.concat(move_queue, ', ') or '(queue empty)'))
end
Map.SetArea = function(name)
  if not Map.mapping then
    return 
  end
  find_area(name, true)
  if Map.currentRoom and getRoomArea(Map.currentRoom) ~= Map.currentArea then
    setRoomArea(Map.currentRoom, Map.currentArea)
    Map.SetRoom(Map.currentRoom)
  end
end
Map.OpenedDoor = function(dir, doorName, status, one_way)
  local doors = getDoors(Map.currentRoom)
  if not doors[dir] and not doors[short[dir]] then
    Map.SetDoor(dir, doorName, status, "no")
  elseif doors[dir] == 2 or doors[short[dir]] == 2 and status == "locked" then
    Map.SetDoor(dir, doorName, status, "no")
  end
end
Map.SetDoor = function(dir, doorName, status, one_way)
  Map.echo("Set door: " .. dir .. " " .. doorName)
  if not Map.mapping then
    return 
  end
  if not Map.currentRoom then
    Map.error("Make Door: I don't know where you are.")
    return 
  end
  dir = exitmap[dir] or dir
  if not stubmap[dir] then
    Map.error("Make Door: Invalid direction.")
    return 
  end
  status = (status ~= "" and status) or "closed"
  one_way = (one_way ~= "" and one_way) or "no"
  if not table.contains({
    "yes",
    "no"
  }, one_way) then
    Map.error("Make Door: Invalid one-way status, must be yes or no.")
    return 
  end
  local exits = getRoomExits(Map.currentRoom)
  local target_room = exits[dir]
  if target_room then
    exits = getRoomExits(target_room)
  end
  if one_way == "no" and (target_room and exits[reverse_dirs[dir]] == Map.currentRoom) then
    add_door(target_room, reverse_dirs[dir], doorName, status)
  end
  add_door(Map.currentRoom, dir, doorName, status)
  Map.echo(string.format("Adding %s door to the %s", status, dir))
end
Map.ShiftRoom = function(dir)
  if not Map.mapping then
    return 
  end
  dir = exitmap[dir] or (table.contains(exitmap, dir) and dir)
  if not dir then
    Map.error("Shift Room: Exit not found")
    return 
  end
  local x, y, z = getRoomCoordinates(Map.currentRoom)
  dir = stubmap[dir]
  local coords = coordmap[dir]
  x = x + coords[1]
  y = y + coords[2]
  z = z + coords[3]
  setRoomCoordinates(Map.currentRoom, x, y, z)
  centerview(Map.currentRoom)
  Map.echo("Shifting room", true)
end
local check_link
check_link = function(firstID, secondID, dir)
  Map.debug("check_link")
  if not firstID then
    Map.error("Check Link Error: No first ID")
    return 
  end
  if not secondID then
    Map.error("Check Link Error: No second ID")
    return 
  end
  local name = getRoomName(firstID)
  local exits1 = table.union(getRoomExits(firstID), get_room_stubs(firstID))
  local exits2 = table.union(getRoomExits(secondID), get_room_stubs(secondID))
  local checkID = exits2[reverse_dirs[dir]]
  local exits = { }
  for k, v in pairs(exits1) do
    table.insert(exits, k)
  end
  return checkID and check_room(checkID, name, exits)
end
Map.MergeRooms = function()
  if not Map.mapping then
    return 
  end
  Map.echo("Merging rooms")
  local x, y, z = getRoomCoordinates(Map.currentRoom)
  local rooms = getRoomsByPosition(Map.currentArea, x, y, z)
  local _ = exits, portals, room, cmd, curportals
  local room_count = 1
  for k, v in pairs(rooms) do
    if v ~= Map.currentRoom then
      if getRoomName(v) == getRoomName(Map.currentRoom) then
        room_count = room_count + 1
        for k1, v1 in pairs(getRoomExits(v)) do
          setExit(Map.currentRoom, v1, stubmap[k1])
          local exits = getRoomExits(v1)
          if exits[reverse_dirs[k1]] == v then
            setExit(v1, Map.currentRoom, stubmap[reverse_dirs[k1]])
          end
        end
        for k1, v1 in pairs(getDoors(v)) do
          setDoor(Map.currentRoom, k1, v1)
        end
        for k1, v1 in pairs(getSpecialExitsSwap(v)) do
          addSpecialExit(Map.currentRoom, v1, k1)
        end
        local portals = getRoomUserData(v, "portals") or ""
        if portals ~= "" then
          portals = string.split(portals, ",")
          for k1, v1 in ipairs(portals) do
            local room, cmd = unpack(string.split(v1, ":"))
            addSpecialExit(tonumber(room), Map.currentRoom, cmd)
            local curportals = getRoomUserData(Map.currentRoom, "portals") or ""
            if not string.find(curportals, room) then
              curportals = curportals .. "," .. room .. ":" .. cmd
              setRoomUserData(Map.currentRoom, "portals", curportals)
            end
          end
        end
        deleteRoom(v)
      end
    end
  end
  if room_count > 1 then
    Map.echo(room_count .. " rooms merged")
  end
end
Map.FindAreaID = function(areaname, exact)
  areaname = string.lower(areaname)
  local list = getAreaTable()
  local returnid, fullareaname, multipleareas = nil, nil, { }
  for area, id in pairs(list) do
    if (not exact and string.find(string.lower(area), areaname, 1, true)) or (exact and areaname == string.lower(area)) then
      returnid = id
      fullareaname = area
      multipleareas[#multipleareas + 1] = area
    end
  end
  if #multipleareas == 1 then
    return returnid, fullareaname
  else
    return nil, nil, multipleareas
  end
end
Map.EchoRoomList = function(areaname, exact)
  local areaid, msg, multiples
  local listcolor, othercolor = "DarkSlateGrey", "LightSlateGray"
  if tonumber(areaname) then
    areaid = tonumber(areaname)
    msg = getAreaTableSwap()[areaid]
  else
    areaid, msg, multiples = Map.FindAreaID(areaname, exact)
  end
  if areaid then
    local roomlist = getAreaRooms(areaid) or { }
    local result = { }
    local getRoomName = getRoomName
    for _, id in pairs(roomlist) do
      result[id] = getRoomName(id)
    end
    roomlist[#roomlist + 1], roomlist[0] = roomlist[0], nil
    table.sort(roomlist)
    local echoLink, format, fg, echo = echoLink, string.format, fg, cecho
    cecho(format("<%s>List of all rooms in <%s>%s<%s> (areaID <%s>%s<%s> - <%s>%d<%s> rooms):\n", listcolor, othercolor, msg, listcolor, othercolor, areaid, listcolor, othercolor, #roomlist, listcolor))
    for _, roomid in pairs(roomlist) do
      local roomname = result[roomid]
      cechoLink(format("<%s>%7s", othercolor, roomid), 'doSpeedWalk(' .. roomid .. ')', format("Go to %s (%s)", roomid, tostring(roomname)), true)
      cecho(format("<%s>: <%s>%s<%s>.\n", listcolor, othercolor, roomname, listcolor))
    end
  elseif not areaid and #multiples > 0 then
    local allareas = getAreaTable()
    local format = string.format
    local countrooms
    countrooms = function(areaname)
      areaid = allareas[areaname]
      local allrooms = getAreaRooms(areaid) or { }
      local areac = (#allrooms or 0) + (allrooms[0] and 1 or 0)
      return areac
    end
    Map.echo("For which area would you want to list rooms for?")
    for _, areaname in ipairs(multiples) do
      echo("  ")
      setUnderline(true)
      cechoLink(format("<%s>%-40s (%d rooms)", othercolor, areaname, countrooms(areaname)), 'Map.EchoRoomList("' .. areaname .. '", true)', "Click to view the room list for " .. areaname, true)
      setUnderline(false)
      echo("\n")
    end
  else
    Map.echo(string.format("Don't know of any area named '%s'.", areaname))
  end
  resetFormat()
end
Map.EchoAreaList = function()
  local totalroomcount = 0
  local rlist = getAreaTableSwap()
  local listcolor, othercolor = "DarkSlateGrey", "LightSlateGray"
  local countrooms
  countrooms = function(areaid)
    local allrooms = getAreaRooms(areaid) or { }
    local areac = (#allrooms or 0) + (allrooms[0] and 1 or 0)
    totalroomcount = totalroomcount + areac
    return areac
  end
  local getAreaRooms, cecho, fg, echoLink, format = getAreaRooms, cecho, fg, echoLink, string.format
  cecho(format("<%s>List of all areas we know of (click to view room list):\n", listcolor))
  for id = 1, table.maxn(rlist) do
    if rlist[id] then
      cecho(format("<%s>%7d ", othercolor, id))
      fg(listcolor)
      echoLink(format("%-40s (%d rooms)", rlist[id], countrooms(id)), 'Map.EchoRoomList("' .. id .. '", true)', "View the room list for " .. rlist[id], true)
      echo("\n")
    end
  end
  cecho(string.format("<%s>Total amount of rooms in this map: %s\n", listcolor, totalroomcount))
end
local handle_exits
handle_exits = function(name, exits)
  local room = Map.room or name
  exits = Map.exits or exits
  exits = string.lower(exits)
  exits = string.gsub(exits, "%a+", exitmap)
  if room then
    Map.debug("Room Name Captured: " .. room)
    room = string.trim(room)
    capture_room_info(room, exits)
    Map.room = nil
    Map.exits = nil
  end
  if not Map.currentRoom then
    Map.FindMe()
  end
end
doSpeedWalk = function(roomID)
  roomID = roomID or speedWalkPath[#speedWalkPath]
  if roomID == Map.currentRoom then
    raiseEvent("onSpeedwalkDone")
    Map.walking = false
    return 
  end
  getPath(Map.currentRoom, roomID)
  local walkPath = speedWalkPath
  local walkDirs = speedWalkDir
  if #speedWalkPath == 0 then
    Map.echo("No path to chosen room found.")
    return 
  end
  table.insert(walkPath, 1, Map.currentRoom)
  local pk = 1
  local dk = 1
  while true do
    local id, dir = walkPath[pk], walkDirs[dk]
    if exitmap[dir] or short[dir] then
      local door = Map.CheckDoors(id, exitmap[dir] or dir)
      local status = door and door[dir]
      local doorName = getRoomUserData(id, "door." .. dir) or nil
      if status and status > 1 then
        local cmd = ""
        if status == 3 then
          cmd = "unlock " .. (exitmap[dir] or dir) .. "." .. doorName
          table.insert(walkDirs, dk, cmd)
          dk = dk + 1
        end
        cmd = "open " .. (exitmap[dir] or dir) .. "." .. doorName
        table.insert(walkDirs, dk, cmd)
        dk = dk + 1
      end
    end
    dk = dk + 1
    pk = pk + 1
    if pk > #walkPath then
      break
    end
  end
  Map.walking = tonumber(speedWalkPath[#speedWalkPath])
  local acc = "speedwalk "
  for _, dir in ipairs(walkDirs) do
    if string.match(dir, "unlock") or string.match(dir, "open") then
      if acc ~= "speedwalk " then
        send(acc)
      end
      send(dir)
      acc = "speedwalk "
    else
      table.insert(move_queue, (exitmap[dir] or dir))
      acc = acc .. (short[dir] or dir)
    end
  end
  if acc ~= "speedwalk " then
    send(acc)
  end
end
Map.ShowMap = function(shown)
  if shown then
    local _ = {
      MapC = show()
    }
  else
    local _ = {
      MapC = hide()
    }
  end
end
Map.SetRoom = function(roomID)
  if Map.currentRoom ~= roomID then
    Map.prevRoom = Map.currentRoom
    Map.currentRoom = roomID
  end
  if getRoomName(Map.currentRoom) ~= Map.currentName then
    Map.prevName = Map.currentName
    Map.prevExits = Map.currentExits
    Map.currentName = getRoomName(Map.currentRoom)
    Map.currentExits = getRoomExits(Map.currentRoom)
  end
  Map.currentArea = getRoomArea(Map.currentRoom)
  centerview(Map.currentRoom)
  raiseEvent("onMoveMap", Map.currentRoom)
  if Map.walking and Map.currentRoom == Map.walking then
    raiseEvent("onSpeedwalkDone")
    Map.walking = false
  end
end
local last_rooms = { }
local lost = false
Map.FindMe = function(name, exits, dir)
  Map.debug("FindMe")
  if move ~= "recall" then
    move_queue = { }
  end
  local check = dir and Map.currentRoom and table.contains(exitmap, dir)
  name = Map.currentName or name
  exits = Map.currentExits or exits
  if not name and not exits then
    Map.error("Room not found, complete room name and exit data not available.")
    return 
  end
  local rooms = find_room(name)
  local match_IDs
  do
    local _accum_0 = { }
    local _len_0 = 1
    for id1, id2 in pairs(rooms) do
      if check_room(id1, name, exits) then
        _accum_0[_len_0] = id1
        _len_0 = _len_0 + 1
      end
    end
    match_IDs = _accum_0
  end
  rooms = match_IDs
  match_IDs = { }
  if table.size(rooms) > 1 and check then
    Map.debug("Found " .. table.size(rooms) .. " possible matches.")
    do
      local _accum_0 = { }
      local _len_0 = 1
      for id1, id2 in pairs(rooms) do
        if check_link(Map.currentRoom, id2, dir) then
          _accum_0[_len_0] = id2
          _len_0 = _len_0 + 1
        end
      end
      match_IDs = _accum_0
    end
  end
  if table.size(match_IDs) == 0 then
    match_IDs = rooms
  end
  if table.contains(match_IDs, Map.currentRoom) then
    match_IDs = {
      Map.currentRoom
    }
  end
  if not table.is_empty(match_IDs) then
    Map.SetRoom(match_IDs[1])
    Map.debug("Room found, ID: " .. match_IDs[1])
  elseif table.is_empty(match_IDs) then
    Map.echo("Room not found in map database")
  end
end
Map.RetryWalk = function()
  if Map.walking then
    move_queue = { }
    doSpeedWalk(Map.walking)
  end
end
Map.EventHandler = function(event, ...)
  if event == "onNewRoom" then
    handle_exits(arg[1], arg[2])
    if walking then
      continue_walk(true)
    end
  elseif event == "onExits" then
    if Map.exits and Map.exits ~= "" then
      raiseEvent("onNewRoom")
    end
  elseif event == "onMoveFail" then
    Map.debug("onMoveFail")
    table.remove(move_queue, 1)
    if Map.walking then
      send("clear")
    end
  elseif event == "onForcedMove" then
    Map.debug("onForcedMove")
    if arg[1] and arg[1] == "pked" then
      local cmd = "recall"
    else
      local cmd = arg[1]
    end
    capture_move_cmd(cmd, arg[2] == "true")
  elseif event == "sysDataSendRequest" then
    capture_move_cmd(arg[1])
  elseif event == "mapStop" then
    Map.mapping = false
    Map.walking = false
    Map.echo("Mapping and speedwalking stopped.")
  end
end
registerAnonymousEventHandler("sysDataSendRequest", "Map.EventHandler")
registerAnonymousEventHandler("onMoveFail", "Map.EventHandler")
registerAnonymousEventHandler("onForcedMove", "Map.EventHandler")
registerAnonymousEventHandler("onNewRoom", "Map.EventHandler")
registerAnonymousEventHandler("mapStop", "Map.EventHandler")
registerAnonymousEventHandler("onExits", "Map.EventHandler")
return config()
