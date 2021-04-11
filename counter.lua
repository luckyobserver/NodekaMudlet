Counter.salvageGold = 0
Counter.totalGold = 0
Counter.totalExp = 0
Counter.runGold = 0
Counter.runExp = 0
TotalCounterStopWatch = createStopWatch()
RunCounterStopWatch = createStopWatch()
resetStopWatch(TotalCounterStopWatch)
resetStopWatch(RunCounterStopWatch)
Counter.addExp = function(exp)
  exp = tonumber(exp)
  if exp then
    Counter.totalExp = Counter.totalExp + exp
    Counter.runExp = Counter.runExp + exp
  end
end
Counter.addSalvageGold = function(gold)
  Counter.salvageGold = Counter.salvageGold + gold
  return Counter.addGold(gold)
end
Counter.addGold = function(gold)
  gold = tonumber(gold)
  if gold then
    Counter.totalGold = Counter.totalGold + gold
    Counter.runGold = Counter.runGold + gold
  end
end
Counter.runGPM = function()
  local runTime = getStopWatchTime(RunCounterStopWatch)
  return ((Counter.runGold / runTime) * 60)
end
Counter.runXPM = function()
  local runTime = getStopWatchTime(RunCounterStopWatch)
  return ((Counter.runExp / runTime) * 60)
end
Counter.totalGPM = function()
  local totalTime = getStopWatchTime(TotalCounterStopWatch)
  return ((Counter.totalGold / totalTime) * 60)
end
Counter.totalXPM = function()
  local totalTime = getStopWatchTime(TotalCounterStopWatch)
  return ((Counter.totalExp / totalTime) * 60)
end
Counter.runTime = function()
  return getStopWatchTime(RunCounterStopWatch)
end
Counter.totalTime = function()
  return getStopWatchTime(TotalCounterStopWatch)
end
ResetRunCounter = function()
  Counter.runExp = 0
  Counter.runGold = 1
  resetStopWatch(RunCounterStopWatch)
end
ResetAllCounters = function()
  Counter.salvageGold = 0
  Counter.totalGold = 0
  Counter.totalExp = 0
  Counter.runGold = 0
  Counter.runExp = 0
  resetStopWatch(TotalCounterStopWatch)
  resetStopWatch(RunCounterStopWatch)
end
ShowRunStats = function()
  local runtime = getStopWatchTime(RunCounterStopWatch)
  local runs = runtime % 60
  local runm = (runtime / 60) % 60
  local runh = (runtime / 3600)
  local ppm = Counter.runGPM() / 20000
  local plat = Counter.runGold / 20000
  local xpm = Counter.runXPM() / 1000000
  local xp = Counter.runExp / 1000000
  local str = string.format("<white>Capped PPM:<gold>%d <white>Plat:<gold>%d <white>XPM:<PaleGreen>%d<white>M XP:<PaleGreen>%d<white>M Time:<green>%02d:%02d:%02d", ppm, plat, xpm, xp, runh, runm, runs)
  CaptureChat(str)
end
local ticktime = 59
Tick = function()
  ticktime = ticktime - 1
  if ticktime < 0 then
    DoTick()
  end
  return ticktime
end
DoTick = function()
  ticktime = 59
  raiseEvent("onTick")
end
SetTick = function(n)
  ticktime = 59 - n
end
TickSet = function()
  DoTick()
end
