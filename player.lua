Player = { }
Player.debugging = false
Player.position = "stand"
Player.combo = ""
Player.startCombos = { }
Player.fightCombos = { }
Player.lag = 0
Player.align = 1000
Player.percent = 300
Player.salvage = { }
Player.salvage.minimum = 3
Player.salvage.count = 0
Player.fight = { }
Player.fight.round = 0
Player.fight.roundDamage = 0
Flag = { }
Flag.pk = false
Flag.inventory = false
Flag.prevents = false
Flag.affects = false
Player.buffs = { }
Player.prevents = { }
Player.checkingBuffs = false
Player.attacking = false
Player.attacktarget = ""
Player.skill_status = { }
local player_tag = "<112,229,0>(<73,149,0>player<112,229,0>): <255,255,255>"
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
Player.echo = function(what, debug, err)
  local tag = player_tag
  if debug then
    tag = tag .. debug_tag
  end
  if err then
    tag = tag .. err_tag
  end
  do_echo(what, tag)
end
Player.error = function(what)
  Player.echo(what, false, true)
end
Player.debug = function(what)
  if Player.debugging then
    Player.echo(what, true)
  end
end
Player.buff_queue = { }
Player.attack_queue = { }
DoAbility = function(queue, name, target)
  if target == nil then
    target = ""
  end
  Player.debug("DoAbility:" .. name .. ":" .. target .. ":")
  if Player.debugging then
    display(queue)
  end
  target = string.trim(target)
  if not table.contains(queue, name) then
    local cmd = CheckAbility(name)
    if cmd then
      table.insert(queue, 1, name)
      if target then
        cmd = cmd .. (" " .. target)
      end
      send(cmd)
      return true
    end
  end
  return false
end
CheckAbility = function(name)
  Player.debug("CheckAbility:" .. name)
  local a = Abilities[name]
  if not a then
    Player.debug("Failed to find ability:" .. name)
    return false
  end
  if a.prevent and Player.prevents[a.prevent] then
    return false
  end
  return AbilityReady(name)
end
RecallTrain = function()
  Player.debug("RecallTrain")
  Bot.Stop()
  Bot.state = "training"
  expandAlias("prev")
  expandAlias("inventory")
  expandAlias("recall")
  registerAnonymousEventHandler("onRecall", "HandleTraining", true)
end
DoRecovery = function()
  Player.debug("DoRecovery")
  Bot.Stop()
  send('sleep')
  tempTimer(240, function()
    send('wake')
    Bot.Start()
  end)
end
DoTrain = function()
  Player.debug("DoTrain")
  expandAlias("go train")
  expandAlias("trainCommand")
end
ResumeRun = function()
  Bot.active = true
  Bot.state = "moving"
  send("look")
end
DoSalvage = function()
  Player.debug("DoSalvage")
  expandAlias("go salvage")
  send("follow scrounger")
end
HandleTraining = function()
  Player.debug("HandleTraining")
  if Bot.state == "training" then
    ShowRunStats()
  end
  if Player.salvage.count >= Player.salvage.minimum then
    registerAnonymousEventHandler("onPrompt", "DoSalvage", true)
  else
    registerAnonymousEventHandler("onPrompt", "DoTrain", true)
  end
end
CheckBuffs = function()
  Player.debug("CheckBuffs")
  Player.checkingBuffs = true
  local _list_0 = Player.buffsWanted
  for _index_0 = 1, #_list_0 do
    local name = _list_0[_index_0]
    if not Player.buffs[name] then
      if DoAbility(Player.buff_queue, name) then
        return 
      end
    end
  end
  Player.checkingBuffs = false
  Player.debug("Checking Buffs Complete")
  raiseEvent("onCheckBuffComplete")
end
BuffUp = function(name)
  Player.debug("BuffUp:" .. name)
  Player.buffs[name] = true
  if Abilities[name] and Abilities[name].prevent then
    Player.prevents[Abilities[name].prevent] = true
  end
  raiseEvent("onBuffUp", name)
  if Player.checkingBuffs then
    ClearAbility(Player.buff_queue, name)
    CheckBuffs()
  end
end
BuffDown = function(name)
  Player.debug("BuffDown:" .. name)
  Player.buffs[name] = false
end
PreventAvailable = function(prevent)
  Player.debug("PreventAvailable:" .. prevent)
  Player.prevents[prevent] = false
end
Prevented = function(prevent)
  Player.debug("Prevented:" .. prevent)
  Player.prevents[prevent] = true
  if Player.attacking and not Flag.prevents then
    AbilityFailed()
    return 
  end
  for i = 1, #Player.buff_queue do
    local name = Player.buff_queue[i]
    if name and Abilities[name] and Abilities[name].prevent == prevent then
      AbilityFailed(name)
      return 
    end
  end
end
AddAttack = function(name)
  Player.debug("AddAttack:" .. name)
  for i = 1, #Player.startCombo do
    if Player.startCombo[i] == name then
      Player.startCombo[i] = nil
      break
    end
  end
  for i = 1, #Player.fightCombo do
    if Player.fightCombo[i] == name then
      Player.fightCombo[i] = nil
      break
    end
  end
  table.insert(Player.startCombo, 1, a)
  table.insert(Player.fightCombo, 1, a)
  registerAnonymousEventHandler("onPrompt", "ResetCombo", true)
