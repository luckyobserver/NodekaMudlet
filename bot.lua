local directions = { }
local hr, hg, hb = unpack(color_table.blue)
Bot.state = ""
Bot.debugging = false
Bot.repop = { }
Bot.playerInRoom = false
Bot.nextRoom = -1
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
local bot_tag = "<112,229,0>(<73,149,0>bot<112,229,0>): <255,255,255>"
local debug_tag = "<255,165,0>(<200,120,0>debug<255,165,0>): <255,255,255>"
local err_tag = "<255,0,0>(<178,34,34>error<255,0,0>): <255,255,255>"
local do_echo
do_echo = function(what, tag)
  moveCursorEnd()
  local curline = getCurrentLine()
  if curline ~= "" then
    echo("\n")
  end
  decho(tag)
  cecho(what)
  echo("\n")
end
Bot.Debug = function()
  Bot.debugging = not Bot.debugging
  local s = "off"
  if Bot.debugging then
    s = "on"
  end
  Bot.echo("Debugging " .. s .. ".")
end
Bot.echo = function(what, debug, err)
  local tag = bot_tag
  if debug then
    tag = tag .. debug_tag
  end
  if err then
    tag = tag .. err_tag
  end
  do_echo(what, tag)
end
Bot.error = function(what)
  Bot.echo(what, false, true)
end
Bot.debug = function(what)
  if Bot.debugging then
    Bot.echo(what, true)
  end
end
local begin
begin = function()
  Bot.debug("begin")
  enableTrigger(Bot.triggerGroups[Bot.areaName])
  if Map.currentRoom == Bot.nextRoom then
    Bot.state = "moving"
    send("look")
  else
    Bot.state = "traveling"
    doSpeedWalk(Bot.nextRoom)
  end
end
local set_start_room
set_start_room = function(startRoom)
  Bot.debug("set_start_room")
  if tonumber(startRoom) then
    Bot.startRoom = tonumber(startRoom)
  else
    local tagNum = Map.GetTag(startRoom)
    if tagNum then
      Bot.startRoom = tagNum
    end
  end
end
local is_runnable
is_runnable = function(r)
  Bot.debug("is_runnable")
  if r then
    local f = getRoomUserData(r, "norun")
    local a = getRoomArea(r)
    local run = (f ~= "true")
    run = (a == Bot.areaID) and run
    run = not table.contains(Bot.visited, r) and run
    return run
  end
  return false
end
local get_valid_rooms
get_valid_rooms = function(areaID)
  Bot.debug("get_valid_rooms")
  local rooms = getAreaRooms(areaID)
  local valid
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #rooms do
      local r = rooms[_index_0]
      if is_runnable(r) then
        _accum_0[_len_0] = r
        _len_0 = _len_0 + 1
      end
    end
    valid = _accum_0
  end
  return valid
end
local add_adjacent
add_adjacent = function(roomID)
  Bot.debug("add_adjacent:" .. roomID .. ":")
  local exits = getRoomExits(roomID)
  local adjacent
  do
    local _accum_0 = { }
    local _len_0 = 1
    for dir, id in pairs(exits) do
      if is_runnable(id) then
        _accum_0[_len_0] = id
        _len_0 = _len_0 + 1
      end
    end
    adjacent = _accum_0
  end
  for _index_0 = 1, #adjacent do
    local id = adjacent[_index_0]
    if not table.contains(Bot.adjacent, id) and not table.contains(Bot.visited, id) then
      table.insert(Bot.adjacent, id)
    end
  end
end
local init
init = function(startRoom)
  Bot.debug("init")
  Bot.visited = { }
  Bot.adjacent = { }
  set_start_room(startRoom)
  Bot.areaID = getRoomArea(Bot.startRoom)
  Bot.areaName = Map.GetAreaName(Bot.startRoom)
  Bot.rooms = get_valid_rooms(Bot.areaID)
  Bot.repop = { }
  Bot.ClearRooms()
