Craft.full = {}
Craft.bag = nil
put = {}
put.type = nil
put.index = nil
put.sawPut = false
put.sawFull = false


Craft.DoPut = ->
    Craft.debug "Craft.DoPut"
    if put.sawPut and not put.sawFull
        Craft.PutComplete!
        return
    bags = [bag for bag in *Craft.baglist when not Craft.full[bag]]
    if Craft.debugging
        Craft.debug("Got "..#bags.." free bags:")
        if #bags > 0 then display(bags)
    Craft.bag = bags[1]
    if Craft.bag
        put.sawPut = false
        put.sawFull = false
        Craft.debug "Putting:"..Craft.bag
        send "put all."..put.type..", "..Craft.bag
    else
        Craft.debug("No more bags.")
        Craft.PutComplete!
    return

Craft.SawPut = (amount, t, name using put) ->
    Craft.debug "SawPut:"..amount..":"..t..":"..name
    c = Craft[t][name]
    if c.bag['inventory'] then c.bag['inventory'] -= amount
    if Craft.bag
        c = Craft[t][name]
        c.bag[Craft.bag] = (c.bag[Craft.bag] or 0) + amount
        if not put.sawPut
            put.sawPut = true
            registerAnonymousEventHandler "onPoolPrompt", "Craft.DoPut", true
    return

Craft.BagFull = ->
    Craft.debug "BagFull"
    if Craft.bag
        put.sawFull = true
        Craft.full[Craft.bag] = true
        Craft.bag = nil
        if not put.sawPut then
            Craft.DoPut!
    return

Craft.Put = (t="component" using put) ->
    Craft.debug "Put:"..t
    if t == "scraps"
        put.type = "scraps"
    else
        put.type = "component"

    Craft.DoPut!
    return
    
Craft.PutComplete = (using put) ->
    Craft.debug "PutComplete"
    Craft.bag = nil
    put = {}
    raiseEvent "onCraftPutComplete"
    return
