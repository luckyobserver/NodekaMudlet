Craft.GetName = (name) ->
    Craft.debug "GetName:"..name..":"
    if Craft.scraps[name] then return name
    if Craft.gemstone[name] then return name
    cn = [string.lower(n) for n, c in pairs Craft.scraps]
    gn = [string.lower(n) for n, c in pairs Craft.gemstone]
    cl = table.n_union(cn,gn)
    names = [n for n in *cl when string.find(n, name)]
    if #names > 0
        if (#names > 1)
            Craft.echo "Multiple components match "..name
            for i in *names
                Craft.echo i
            return
        return names[1]