end
local step
step = function()
  Bot.debug("step")
  local nxt = table.remove(directions, 1)
  if string.match(nxt, "unlock") then
    send(nxt)
    nxt = table.remove(directions, 1)
  end
  if string.match(nxt, "open") then
    send(nxt)
    nxt = table.remove(directions, 1)
  end
  Bot.state = "moving"
  send(short[nxt] or nxt)
end
local next_room
next_room = function()
  Bot.debug("next_room")
  local contains = table.contains
  local gp = getPath
  local rooms = Bot.rooms
  local visited = Bot.visited
  local adjacent = Bot.adjacent
  local dist = math.huge
  local nr = nil
  for _index_0 = 1, #adjacent do
    local r = adjacent[_index_0]
    local possible, cost = gp(Map.currentRoom, r)
    if cost < dist then
      if cost == 1 then
        return r
      end
      dist = cost
      nr = r
    end
  end
  if not nr and #visited < #rooms then
    Bot.debug("No adjacent rooms, searching full room list.")
    dist = math.huge
    for _index_0 = 1, #rooms do
      local r = rooms[_index_0]
      if not contains(visited, r) then
        local possible, cost = gp(Map.currentRoom, r)
        if cost < dist then
          if cost == 1 then
            return r
          end
          dist = cost
          nr = r
        end
      end
    end
  end
  return nr
end
local get_dirs
get_dirs = function(r)
  Bot.debug("get_dirs")
  local dirs = nil
  getPath(Map.currentRoom, r)
  if r and speedWalkPath and #speedWalkPath > 0 then
    local path = speedWalkPath
    dirs = speedWalkDir
    table.insert(path, 1, Map.currentRoom)
    local k = #dirs
    while k > 0 do
      local id = path[k]
      local dir = dirs[k]
      if exitmap[dir] or short[dir] then
        local door = Map.CheckDoors(id, exitmap[dir] or dir)
        local status = door and door[dir]
        if status and status > 1 then
          local doorName = getRoomUserData(id, "door." .. dir) or ""
          if doorName ~= "" then
            local cmd = ""
            if status == 3 then
              cmd = "unlock " .. (exitmap[dir] or dir) .. "." .. doorName
              table.insert(dirs, k, cmd)
            end
            cmd = "open " .. (exitmap[dir] or dir) .. "." .. doorName
            table.insert(dirs, k, cmd)
          end
        end
      end
      k = k - 1
    end
  end
  return dirs
end
Bot.GetPath = function()
  Bot.debug("GetPath")
  Bot.state = "getting_path"
  local r = next_room()
  if r then
    directions = get_dirs(r)
    if directions and #directions > 0 then
      Bot.nextRoom = r
      step()
      return 
    end
  end
  Bot.Start(Bot.startRoom)
end
local do_move
do_move = function()
  Bot.debug("do_move")
  if Bot.state == "cleared" then
    Bot.state = "doing_move"
    if directions and #directions > 0 then
      step()
    else
      Bot.GetPath()
    end
  end
end
local done_room
done_room = function(id)
  if not table.contains(Bot.visited, id) then
    table.insert(Bot.visited, id)
  end
  add_adjacent(id)
  if table.contains(Bot.adjacent, id) then
    table.remove(Bot.adjacent, table.index_of(Bot.adjacent, id))
  end
  highlightRoom(id, hr, hg, hb, hr, hg, hb, 0.5, 255, 255)
end
Bot.Resume = function()
  directions = { }
  Bot.mobs = { }
  Bot.active = true
  Bot.state = "attacking"
end
Bot.DoneMove = function()
  Bot.debug("DoneMove:" .. Bot.state .. ":" .. Map.currentRoom .. ":" .. Bot.nextRoom .. ":")
  if Bot.state == "traveling" and Map.currentRoom == Bot.nextRoom then
    enableTrigger(Bot.triggerGroups[Bot.areaName])
    Bot.active = true
    Bot.state = "moving"
  end
  if Bot.state == "moving" then
    local cr = Map.currentRoom
    done_room(cr)
    Bot.lastRoom = cr
    Bot.state = "moved"
    Bot.mobs = { }
    Bot.playerInRoom = false
  end
