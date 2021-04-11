local trade = { }
local tradeQ = { }
local gotQ = { }
Craft.tradestatus = false
local high_values = {
  20,
  16,
  15,
  12,
  10,
  9,
  8,
  6,
  5,
  4,
  3
}
local low_values = {
  5,
  4,
  3,
  6,
  8,
  9,
  10,
  12,
  15,
  16,
  20
}
Craft.startLow = true
Craft.useSmile = false
Craft.smiles = 0
local normalcost = {
  8,
  16,
  30,
  48
}
local getSmileCost = {
  10,
  20,
  36,
  56
}
local haveSmileCost = {
  8,
  15,
  28,
  44
}
Craft.SetSmile = function(amount)
  Craft.echo("Setting smile amount to: " .. amount)
  Craft.smiles = amount
  Craft.useSmile = true
end
Craft.TradeClear = function()
  trade = { }
  gotQ = { }
  Craft.echo("Cleared trade queues.")
end
Craft.TradeAddQ = function(a, n)
  local name = string.trim(n) or ""
  Craft.debug("TradeAddQ:" .. a .. ":" .. n .. ":")
  name = Craft.GetName(name)
  if not name then
    return 
  end
  local amount = a or 1
  local total = Craft.component[name].count
  if total <= 0 then
    Craft.echo("You need at least 1 " .. name .. " to trade.")
    return 
  end
  if name ~= "" then
    if not trade.q then
      trade.q = { }
    end
    for i = 1, amount do
      table.insert(trade.q, name)
    end
    Craft.echo("Added " .. amount .. " " .. name .. " to trade queue.")
  end
