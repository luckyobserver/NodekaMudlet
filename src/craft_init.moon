export ^

Craft.bags = {}
Craft.baglist = {}
Craft.tradeAny = {}
bagindex = nil
bag = false
in_inventory = false

-- Mark comps that we can trade 
set_trade_comps = ->
    for t=1,4
        g = Craft.tradeAny[t]
        if g
            mats = g.material or {"metal","cloth","wood","leather"}
            comps = g.components or nil
            keep = g.keep or 1

            -- Go through explicitly named comps first
            if comps
                for n in *comps
                    Craft.component[n].trade = true

            -- Then go through groups
            for m in *mats
                r = [c for n, c in pairs Craft.component when (c.material == m) and (c.tier == t)]
                if r
                    for c in *r
                        c.trade = true

Craft.InitInspect = ->
    if not Craft.bags
        Craft.error("Variable Craft.bags is not defined, please create a variable to specify what bags contain comps, example:")
        Craft.error("Craft.bags = {rucksack={1,10}, alpine={10,20}, explorer={1,5}}")
        return
    Craft.state = "initializing"
    
    for n, c in pairs Craft.component
        c.expertise=false
        c.artistry=false
        c.trade=false
        c.count = 0
        c.bag = {}

    for n, s in pairs Craft.scraps
        s.count = 0
        s.bag = {}

    for n, g in pairs Craft.gemstone
        g.count = 0
        g.bag = {}

    set_trade_comps!
    registerAnonymousEventHandler("onCraftCheckComplete", Craft.CheckInventory, true)
    send("quest action, crafting")
    send(" ")
    send(" ")
    return

Craft.InitExpertise = (id) ->
    t = "expertise"
    if id > 1000
        t = "artistry"
        id -= 1000
    c = [c for n, c in pairs Craft.component when c.id == id]
    if c[1]
        c = c[1]
        c[t] = true
    return

reset_bags = (using bag, bagindex) ->
    bag = false
    bagindex = nil
    Craft.baglist = {}
    for bag,rng in pairs Craft.bags
        for i=rng[1],rng[2]
            table.insert(Craft.baglist, i.."."..bag)
    return

bag_check_complete = (using bag, bagindex) ->
    bag = false
    bagindex = nil
    raiseEvent("onCraftCheckComplete")
    return

do_bag = (using bag, bagindex) ->
    bagindex, bag = next(Craft.baglist, bagindex)
    if bag
        registerAnonymousEventHandler("onSawBag", "Craft.SawBag", true)
        send("examine " .. bag)
    else
        bag_check_complete!
    return

Craft.InitBags = ->
    reset_bags!
    do_bag!
    return

Craft.DoneBag = (using bag) ->
    bag = false
    do_bag!
    return

Craft.SawBag = ->
    registerAnonymousEventHandler("onPoolPrompt", "Craft.DoneBag", true)
    return

add_bag = (amount, t, name, b) ->
    Craft.debug "add_bag:"..amount..":"..t..":"..name..":"..b
    c = Craft[t][name]
    if Craft.state == "initializing"
        c.count += amount
    c.bag[b] = (c.bag[b] or 0) + amount
    return

Craft.SawComp = (amount, t, name) ->
    Craft.debug "SawComp:"..amount..":"..t..":"..name..":"
    n = string.trim(name)
    if in_inventory
        add_bag(amount, t, n, "inventory")
    elseif bag
        add_bag(amount, t, n, bag)
    return

Craft.DoneInventory = (using in_inventory) ->
    in_inventory = false
    if Craft.state == "initializing"
       Craft.state = ""
       raiseEvent("onCraftInitComplete")
    return

reset_inventory = ->
    for t in *{"component","scraps","gemstone"}
        for n, c in pairs Craft[t]
            c.bag['inventory'] = 0
    return

Craft.CheckInventory = ->
    send "inventory"
    return

Craft.OnInventory = (using in_inventory) ->
    in_inventory = true
    reset_inventory!
    registerAnonymousEventHandler("onPoolPrompt", "Craft.DoneInventory", true)
    return

Craft.NoBag = (using bag, bagindex) ->
    if Craft.state == "initializing"
        Craft.error("Bag not found, something is wrong.")
        bag = false
        bagindex = nil
        Craft.state = ""
    return

reset_bags!
registerAnonymousEventHandler("onInventory", "Craft.OnInventory")
registerAnonymousEventHandler("onNoBag", "Craft.NoBag")
