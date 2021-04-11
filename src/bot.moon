export ^

directions = {}

-- Highlight colors
hr, hg, hb = unpack(color_table.blue)

Bot.state = ""
Bot.debugging = false
Bot.repop = {}
Bot.playerInRoom = false
Bot.nextRoom = -1

exitmap = {
    n: 'north', ne: 'northeast', nw: 'northwest',   e: 'east',
    w: 'west',     s: 'south',        se: 'southeast',   sw: 'southwest',
    u: 'up',       d: 'down',         in: 'in',      out: 'out',
    l: 'look'
}

short = {}
for k,v in pairs(exitmap) do
    short[v] = k

bot_tag = "<112,229,0>(<73,149,0>bot<112,229,0>): <255,255,255>"
debug_tag = "<255,165,0>(<200,120,0>debug<255,165,0>): <255,255,255>"
err_tag = "<255,0,0>(<178,34,34>error<255,0,0>): <255,255,255>"

do_echo = (what, tag) ->
    moveCursorEnd!
    curline = getCurrentLine!
    if curline ~= ""
        echo("\n")
    decho(tag)
    cecho(what)
    echo("\n")
    return

Bot.Debug = ->
    Bot.debugging = not Bot.debugging
    s = "off"
    if Bot.debugging then s = "on"
    Bot.echo("Debugging "..s..".")
    return

Bot.echo = (what, debug, err) ->
    tag = bot_tag
    if debug then tag ..= debug_tag
    if err then tag ..= err_tag
    do_echo(what, tag)
    return

Bot.error = (what) ->
    Bot.echo(what,false,true)
    return

Bot.debug = (what) ->
    if Bot.debugging
        Bot.echo(what,true)
    return

begin = ->
    Bot.debug "begin"
    enableTrigger(Bot.triggerGroups[Bot.areaName])
    if Map.currentRoom == Bot.nextRoom
        Bot.state = "moving"
        send "look"
    else
        Bot.state = "traveling"
        doSpeedWalk(Bot.nextRoom)
    return

set_start_room = (startRoom) ->
    Bot.debug "set_start_room"
    if tonumber startRoom
        Bot.startRoom = tonumber startRoom
    else
        tagNum = Map.GetTag(startRoom)
        if tagNum
            Bot.startRoom = tagNum

is_runnable = (r) ->
    Bot.debug "is_runnable"
    if r
        f = getRoomUserData(r, "norun")
        a = getRoomArea(r)
        run = (f != "true")
        run = (a == Bot.areaID) and run
        run = not table.contains(Bot.visited, r) and run
        return run
    return false

get_valid_rooms = (areaID) ->
    Bot.debug "get_valid_rooms"
    rooms = getAreaRooms(areaID)
    valid = [r for r in *rooms when is_runnable(r)]
    return valid

add_adjacent = (roomID) ->
    Bot.debug "add_adjacent:"..roomID..":"
    exits = getRoomExits(roomID)
    adjacent = [id for dir, id in pairs exits when is_runnable(id)]
    for id in *adjacent
        if not table.contains(Bot.adjacent, id) and not table.contains(Bot.visited, id)
            table.insert(Bot.adjacent, id)
    return

init = (startRoom) ->
    Bot.debug "init"
    Bot.visited = {}
    Bot.adjacent = {}
    set_start_room(startRoom)
    Bot.areaID = getRoomArea(Bot.startRoom)
    Bot.areaName = Map.GetAreaName(Bot.startRoom)
    Bot.rooms = get_valid_rooms(Bot.areaID)
    Bot.repop = {}
    Bot.ClearRooms!
    return

step = (using directions) ->
    Bot.debug "step"
    nxt = table.remove(directions, 1)
    if string.match(nxt, "unlock")
        send nxt
        nxt = table.remove(directions,1)
    if string.match(nxt, "open")
        send nxt
        nxt = table.remove(directions,1)
    Bot.state = "moving"
    send short[nxt] or nxt
    return

next_room = ->
    Bot.debug "next_room"
    -- import functions for speed
    contains = table.contains
    gp = getPath
    -- import arrays for speed
    rooms = Bot.rooms
    visited = Bot.visited
    adjacent = Bot.adjacent
    -- initialize vars
    dist = math.huge
    nr = nil
    for r in *adjacent
        possible, cost = gp(Map.currentRoom, r)
        if cost < dist
            if cost == 1 then return r
            dist = cost
            nr = r
    if not nr and #visited < #rooms
        Bot.debug "No adjacent rooms, searching full room list."
        dist = math.huge
        for r in *rooms
            if not contains visited, r
                possible, cost = gp(Map.currentRoom, r)
                if cost < dist
                    if cost == 1 then return r
                    dist = cost
                    nr = r
    return nr

get_dirs = (r) ->
    Bot.debug "get_dirs"
    dirs = nil
    getPath(Map.currentRoom, r)
    if r and speedWalkPath and #speedWalkPath > 0
        path = speedWalkPath
        dirs = speedWalkDir
        table.insert(path, 1, Map.currentRoom)
        k=#dirs
        while k > 0
            id = path[k]
            dir = dirs[k]
            if exitmap[dir] or short[dir]
                door = Map.CheckDoors(id, exitmap[dir] or dir)
                status = door and door[dir]
                if status and status > 1
                    doorName = getRoomUserData(id, "door." .. dir) or ""
                    if doorName != ""
                        cmd = ""
                        if status == 3
                            cmd = "unlock "..(exitmap[dir] or dir).."."..doorName
                            table.insert(dirs,k,cmd)
                        cmd = "open "..(exitmap[dir] or dir).."."..doorName
                        table.insert(dirs,k,cmd)
            k -= 1
    return dirs

