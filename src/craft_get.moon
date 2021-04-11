getQ = {}
gotQ = {}
get = {}

Craft.GetName = (name) ->
    Craft.debug "GetName:"..name..":"
    if Craft.scraps[name] then return name
    if Craft.gemstone[name] then return name
    cn = [string.lower(n) for n, c in pairs Craft.scraps]
    gn = [string.lower(n) for n, c in pairs Craft.gemstone]
    cl = table.n_union(cn,gn)
    names = [n for n in *cl when string.find(n, name)]
    if Craft.debugging
        display(names)
    if #names > 0
        if (#names > 1)
            Craft.echo "Multiple components match "..name
            for i in *names
                Craft.echo i
            return
        name = names[1]
        return name
    return

Craft.GetAddQ = (amount, t, n using getQ) ->
    Craft.debug "GetAddQ:"..amount..":"..t..":"..n..":"
    n = string.trim(n) or ""
    name = Craft.GetName(n)
    if t == "component" and not Craft.component[name]
        if Craft.gemstone[name] then t = "gemstone"
    Craft.debug "Got name:"..name.." type:"..t
    total = Craft[t][name].count
    if total < amount
        Craft.echo("You have "..total.." "..t.." of "..name.." unable to retrieve "..amount..".")
        return
    if name ~= ""
        table.insert(getQ, {amount, t, name})
        Craft.echo("Added "..amount.." "..t.." of "..name.." to retrieval queue.")
    return

Craft.GetComplete = (using get, getQ) ->
    Craft.debug "GetComplete"
    Craft.bag = nil
    get = {}
    getQ = {}
    Craft.state = ""
    if gotQ and (#gotQ > 0)

        for i in *gotQ
            Craft.echo "Retrieved "..i[1].." "..i[2].." of "..i[3]

        raiseEvent("onCraftGetComplete", gotQ)
    return

get_next_bag = (using get) ->
    Craft.debug "get_next_bag:"..get.want..":"..get.type..":"..get.name..":"
    c = Craft[get.type][get.name]
    b = [{name, count} for name, count in pairs c.bag when count > 0 and name != "inventory"]
    {Craft.bag, amount} = b[1]
    if Craft.bag
        s = ""
        if get.want >= amount then s = "all."

        send "get "..s..get.type.." "..get.name..", "..Craft.bag
    return

do_get = (using gotQ, get) ->
    Craft.debug "do_get"


    if not getQ or (#getQ == 0)
        Craft.GetComplete!
        return

    get.want, get.type, get.name = unpack getQ[1]

    c = Craft[get.type][get.name]
    if c.bag['inventory']
        get.want -= c.bag['inventory']

    if get.want > 0 then
        get_next_bag!
        return
    else
        table.insert(gotQ, getQ[1])
        table.remove(getQ, 1)
        do_get!
        return

    Craft.GetComplete!
    return

Craft.SawGet = (amount, t, name using get, getQ, gotQ) ->
    Craft.debug "SawGet:"..amount..":"..t..":"..name..":"

    -- Mark the bag as not full
    if Craft.bag
        Craft.full[Craft.bag] = false

    -- Add the component to our inventory
    c = Craft[t][name]
    c.bag['inventory'] = (c.bag['inventory'] or 0) + amount

    -- If we know where it came from, remove it from that bag
    if (get.name == name) and (get.type == t) and Craft.bag
        get.want -= amount
        c = Craft[get.type][get.name]
        c.bag[Craft.bag] = (c.bag[Craft.bag] or 0) - amount

        if get.want <= 0
            table.insert(gotQ, getQ[1])
            table.remove(getQ, 1)
            get = {}
            do_get!
        else
            get_next_bag!

    return

Craft.Get = (amount, t, n using getQ, gotQ) ->
    amount = amount or 0
    t = t or ""
    n = n or ""
    Craft.debug("Get:"..amount..":"..t..":"..n..":")
    gotQ = {}

    if n ~= ""
        Craft.GetAddQ(amount, t, n)

    do_get!
    return

Craft.NotInBag = ->
    Craft.debug("NotInBag")
    Craft.GetComplete!
    return

registerAnonymousEventHandler("onNotInBag", "Craft.GetComplete")
registerAnonymousEventHandler("onInventoryFull", "Craft.GetComplete")
