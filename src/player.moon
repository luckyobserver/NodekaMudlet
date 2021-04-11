export ^

Player = {}
Player.debugging = false
Player.position = "stand"
Player.combo = ""
Player.startCombos = {}
Player.fightCombos = {}
Player.lag = 0
Player.align = 1000
Player.percent = 300
Player.salvage = {}
Player.salvage.minimum = 3
Player.salvage.count = 0
Player.fight = {}
Player.fight.round = 0
Player.fight.roundDamage = 0

Flag = {}
Flag.pk = false
Flag.inventory = false
Flag.prevents = false
Flag.affects = false

Player.buffs = {}
Player.prevents = {}
Player.checkingBuffs = false
Player.attacking = false
Player.attacktarget = ""
Player.skill_status = {}

player_tag = "<112,229,0>(<73,149,0>player<112,229,0>): <255,255,255>"
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

Player.echo = (what, debug, err) ->
    tag = player_tag
    if debug then tag ..= debug_tag
    if err then tag ..= err_tag
    do_echo(what, tag)
    return

Player.error = (what) ->
    Player.echo(what,false,true)
    return

Player.debug = (what) ->
    if Player.debugging
        Player.echo(what,true)
    return

Player.buff_queue = {}
Player.attack_queue = {}
DoAbility = (queue, name, target="") ->
    Player.debug "DoAbility:"..name..":"..target..":"
    if Player.debugging
        display(queue)
    target = string.trim(target)
    if not table.contains(queue, name)
        cmd = CheckAbility(name)
        if cmd
            table.insert(queue, 1, name)
            if target then cmd ..= " "..target
            send(cmd)
            return true
    return false

CheckAbility = (name) ->
    Player.debug "CheckAbility:"..name
    a = Abilities[name]
    -- Check if it has a prevent
    if not a
        Player.debug("Failed to find ability:"..name)
        return false
    if a.prevent and Player.prevents[a.prevent]
        return false
    return AbilityReady(name)

RecallTrain = ->
    Player.debug("RecallTrain")
    Bot.Stop!
    Bot.state = "training"
    expandAlias("prev")
    expandAlias("inventory")
    expandAlias("recall")
    registerAnonymousEventHandler("onRecall", "HandleTraining", true)
    return

DoRecovery = ->
    Player.debug "DoRecovery"
    Bot.Stop!
    send('sleep')
    tempTimer(240, ->
        send('wake')
        Bot.Start!
        return
    )
    return

DoTrain = ->
    Player.debug "DoTrain"
    expandAlias("go train")
    expandAlias("trainCommand")
    return

ResumeRun = ->
    Bot.active = true
    Bot.state = "moving"
    send("look")
    return
--ResumeRun = ->
    --Player.debug "ResumeRun"
    --if Player.percent < 50 then
      --if Bot.areaName ~= "bule" then
        --Bot.Start("bule")
        --return
    --else
      --if Bot.areaName ~= "wlc" then
        --Bot.Start("wlc.se")
        --return
    --Bot.Start('')
    --return

DoSalvage = ->
    Player.debug "DoSalvage"
    expandAlias("go salvage")
    send("follow scrounger")
    return

HandleTraining = ->
    Player.debug "HandleTraining"
    if Bot.state == "training" then ShowRunStats!
    if Player.salvage.count >= Player.salvage.minimum then
        registerAnonymousEventHandler("onPrompt", "DoSalvage", true)
    else
        registerAnonymousEventHandler("onPrompt", "DoTrain", true)
    return

CheckBuffs = ->
    Player.debug "CheckBuffs"
    Player.checkingBuffs = true
    for name in *Player.buffsWanted
        if not Player.buffs[name]
            if DoAbility(Player.buff_queue, name) then return
    Player.checkingBuffs = false
    Player.debug("Checking Buffs Complete")
    raiseEvent("onCheckBuffComplete")
    return

BuffUp = (name) ->
    Player.debug "BuffUp:"..name
    Player.buffs[name] = true
    if Abilities[name] and Abilities[name].prevent
        Player.prevents[Abilities[name].prevent] = true
    raiseEvent("onBuffUp", name)
    if Player.checkingBuffs
        -- The buffs are queued in order, if we see one, then every buff after
        -- it has failed somehow and we will remove them
        ClearAbility(Player.buff_queue, name)
        CheckBuffs!
    return

BuffDown = (name) ->
    Player.debug "BuffDown:"..name
    Player.buffs[name] = false
    return

PreventAvailable = (prevent) ->
    Player.debug "PreventAvailable:"..prevent
    Player.prevents[prevent] = false
    return

Prevented = (prevent) ->
    Player.debug "Prevented:"..prevent
    Player.prevents[prevent] = true
    if Player.attacking and not Flag.prevents
        AbilityFailed!
        return
    for i=1,#Player.buff_queue
        name = Player.buff_queue[i]
        if name and Abilities[name] and Abilities[name].prevent == prevent
            AbilityFailed(name)
            return
    return

AddAttack = (name) ->
    Player.debug "AddAttack:"..name
    for i=1,#Player.startCombo
        if Player.startCombo[i] == name
            Player.startCombo[i] = nil
            break
    for i=1,#Player.fightCombo
        if Player.fightCombo[i] == name
            Player.fightCombo[i] = nil
            break
    table.insert(Player.startCombo, 1, a)
    table.insert(Player.fightCombo, 1, a)
    registerAnonymousEventHandler("onPrompt", "ResetCombo", true)
    return