Bot.GetPath = (using directions) ->
    Bot.debug "GetPath"
    Bot.state = "getting_path"
    r = next_room!
    if r
        directions = get_dirs(r)
        if directions and #directions > 0
            Bot.nextRoom = r
            step!
            return
    Bot.Start(Bot.startRoom)
    return

do_move = ->
    Bot.debug "do_move"
    if Bot.state == "cleared"
        Bot.state = "doing_move"
        if directions and #directions > 0
            step!
        else
            Bot.GetPath!
    return

done_room = (id) ->
    if not table.contains(Bot.visited, id)
        table.insert(Bot.visited, id)
    add_adjacent(id)
    if table.contains(Bot.adjacent, id)
        table.remove(Bot.adjacent, table.index_of(Bot.adjacent, id))
    highlightRoom(id, hr, hg, hb, hr, hg, hb,0.5,255,255)
    return

Bot.Resume = ->
    directions = {}
    Bot.mobs = {}
    Bot.active = true
    Bot.state = "attacking"
    return

Bot.DoneMove = ->
    Bot.debug "DoneMove:"..Bot.state..":"..Map.currentRoom..":"..Bot.nextRoom..":"
    if Bot.state == "traveling" and Map.currentRoom == Bot.nextRoom
        enableTrigger(Bot.triggerGroups[Bot.areaName])
        Bot.active = true
        Bot.state = "moving"
    if Bot.state == "moving"
        cr = Map.currentRoom
        done_room(cr)
        Bot.lastRoom = cr
        Bot.state = "moved"
        Bot.mobs = {}
        Bot.playerInRoom = false
    return

Bot.AddMob = (target, num) ->
    Bot.debug "AddMob"
    if Bot.state == "moved"
        for i=1,num
            table.insert(Bot.mobs, target)
    return

Bot.MobKilled = ->
    Bot.debug "MobKilled:"..Bot.state
    if Bot.state == "attacking" or Bot.state == "moving" and not Bot.playerInRoom
        Bot.state = "killed"
        if #Bot.mobs > 0
            table.remove(Bot.mobs,1)
    return

Bot.AttackMob = ->
    Bot.debug "AttackMob:"..Bot.state
    if Bot.debugging then display(Bot.mobs)
    if Bot.state == "moved" or Bot.state == "killed"
        if #Bot.mobs > 0 and not Bot.playerInRoom
            Bot.state = "attacking"
            Bot.target = Bot.mobs[1]
            expandAlias("attack "..Bot.target,false)
        else
            Bot.state = "cleared"
            do_move!
    return


Bot.Start = (startRoom) ->
    Bot.debug "Start"
    if not startRoom or startRoom == ""
        if Bot.state == "stopped" or Bot.state == "training"
            Bot.nextRoom = Bot.lastRoom
            raiseEvent("onBotStart")
            Bot.active = true
            begin!
            return
    init(startRoom)
    Bot.nextRoom = Bot.startRoom
    Bot.active = true
    raiseEvent("onBotStart")
    begin!
    return 

Bot.Stop = ->
    Bot.debug "Stop"
    Bot.active = false
    Bot.state = "stopped"
    raiseEvent("onBotStop")
    return

Bot.MoveFail = ->
    Bot.debug "MoveFail"
    if Bot.active and Bot.state == "moving"
        directions = nil
        done_room(Bot.nextRoom)
        Bot.state = "moved"
        send "clear"
        send "look"
    return

Bot.AbilityFailed = ->
    if Bot.state == "attacking"
        Bot.state = "moved"
    return

Bot.ClearRooms = ->
    rooms, result = getRooms!
    for id, name in pairs rooms
        unHighlightRoom(id)
    return

Bot.Repop = (area) ->
    if Bot.active
        CaptureChat("<white>Repop: "..area)
        if Repoptimer then killTimer(Repoptimer)
        Repoptimer = tempTimer(60, -> Bot.DoRepop!)
    return

Bot.DoRepop = ->
    Bot.ClearRooms!
    Bot.visited = {}
    Bot.adjacent = {}
    done_room(Map.currentRoom)
    if Repoptimer then killTimer(Repoptimer)
    Repoptimer = nil
    return

Bot.NotHere = ->
    if Bot.active and Bot.state == "attacking"
        Bot.state = "moving"
        send("look")
    return

Bot.Watchdog = ->
    Bot.debug "Bot.Watchdog Reset"
    if Bot.WDTimer then killTimer(Bot.WDTimer)
    Bot.WDTimer = tempTimer(60, "Bot.WDFail")
    return

Bot.WDFail = ->
    if Bot.active
        Bot.echo "Watchdog Triggered"
        Bot.Stop!
        Bot.lastRoom = Bot.startRoom
        registerAnonymousEventHandler("onRecall", "Bot.WDRecall", true)
        expandAlias("recall")
    return

Bot.WDRecall = ->
    registerAnonymousEventHandler("onPrompt", "Bot.Start", true)
    return

registerAnonymousEventHandler("onExits", "Bot.Watchdog")
registerAnonymousEventHandler("onCombatPrompt", "Bot.Watchdog")
registerAnonymousEventHandler("onMobNotHere", "Bot.NotHere")
registerAnonymousEventHandler("onMobDeath", "Bot.MobKilled")
registerAnonymousEventHandler("onPrompt", "Bot.AttackMob")
registerAnonymousEventHandler("onMoveMap", "Bot.DoneMove")
registerAnonymousEventHandler("onMoveFail", "Bot.MoveFail")
