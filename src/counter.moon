export ^
Counter.salvageGold = 0
Counter.totalGold = 0
Counter.totalExp = 0
Counter.runGold = 0
Counter.runExp = 0
TotalCounterStopWatch = createStopWatch()
RunCounterStopWatch = createStopWatch()
resetStopWatch(TotalCounterStopWatch)
resetStopWatch(RunCounterStopWatch)

Counter.addExp = (exp) ->
    exp = tonumber(exp)
    if exp then
        Counter.totalExp =Counter.totalExp + exp
        Counter.runExp =Counter.runExp + exp

Counter.addSalvageGold = (gold) ->
    Counter.salvageGold =Counter.salvageGold + gold
    Counter.addGold(gold)

Counter.addGold = (gold) ->
    gold = tonumber(gold)
    if gold then
        Counter.totalGold =Counter.totalGold + gold
        Counter.runGold =Counter.runGold + gold

Counter.runGPM = ->
    runTime = getStopWatchTime(RunCounterStopWatch)
    return ((Counter.runGold / runTime) * 60)

Counter.runXPM = ->
    runTime = getStopWatchTime(RunCounterStopWatch)
    return ((Counter.runExp / runTime) * 60)

Counter.totalGPM = ->
    totalTime = getStopWatchTime(TotalCounterStopWatch)
    return ((Counter.totalGold / totalTime) * 60)


Counter.totalXPM = ->
    totalTime = getStopWatchTime(TotalCounterStopWatch)
    return ((Counter.totalExp / totalTime) * 60)

Counter.runTime = ->
    return getStopWatchTime(RunCounterStopWatch)

Counter.totalTime = ->
    return getStopWatchTime(TotalCounterStopWatch)

ResetRunCounter = ->
    Counter.runExp = 0
    Counter.runGold = 1
    resetStopWatch(RunCounterStopWatch)
    return

ResetAllCounters = ->
    Counter.salvageGold = 0
    Counter.totalGold = 0
    Counter.totalExp = 0
    Counter.runGold = 0
    Counter.runExp = 0
    resetStopWatch(TotalCounterStopWatch)
    resetStopWatch(RunCounterStopWatch)
    return

ShowRunStats = ->
    runtime = getStopWatchTime(RunCounterStopWatch)
    runs = runtime % 60
    runm = (runtime / 60) % 60
    runh = (runtime / 3600)
    ppm = Counter.runGPM!/20000
    plat = Counter.runGold/20000
    xpm = Counter.runXPM!/1000000
    xp = Counter.runExp/1000000
    str = string.format("<white>Capped PPM:<gold>%d <white>Plat:<gold>%d <white>XPM:<PaleGreen>%d<white>M XP:<PaleGreen>%d<white>M Time:<green>%02d:%02d:%02d",
        ppm,
        plat,
        xpm,
        xp,
        runh,
        runm,
        runs)
    CaptureChat(str)
    return

ticktime = 59
Tick = ->
    ticktime -= 1
    if ticktime < 0 then DoTick!
    return ticktime

DoTick = ->
    ticktime = 59
    raiseEvent("onTick")
    return

SetTick = (n) ->
    ticktime = 59-n
    return
    
TickSet = ->
    DoTick!
    return