ResetCombo = ->
    Player.debug "ResetCombo"
    SetCombo(Player.combo)
    return

SetCombo = (c) ->
    Player.debug "SetCombo:"..c
    if Player.startCombos[c] and Player.fightCombos[c] then
        Player.combo = c
        Player.startCombo = table.deepcopy(Player.startCombos[c])
        Player.fightCombo = table.deepcopy(Player.fightCombos[c])
    return

DoAttack = (target="") ->
    Player.debug("DoAttack:"..target..":")
    combo = {}
    Player.attacking = true
    Player.attacktarget = target
    if Player.position == "stand" then
        combo = Player.startCombo
    elseif (Player.position == "fight") then
        combo = Player.fightCombo
    else
        return
    for name in *combo
        if DoAbility(Player.attack_queue, name, target)
            Player.attackAbility = Player.attack_queue[1]
            return
    return

AbilityFailed = (name) ->
    if name == "onAbilityFailed" then name = nil
    Player.debug "AbilityFailed:"..(name or "nil")..":"
    Player.debug "Player.checkingBuffs:"..tostring(Player.checkingBuffs)
    Player.debug "Player.position:"..Player.position
    if Player.checkingBuffs and Player.position != "fight"
        name = name or Player.buff_queue[#Player.buff_queue]
        index = table.index_of(Player.buff_queue, name)
        Player.buff_queue[index] = nil
        Player.debug "Removing queued skill:"..name.." from index:"..index
        registerAnonymousEventHandler("onPrompt", "CheckBuffs", true)
        return
    Player.debug "Player.attacking:"..tostring(Player.attacking)..":"..Player.attacktarget..":"
    if Player.attacking
        name = name or Player.attack_queue[#Player.attack_queue]
        index = table.index_of(Player.attack_queue, name)
        if index
            Player.attack_queue[index] = nil
            Player.debug "Removing queued skill:"..name.." from index:"..index
        DoAttack(Player.attacktarget)
        return
    return
 
DoCombatAttack = ->
    Player.debug "DoCombatAttack"
    if (#Player.attack_queue == 0) and ((Player.fight.round > 1) or (Player.lag == 0)) and (Player.lag < 2000)
        DoAttack()
    return

ClearAbility = (queue, name) ->
    Player.debug "ClearAbility:"..name
    saw = false
    for i=1, #queue
        if saw
            Player.debug("Saw a later ability, clearing:"..queue[i])
            queue[i] = nil
        elseif queue[i] == name
            Player.debug("Saw ability:"..name.." at index "..i)
            saw = true
            queue[i] = nil
    return
SawAttack = (name)->
    Player.debug "SawAttack:"..name..":"
    a = Abilities[name]
    if a
        Player.attacking = false
        Player.attacktarget = ""
        if a.prevent
            Player.prevents[a.prevent] = true
        ClearAbility(Player.attack_queue, name)
        ClearAbility(Player.buff_queue, name)
    return

SawAffects = ->
    Player.debug "SawAffects"
    Flag.affects = true
    Player.buffs = {}
    Player.buff_queue = {}
    registerAnonymousEventHandler("onPrompt", -> Flag.affects = false, true)
    return

CheckAffects = ->
    Player.debug "CheckAffects"
    registerAnonymousEventHandler("onAffects", "SawAffects", true)
    send("affect")
    return

SawPrevents = ->
    Player.debug "SawPrevents"
    Flag.prevents = true
    Player.prevents = {}
    registerAnonymousEventHandler("onPrompt", -> Flag.prevents = false, true)
    return

CheckPrevents = ->
    Player.debug "CheckPrevents"
    registerAnonymousEventHandler("onPrevents", "SawPrevents", true)
    send("prevent")
    return

SkillStatus = ->
    available = "<black:green>"
    active = "<black:LightBlue>"
    prevented = "<black:red>"
    t = available
    s = ""
    for sn, n in pairs Player.skill_status
        t = available
        if Player.buffs[n]
            t = active
        elseif Player.prevents[Abilities[n].prevent]
            t = prevented
        s ..= t..sn.."<black:black> "
    s = string.sub(s,1,-2)
    return s

CommandsCleared = ->
    Player.debug "CommandsCleared"
    Player.buff_queue = {}
    Player.attack_queue = {}
    Player.attacking = false
    Player.attacktarget = ""
    return

ResetAttack = ->
    Player.attack_queue = {}
    Player.attacking = false
    Player.attacktarget = ""
    return

registerAnonymousEventHandler("onExits", "ResetAttack")
registerAnonymousEventHandler("onMobNotHere", "ResetAttack")
registerAnonymousEventHandler("onAbilityFailed", "AbilityFailed")
registerAnonymousEventHandler("onCommandsCleared", "CommandsCleared")
registerAnonymousEventHandler("onMobDeath", "ResetAttack")
registerAnonymousEventHandler("onCombatPrompt", "DoCombatAttack")
registerAnonymousEventHandler("onBotStart", -> SetCombo("run"))