end
local get_combo
get_combo = function(target, available, values, index, combo)
  index = index or 1
  combo = combo or (function()
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #values do
      local v = values[_index_0]
      _accum_0[_len_0] = 0
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
  for i = index, #available do
    if available[i] > 0 then
      if values[i] == target then
        combo[i] = combo[i] + 1
        return combo
      elseif values[i] < target then
        available[i] = available[i] - 1
        combo[i] = combo[i] + 1
        local result = get_combo(target - values[i], available, values, i, combo)
        if result then
          return result
        end
        available[i] = available[i] + 1
        combo[i] = combo[i] - 1
      end
    end
  end
end
local get_keep
get_keep = function(c)
  local keep = Craft.tradeAny[c.tier].keep
  if not keep then
    if c.artistry and c.expertise then
      keep = 0
    else
      keep = 1
    end
  end
  return keep
end
local get_available_comps
get_available_comps = function(values)
  Craft.debug("get_available_comps")
  local available
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #values do
      local v = values[_index_0]
      _accum_0[_len_0] = 0
      _len_0 = _len_0 + 1
    end
    available = _accum_0
  end
  local cl
  do
    local _accum_0 = { }
    local _len_0 = 1
    for n, c in pairs(Craft.component) do
      if c.trade and c.count > 0 and not table.contains(trade.q, n) then
        _accum_0[_len_0] = c
        _len_0 = _len_0 + 1
      end
    end
    cl = _accum_0
  end
  if Craft.debugging then
    Craft.debug("Trade queue:")
    display(trade.q)
    Craft.debug("Got tradeable comps:")
    display(cl)
  end
  for _index_0 = 1, #cl do
    local c = cl[_index_0]
    local keep = get_keep(c)
    local j = table.index_of(values, c.value)
    if c.count > (keep + 1) then
      Craft.debug(c.name .. " is available:" .. c.count .. ":" .. c.value)
      available[j] = available[j] + 2
    elseif c.count > keep then
      Craft.debug(c.name .. " is available:" .. c.count .. ":" .. c.value)
      available[j] = available[j] + 1
    end
  end
  return available
end
local queue_trades
queue_trades = function(combo, values)
  Craft.debug("queue_trades")
  Craft.debug("Adding target component")
  Craft.GetAddQ(1, "component", trade.name)
  for i = 1, #combo do
    local comps
    do
      local _accum_0 = { }
      local _len_0 = 1
      for n, c in pairs(Craft.component) do
        if c.trade and c.count > 0 and c.value == values[i] and not table.contains(trade.q, n) then
          _accum_0[_len_0] = c
          _len_0 = _len_0 + 1
        end
      end
      comps = _accum_0
    end
    local index = nil
    local want = combo[i]
    while combo[i] and (want > 0) do
      local comp
      index, comp = next(comps, index)
      local keep = get_keep(comp)
      if (comp.count > (keep + 1)) and (want > 1) then
        Craft.debug("Adding trade component")
        Craft.GetAddQ(2, "component", comp.name)
        want = want - 2
      elseif comp.count > keep then
        Craft.debug("Adding trade component")
        Craft.GetAddQ(1, "component", comp.name)
        want = want - 1
      end
    end
  end
end
Craft.GetTrade = function()
  Craft.debug("GetTrade")
  trade.index, trade.name = next(trade.q, trade.index)
  if not trade.name then
    Craft.TradeComplete()
    return 
  end
  Craft.tradestatus = "\n<white>Trades: " .. trade.index .. " of " .. #trade.q .. "\n"
  local c = Craft.component[trade.name]
  local cost = normalcost[c.tier]
  if Craft.useSmile then
    if Craft.smiles < 2 then
      Craft.echo("Getting a smile - currently have " .. Craft.smiles .. " smiles.")
      cost = getSmileCost[c.tier]
    else
      cost = haveSmileCost[c.tier]
    end
  end
  Craft.echo("Trading for " .. trade.name .. " getting comps worth " .. cost)
  local values = high_values
  if Craft.startLow then
    values = low_values
  end
  local available = get_available_comps(values)
  local combo = nil
  local i = 1
  while not combo and i < 5 do
    combo = get_combo(cost, available, values)
    if not combo then
      cost = cost + 1
    end
    i = i + 1
  end
  if not combo then
    Craft.echo("Unable to complete trade, not enough components available.")
    Craft.GetTradeComplete()
    return 
  end
  queue_trades(combo, values)
  registerAnonymousEventHandler("onCraftGetComplete", "Craft.DoTrade", true)
  Craft.Get()
end
Craft.TradeComps = function(amount, name)
  Craft.debug("Trade")
  local gotQ = { }
  trade.person = "gerahf"
  trade.type = "component"
  if name ~= "" then
    Craft.TradeAddQ(amount, name)
  else
    trade.index = nil
    Craft.GetTrade()
  end
end
local get_scraps
get_scraps = function()
  local acc = { }
  for n, c in pairs(Craft.scraps) do
    if c and (c.name ~= "jewel fragments") then
      if (c.count >= c.cost) then
        local a = c.cost
        if c.count >= (c.cost * 2) then
          a = c.cost * 2
        end
        table.insert(acc, {
          a,
          n
        })
      end
    end
  end
  return acc
end
Craft.TradeScraps = function()
  trade.type = "scraps"
  trade.person = "stacy"
  gotQ = { }
  local trades = get_scraps()
  if #trades > 0 then
    for i = 1, #trades do
      Craft.GetAddQ(trades[i][1], "scraps", trades[i][2])
    end
    registerAnonymousEventHandler("onCraftGetComplete", "Craft.DoTrade", true)
    Craft.Get()
  end
end
Craft.TradeJewels = function(n)
  local amount = n or 50
  trade.type = "jewels"
  trade.person = "stacy"
  gotQ = { }
  Craft.GetAddQ(amount, "scraps", "jewel fragments")
  registerAnonymousEventHandler("onCraftGetComplete", "Craft.DoTrade", true)
  Craft.Get()
end
Craft.StacyBegin = function()
  if trade and trade.type == "jewels" and not trade.answered_jewels then
    send("answer jewels")
    trade.answered_jewels = true
  elseif trade and (trade.type == "scraps" or (trade.type == "jewels" and trade.answered_jewels)) then
    Craft.GiveTrade()
  end
end
Craft.DoTrade = function(event, q)
  Craft.debug("DoTrade:" .. #q)
  gotQ = q
  if trade then
    if #gotQ > 0 then
      send("follow " .. trade.person)
    else
      Craft.TradeComplete()
    end
  end
end
Craft.GerahfHere = function()
  if trade and trade.type == "component" then
    send("give component " .. trade.name .. ", gerahf")
    send("answer here")
  end
end
Craft.GerahfOffer = function()
  if trade and trade.type == "component" then
    Craft.GiveTrade()
  end
end
Craft.AnswerJewels = function()
  if trade then
    tempTimer(1, function()
      return registerAnonymousEventHandler("onTradeBegin", "Craft.GiveTrade", true)
    end)
    send("answer jewels")
  end
end
Craft.GiveTrade = function()
  if trade then
    if trade.type == "component" then
      table.remove(gotQ, 1)
    end
    for _index_0 = 1, #gotQ do
      local item = gotQ[_index_0]
      local amount, t, name = unpack(item)
      for i = 1, amount do
        send("give " .. t .. " " .. name .. ", " .. trade.person)
      end
    end
    if trade.type == "component" then
      send("answer offer")
    else
      send("answer begin")
    end
  end
end
Craft.TraderGave = function()
  if trade and trade.type then
    if not trade.gave then
      trade.gave = 0
    end
    trade.gave = trade.gave + 1
    if (trade.gave == 1 and trade.type ~= "component") or (trade.gave == 2 and trade.type == "component") then
      registerAnonymousEventHandler("onPrompt", "Craft.TradeDone", true)
    end
  end
end
Craft.TradeDone = function()
  Craft.debug("TradeDone")
  gotQ = { }
  if trade and trade.type then
    trade.gave = 0
    if trade.type == "scraps" then
      local comps
      do
        local _accum_0 = { }
        local _len_0 = 1
        for n, c in pairs(Craft.scraps) do
          if (c.name ~= "jewel fragments") and (c.count >= c.cost) then
            _accum_0[_len_0] = n
            _len_0 = _len_0 + 1
          end
        end
        comps = _accum_0
      end
      Craft.debug("#Comps:" .. #comps)
      if #comps > 0 then
        registerAnonymousEventHandler("onCraftPutComplete", "Craft.TradeScraps", true)
      end
    elseif trade.type == "component" then
      Craft.tradestatus = "\n<white>Trades: " .. trade.index .. " of " .. #trade.q .. "\n"
      Craft.echo("Trade complete " .. (#trade.q - trade.index) .. " of " .. #trade.q .. " trades left.")
      registerAnonymousEventHandler("onCraftPutComplete", "Craft.GetTrade", true)
    end
    Craft.Put()
    return 
  end
  local trade = false
end
Craft.TradeComplete = function()
  trade = { }
  gotQ = { }
  Craft.tradestatus = false
  Craft.echo("Trades complete.")
  raiseEvent("onTradeComplete")
end
Craft.TradeStop = function()
  trade = { }
  Craft.echo("Stopping Trade.")
  Craft.tradestatus = false
end
Craft.MoveComp = function(amount, t, name)
  Craft.debug("MoveComp:" .. amount .. ":" .. t .. ":" .. name .. ":")
  local c = Craft[t][name]
  c.count = c.count + amount
  c.bag['inventory'] = (c.bag['inventory'] or 0) + amount
end
