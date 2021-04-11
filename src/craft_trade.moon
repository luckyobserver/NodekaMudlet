trade = {}
tradeQ = {}
gotQ = {}

Craft.tradestatus = false

-- Unique values for each component and tier
high_values = {20,16,15,12,10,9,8,6,5,4,3}
low_values = {5,4,3,6,8,9,10,12,15,16,20}
Craft.startLow = true

-- If the user wants to use Gerahf smiles then make this true
Craft.useSmile = false
Craft.smiles = 0

-- Cost without caring about smiles
normalcost = {8,16,30,48}

-- Cost to get smiles
getSmileCost = {10,20,36,56}
-- Cost if you have smiles
haveSmileCost = {8,15,28,44}

-- Set your smile count and use smiles for trades
Craft.SetSmile = (amount) ->
    Craft.echo "Setting smile amount to: "..amount
    Craft.smiles = amount
    Craft.useSmile = true
    return

-- Clear the trade queue and give queue
Craft.TradeClear = (using trade, gotQ) ->
    trade = {}
    gotQ = {}
    Craft.echo("Cleared trade queues.")
    return

-- Add an item to the trade queue, this queue contains all the items we want
-- to trade for
Craft.TradeAddQ = (a, n using trade) ->
    name = string.trim(n) or ""
    Craft.debug "TradeAddQ:"..a..":"..n..":"
    name = Craft.GetName(name) -- make sure the name is OK
    if not name then return
    amount = a or 1
    total = Craft.component[name].count
    if total <= 0
        Craft.echo("You need at least 1 "..name.." to trade.")
        return
    if name ~= ""
        if not trade.q then trade.q = {}
        -- If the name is here then we add the item to the queue
        for i=1,amount
            table.insert(trade.q, name)
        Craft.echo("Added "..amount.." "..name.." to trade queue.")
    return

-- get_combo is a recursive function that takes the target cost, the number of
-- available components for each value type and returns an array with each
-- index corresponding to the number of components needed of that value
get_combo = (target, available, values, index, combo) ->
    index = index or 1
    combo = combo or [0 for v in *values]

    for i=index,#available do
        if available[i] > 0
            if values[i] == target
                combo[i] += 1
                return combo
            elseif values[i] < target then
                available[i] -= 1
                combo[i] += 1
                result = get_combo(target-values[i], available, values, i, combo)
                if result then return result
                available[i] += 1
                combo[i] -= 1
    return

-- get_keep gets the "keep" value for a given tier - how many comps should you
-- keep as a minimum
get_keep = (c) ->
    keep = Craft.tradeAny[c.tier].keep
    if not keep
        if c.artistry and c.expertise
            keep = 0
        else
            keep = 1
    return keep

-- Iterates through all components that are flagged as tradeable and increments
-- the count in the "available" array by 1 or 2 depending on how many are there
get_available_comps = (values) ->
    Craft.debug("get_available_comps")
    available = [0 for v in *values]
    -- checks trade flag, count, and that the component isn't in the trade queue
    cl = [c for n, c in pairs Craft.component when c.trade and c.count > 0 and not table.contains(trade.q, n)]
    if Craft.debugging
        Craft.debug("Trade queue:")
        display(trade.q)
        Craft.debug("Got tradeable comps:")
        display(cl)
    for c in *cl
        keep = get_keep(c)
        j = table.index_of(values,c.value)
        if c.count > (keep+1)
            Craft.debug(c.name.." is available:"..c.count..":"..c.value)
            available[j] += 2
        elseif c.count > keep
            Craft.debug(c.name.." is available:"..c.count..":"..c.value)
            available[j] += 1
    return available

-- For all the trades in the combo get the actual components for each value
-- and add them to the get queue
queue_trades = (combo, values) ->
    Craft.debug("queue_trades")
    -- Get the target comp, need at least 1 to give to Gerahf
    Craft.debug("Adding target component")
    Craft.GetAddQ(1, "component", trade.name)
    for i=1,#combo
        comps = [c for n,c in pairs Craft.component when c.trade and c.count > 0 and c.value == values[i] and not table.contains(trade.q, n)]
        index = nil
        want = combo[i]
        while combo[i] and (want > 0)
            index, comp = next comps, index
            keep = get_keep(comp)
            if (comp.count > (keep+1)) and (want > 1)
                Craft.debug("Adding trade component")
                Craft.GetAddQ(2, "component", comp.name)
                want -= 2
            elseif comp.count > keep
                Craft.debug("Adding trade component")
                Craft.GetAddQ(1, "component", comp.name)
                want -= 1
    return

-- Start the trade process, need to get our trade comps and our target comp
Craft.GetTrade = (using trade) ->
    Craft.debug "GetTrade"
    trade.index, trade.name = next trade.q, trade.index
    if not trade.name
        -- trade.q is empty, no more trades!
        Craft.TradeComplete!
        return
    Craft.tradestatus = "\n<white>Trades: "..trade.index.." of "..#trade.q.."\n"
    c = Craft.component[trade.name]
    

    -- Figure out the target cost, if we're using smiles or whatever
    cost = normalcost[c.tier]
    if Craft.useSmile
        if Craft.smiles < 2
            Craft.echo("Getting a smile - currently have "..Craft.smiles.." smiles.")
            cost = getSmileCost[c.tier]
        else
            cost = haveSmileCost[c.tier]

    Craft.echo "Trading for "..trade.name.." getting comps worth "..cost
    -- Get the number of available comps for each value type
    values = high_values
    if Craft.startLow then values = low_values
    available = get_available_comps(values)

    -- If we don't have the right comps, add 1 value to the target and try again
    -- Only do this five times... otherwise could get infinite loop
    combo = nil
    i = 1
    while not combo and i < 5 do
        combo = get_combo(cost, available, values)
        if not combo then cost += 1
        i += 1

    -- Can't find a combo that works
    if not combo
        Craft.echo "Unable to complete trade, not enough components available."
        Craft.GetTradeComplete!
        return

    -- Queue up the comps we want
    queue_trades(combo, values)

    -- When we're done getting the comps, do the trade!
    registerAnonymousEventHandler("onCraftGetComplete", "Craft.DoTrade", true)

    -- Start getting comps
    Craft.Get()
    return