end
Bot.AddMob = function(target, num)
  Bot.debug("AddMob")
  if Bot.state == "moved" then
    for i = 1, num do
      table.insert(Bot.mobs, target)
    end
  end
end
Bot.MobKilled = function()
  Bot.debug("MobKilled:" .. Bot.state)
  if Bot.state == "attacking" or Bot.state == "moving" and not Bot.playerInRoom then
    Bot.state = "killed"
    if #Bot.mobs > 0 then
      table.remove(Bot.mobs, 1)
    end
  end
end
Bot.AttackMob = function()
  Bot.debug("AttackMob:" .. Bot.state)
  if Bot.debugging then
    display(Bot.mobs)
  end
  if Bot.state == "moved" or Bot.state == "killed" then
    if #Bot.mobs > 0 and not Bot.playerInRoom then
      Bot.state = "attacking"
      Bot.target = Bot.mobs[1]
      expandAlias("attack " .. Bot.target, false)
    else
      Bot.state = "cleared"
      do_move()
    end
  end
end
Bot.Start = function(startRoom)
  Bot.debug("Start")
  if not startRoom or startRoom == "" then
    if Bot.state == "stopped" or Bot.state == "training" then
      Bot.nextRoom = Bot.lastRoom
      raiseEvent("onBotStart")
      Bot.active = true
      begin()
      return 
    end
  end
  init(startRoom)
  Bot.nextRoom = Bot.startRoom
  Bot.active = true
  raiseEvent("onBotStart")
  begin()
end
Bot.Stop = function()
  Bot.debug("Stop")
  Bot.active = false
  Bot.state = "stopped"
  raiseEvent("onBotStop")
end
Bot.MoveFail = function()
  Bot.debug("MoveFail")
  if Bot.active and Bot.state == "moving" then
    directions = nil
    done_room(Bot.nextRoom)
    Bot.state = "moved"
    send("clear")
    send("look")
  end
end
Bot.AbilityFailed = function()
  if Bot.state == "attacking" then
    Bot.state = "moved"
  end
end
Bot.ClearRooms = function()
  local rooms, result = getRooms()
  for id, name in pairs(rooms) do
    unHighlightRoom(id)
  end
end
Bot.Repop = function(area)
  if Bot.active then
    CaptureChat("<white>Repop: " .. area)
    if Repoptimer then
      killTimer(Repoptimer)
    end
    local Repoptimer = tempTimer(60, function()
      return Bot.DoRepop()
    end)
  end
end
Bot.DoRepop = function()
  Bot.ClearRooms()
  Bot.visited = { }
  Bot.adjacent = { }
  done_room(Map.currentRoom)
  if Repoptimer then
    killTimer(Repoptimer)
  end
  local Repoptimer = nil
end
Bot.NotHere = function()
  if Bot.active and Bot.state == "attacking" then
    Bot.state = "moving"
    send("look")
  end
end
Bot.Watchdog = function()
  Bot.debug("Bot.Watchdog Reset")
  if Bot.WDTimer then
    killTimer(Bot.WDTimer)
  end
  Bot.WDTimer = tempTimer(60, "Bot.WDFail")
end
Bot.WDFail = function()
  if Bot.active then
    Bot.echo("Watchdog Triggered")
    Bot.Stop()
    Bot.lastRoom = Bot.startRoom
    registerAnonymousEventHandler("onRecall", "Bot.WDRecall", true)
    expandAlias("recall")
  end
end
Bot.WDRecall = function()
  registerAnonymousEventHandler("onPrompt", "Bot.Start", true)
end
registerAnonymousEventHandler("onExits", "Bot.Watchdog")
registerAnonymousEventHandler("onCombatPrompt", "Bot.Watchdog")
registerAnonymousEventHandler("onMobNotHere", "Bot.NotHere")
registerAnonymousEventHandler("onMobDeath", "Bot.MobKilled")
registerAnonymousEventHandler("onPrompt", "Bot.AttackMob")
registerAnonymousEventHandler("onMoveMap", "Bot.DoneMove")
return registerAnonymousEventHandler("onMoveFail", "Bot.MoveFail")