end
ResetCombo = function()
  Player.debug("ResetCombo")
  SetCombo(Player.combo)
end
SetCombo = function(c)
  Player.debug("SetCombo:" .. c)
  if Player.startCombos[c] and Player.fightCombos[c] then
    Player.combo = c
    Player.startCombo = table.deepcopy(Player.startCombos[c])
    Player.fightCombo = table.deepcopy(Player.fightCombos[c])
  end
end
DoAttack = function(target)
  if target == nil then
    target = ""
  end
  Player.debug("DoAttack:" .. target .. ":")
  local combo = { }
  Player.attacking = true
  Player.attacktarget = target
  if Player.position == "stand" then
    combo = Player.startCombo
  elseif (Player.position == "fight") then
    combo = Player.fightCombo
  else
    return 
  end
  for _index_0 = 1, #combo do
    local name = combo[_index_0]
    if DoAbility(Player.attack_queue, name, target) then
      Player.attackAbility = Player.attack_queue[1]
      return 
    end
  end
end
AbilityFailed = function(name)
  if name == "onAbilityFailed" then
    name = nil
  end
  Player.debug("AbilityFailed:" .. (name or "nil") .. ":")
  Player.debug("Player.checkingBuffs:" .. tostring(Player.checkingBuffs))
  Player.debug("Player.position:" .. Player.position)
  if Player.checkingBuffs and Player.position ~= "fight" then
    name = name or Player.buff_queue[#Player.buff_queue]
    local index = table.index_of(Player.buff_queue, name)
    Player.buff_queue[index] = nil
    Player.debug("Removing queued skill:" .. name .. " from index:" .. index)
    registerAnonymousEventHandler("onPrompt", "CheckBuffs", true)
    return 
  end
  Player.debug("Player.attacking:" .. tostring(Player.attacking) .. ":" .. Player.attacktarget .. ":")
  if Player.attacking then
    name = name or Player.attack_queue[#Player.attack_queue]
    local index = table.index_of(Player.attack_queue, name)
    if index then
      Player.attack_queue[index] = nil
      Player.debug("Removing queued skill:" .. name .. " from index:" .. index)
    end
    DoAttack(Player.attacktarget)
    return 
  end
end
DoCombatAttack = function()
  Player.debug("DoCombatAttack")
  if (#Player.attack_queue == 0) and ((Player.fight.round > 1) or (Player.lag == 0)) and (Player.lag < 2000) then
    DoAttack()
  end
end
ClearAbility = function(queue, name)
  Player.debug("ClearAbility:" .. name)
  local saw = false
  for i = 1, #queue do
    if saw then
      Player.debug("Saw a later ability, clearing:" .. queue[i])
      queue[i] = nil
    elseif queue[i] == name then
      Player.debug("Saw ability:" .. name .. " at index " .. i)
      saw = true
      queue[i] = nil
    end
  end
end
SawAttack = function(name)
  Player.debug("SawAttack:" .. name .. ":")
  local a = Abilities[name]
  if a then
    Player.attacking = false
    Player.attacktarget = ""
    if a.prevent then
      Player.prevents[a.prevent] = true
    end
    ClearAbility(Player.attack_queue, name)
    ClearAbility(Player.buff_queue, name)
  end
end
SawAffects = function()
  Player.debug("SawAffects")
  Flag.affects = true
  Player.buffs = { }
  Player.buff_queue = { }
  registerAnonymousEventHandler("onPrompt", function()
    Flag.affects = false, true
  end)
end
CheckAffects = function()
  Player.debug("CheckAffects")
  registerAnonymousEventHandler("onAffects", "SawAffects", true)
  send("affect")
end
SawPrevents = function()
  Player.debug("SawPrevents")
  Flag.prevents = true
  Player.prevents = { }
  registerAnonymousEventHandler("onPrompt", function()
    Flag.prevents = false, true
  end)
end
CheckPrevents = function()
  Player.debug("CheckPrevents")
  registerAnonymousEventHandler("onPrevents", "SawPrevents", true)
  send("prevent")
end
SkillStatus = function()
  local available = "<black:green>"
  local active = "<black:LightBlue>"
  local prevented = "<black:red>"
  local t = available
  local s = ""
  for sn, n in pairs(Player.skill_status) do
    t = available
    if Player.buffs[n] then
      t = active
    elseif Player.prevents[Abilities[n].prevent] then
      t = prevented
    end
    s = s .. (t .. sn .. "<black:black> ")
  end
  s = string.sub(s, 1, -2)
  return s
end
CommandsCleared = function()
  Player.debug("CommandsCleared")
  Player.buff_queue = { }
  Player.attack_queue = { }
  Player.attacking = false
  Player.attacktarget = ""
end
ResetAttack = function()
  Player.attack_queue = { }
  Player.attacking = false
  Player.attacktarget = ""
end
registerAnonymousEventHandler("onExits", "ResetAttack")
registerAnonymousEventHandler("onMobNotHere", "ResetAttack")
registerAnonymousEventHandler("onAbilityFailed", "AbilityFailed")
registerAnonymousEventHandler("onCommandsCleared", "CommandsCleared")
registerAnonymousEventHandler("onMobDeath", "ResetAttack")
registerAnonymousEventHandler("onCombatPrompt", "DoCombatAttack")
return registerAnonymousEventHandler("onBotStart", function()
  return SetCombo("run")
end)