-- The #tradec alias calls this - if there is an amount specified then it adds
-- it to the trade queue, if no argument is provided then it starts the trade
-- process
Craft.TradeComps = (amount, name using giveQ) ->
    Craft.debug "Trade"
    gotQ = {}
    trade.person = "gerahf"
    trade.type = "component"
    if name ~= ""
        Craft.TradeAddQ(amount, name)
    else
        trade.index = nil
        Craft.GetTrade!
    return

get_scraps = ->
    acc = {}
    for n, c in pairs Craft.scraps
        if c and (c.name != "jewel fragments")
            if (c.count >= c.cost)
                -- Set it to trade 1, if there is enough to do 2 then go for it
                a = c.cost

                if c.count >= (c.cost*2)
                    a = c.cost*2

                table.insert(acc, {a, n})
    return acc


Craft.TradeScraps = (using gotQ, trade) ->
    trade.type = "scraps"
    trade.person = "stacy"
    gotQ = {}
    trades = get_scraps!

    if #trades > 0
        for i=1,#trades
            Craft.GetAddQ(trades[i][1], "scraps", trades[i][2])

        -- Queued all the scraps up, make sure we actually got some
        registerAnonymousEventHandler "onCraftGetComplete", "Craft.DoTrade", true
        Craft.Get!

    return

Craft.TradeJewels = (n using gotQ, trade) ->
    amount = n or 50
    trade.type = "jewels"
    trade.person = "stacy"
    gotQ = {}
    Craft.GetAddQ(amount, "scraps", "jewel fragments")
    registerAnonymousEventHandler "onCraftGetComplete", "Craft.DoTrade", true
    Craft.Get!
    return

Craft.StacyBegin = ->
    if trade and trade.type == "jewels" and not trade.answered_jewels
        send("answer jewels")
        trade.answered_jewels = true
    elseif trade and (trade.type == "scraps" or (trade.type == "jewels" and trade.answered_jewels))
        Craft.GiveTrade!
    return

Craft.DoTrade = (event, q using gotQ) ->
    Craft.debug "DoTrade:"..#q
    gotQ = q
    if trade
        if #gotQ > 0
            send "follow "..trade.person
        else
            Craft.TradeComplete!
    return

Craft.GerahfHere = ->
    if trade and trade.type == "component"
        send "give component "..trade.name..", gerahf"
        send "answer here"
    return

Craft.GerahfOffer = ->
    if trade and trade.type == "component"
        Craft.GiveTrade!
    return

Craft.AnswerJewels = ->
    if trade
        tempTimer(1, -> registerAnonymousEventHandler "onTradeBegin", "Craft.GiveTrade", true)
        send "answer jewels"
    return

Craft.GiveTrade = ->
    if trade
        if trade.type == "component" then table.remove(gotQ, 1)

        for item in *gotQ
            amount, t, name = unpack item
            for i=1,amount
                send "give "..t.." "..name..", "..trade.person

        if trade.type == "component" then send "answer offer"
        else send "answer begin"
    return

Craft.TraderGave = ->
    if trade and trade.type
        if not trade.gave then trade.gave = 0
        trade.gave += 1
        if (trade.gave == 1 and trade.type != "component") or
                (trade.gave == 2 and trade.type == "component")
            registerAnonymousEventHandler("onPrompt", "Craft.TradeDone", true)
    return

Craft.TradeDone = (using gotQ) ->
    Craft.debug "TradeDone"
    gotQ = {}
    if trade and trade.type
        trade.gave = 0
        if trade.type == "scraps"
            -- See if there are more scraps to trade
            comps = [n for n, c in pairs Craft.scraps when (c.name != "jewel fragments") and (c.count >= c.cost)]
            Craft.debug("#Comps:"..#comps)
            if #comps > 0
                -- If there are, then when we're done putting comps away, trade again
                registerAnonymousEventHandler "onCraftPutComplete", "Craft.TradeScraps", true
        elseif trade.type == "component"
            Craft.tradestatus = "\n<white>Trades: "..trade.index.." of "..#trade.q.."\n"
            Craft.echo("Trade complete "..(#trade.q-trade.index).." of "..#trade.q.." trades left.")
            registerAnonymousEventHandler "onCraftPutComplete", "Craft.GetTrade", true
        Craft.Put!
        return
    trade = false
    return

Craft.TradeComplete = (using trade, gotQ) ->
    trade = {}
    gotQ = {}
    Craft.tradestatus = false
    Craft.echo("Trades complete.")
    raiseEvent("onTradeComplete")
    return

Craft.TradeStop = ->
    trade = {}
    Craft.echo("Stopping Trade.")
    Craft.tradestatus = false
    return

Craft.MoveComp = (amount, t, name) ->
    Craft.debug "MoveComp:"..amount..":"..t..":"..name..":"
    c = Craft[t][name]
    c.count += amount
    c.bag['inventory'] = (c.bag['inventory'] or 0) + amount
    return
