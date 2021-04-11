Craft.debugging = false

Craft.info = {}

-- example: Level 2 > 8 techs
Craft.info.expertiseLevels = {0, 8, 20, 35, 50, 65, 80, 95, 110, 125, 140, 155}
Craft.info.artistryLevels = {0, 6, 18, 27, 36, 54, 63, 72, 90, 99, 108, 126}

-- Crafting Item Point Costs per Level
Craft.info.armorLevelCost={ 0, 3, 6, 10, 15, 19, 23, 28, 34, 40, 46, 53, }
Craft.info.weaponLevelCost = { 0, 5, 10, 15, 19, 23, 28, 34, 40, 46, 53, 61, }

craft_tag = "<112,229,0>(<73,149,0>craft<112,229,0>): <255,255,255>"
debug_tag = "<255,165,0>(<200,120,0>debug<255,165,0>): <255,255,255>"
err_tag = "<255,0,0>(<178,34,34>error<255,0,0>): <255,255,255>"

do_echo = (what, tag) ->
    moveCursorEnd!
    curline = getCurrentLine!
    if curline ~= ""
        echo("\n")
    decho(tag)
    cecho(what)
    --echo("\n")
    return

Craft.echo = (what, debug, err) ->
    tag = craft_tag
    if debug then tag ..= debug_tag
    if err then tag ..= err_tag
    do_echo(what, tag)
    return

Craft.error = (what) ->
    Craft.echo(what,false,true)
    return

Craft.debug = (what) ->
    if Craft.debugging
        Craft.echo(what,true)
    return

ctg = {}
ctg["metal"] = "<SlateGray>"
ctg["cloth"] = "<purple>"
ctg["wood"] = "<ForestGreen>"
ctg["leather"] = "<SaddleBrown>"

help = {}
help.help = {
    title:"Craft Help",
    command:"#craft <yellow>help<gray> <command>",
    short:"Display detailed help about a specified command.",
    long:"Display detailed help about a specified command:

        - components
        - gemstones
        - recipes
        - slots
        - get
        - put
        - tradecomponents
        - tradescraps
        - tradejewels
        - initialize",
}
help.components = {
    title:"Components",
    command:"#craft <yellow>components<gray>",
    short:"Display component and scrap info",
    long:"Displays a table with detailed info about component and scrap types, tiers,
amount you have as well as artistry and expertise techs." }
help.gemstones = {
    title:"Gemstones",
    command:"#craft <yellow>gemstones<gray>",
    short:"Displays gemstone info",
    long:"Displays gemstone types, bonus points, amount you have, etc...",
}
help.recipes = {
    title:"Item Stat Recipes",
    command:"#craft <yellow>recipes<gray> [class1] [class2] [stats]",
    short:"Show recipes filtered by class or stats",
    long:"Searches possible crafting recipes by component class or stat bonus

<white>example:<gray>
    #craft r a b
    #craft r a str,hit
    #craft r str,con",
}
help.slots = {
    title:"Item Slot Recipes",
    command:"#craft <yellow>slots<gray>",
    short:"Display recipes to make items for each slot",
    long:"Display recipes to make items for each slot",
}
help.get = {
    title:"Get",
    command:"#<yellow>get<gray><components|scraps> [#] [name]",
    short:"Add item to retrieval queue or execute retrieval",
    long:"If you provide # and name then it adds the item to the retrieval queue. To
retrieve all the components in the queue then run the command without any
arguments.

<white>example:<gray>
    #getc 10 elysian
    #getcomp thorned
    #getc amber
    #getc"
}
help.put = {
    title:"Put",
    command:"#<yellow>put<gray>[components|scraps|all]",
    short:"Put away items",
    long:"Puts away items into the bags defined by your bag variables:

<white>bag variable example:<gray>
    Craft.bags = {rucksack:{1,45},explorer:{6,18}}

<white>example:<gray>
    #putc
    #puta
    #puts
    #put"
}
help.tradecomponents = {
    title:"Trade Components",
    command:"#<yellow>tradecomponents<gray> [#] [item]",
    short:"Add item to queue or execute trade",
    long:"Add # components to the trade queue and if executed without arguments then
begins executing all trades in the queue. Components to offer in trade are
automatically selected. You choose which components you want to make available
by setting the Craft.tradeAny variable. If you do not have artistry and
expertise techs in the component then it will keep 1 component, otherwise it
will trade all components that match the filter.

<white>Craft.tradeAny variable example:<gray>
        Craft.tradeAny = {}
        -- Trades all tier 1 materials
        Craft.tradeAny[1] = {material:{'metal','cloth','wood','leather'}}
        -- Trades all tier 2 materials
        Craft.tradeAny[2] = {material:{'metal','cloth','wood','leather'}}
        -- Trades all tier 3 wood components as well as the specific named comps
        Craft.tradeAny[3] = {material:{'wood'}, components:{
            'galvanic alloy',
            'limpid iron',
            'siren-steel',
            'dewstrand',
            'sable silk',
            'irongrowth',
            'whip-wing beech',
            'lustrous silver pelt',
            'phytoderm husk',
            'spored lamella',
        }}

<white>example:<gray>
    #tradec 10 wyrm
    #tradec gypsy
    #tradec",
}
help.tradescraps = {
    title:"Trade Scraps",
    command:"#<yellow>tradescraps<gray>",
    short:"Trade all scraps into components",
    long:"Gathers all scraps that are available to trade and executes trades with Stacy",
}
help.tradejewels = {
    title:"Trade Jewels",
    command:"#<yellow>tradejewels<gray> [#]",
    short:"Trade # jewels with Stacy, defaults to 50",
    long:"Trade # jewels with Stacy, defaults to 50"
}
help.initialize = {
    title:"Initialize",
    command:"#craft <yellow>initialize<gray>",
    short:"Initializes craft plugin and does inventory.",
    long:"Initializes craft plugin and does inventory.",
}
help.initialize = {
    title:"Reset",
    command:"#craft <yellow>reset<gray>",
    short:"Resets craft plugin.",
    long:"Resets craft plugin.",
}

Craft.Help = (topic) ->
    topic = string.lower topic
    topic = string.trim topic
    if not topic or topic == ""
        cecho("\n\n<white>Craft Help<gray>\n\n")
        cecho("The following commands are available from the craft module. For additional info
use #craft help <command> for any highlighted word. Most words can be shortened\n")
        for n, c in pairs help
            str = string.format "\n%-60s - %s", c.command, c.short
            cecho(str)
    else
        topics = [c for n, c in  pairs help when string.match n, topic or help[n]]
        for t in *topics

            cecho("\n<white>Craft "..t.title.." Help<gray>\n")
            cecho("Command: <white>"..t.command.."\n\n")
            cecho(t.long.."\n")
    return
                
Craft.ShowSlots = ->
    slots = {
        {slot:"Light", an:14, a:"cloth", bn:7, b:"wood", mob:"Faja"},
        {slot:"Head", an:7, a:"metal", bn:4, b:"cloth", mob:"Eregalt"},
        {slot:"Neck", an:4, a:"wood", bn:3, b:"wood", mob:"Tessa"},
        {slot:"Body (cloth)", an:7, a:"cloth", bn:4, b:"cloth", mob:"Faja"},
        {slot:"Body (leather)", an:7, a:"leather", bn:4, b:"leather", mob:"Tessa"},
        {slot:"Chest (metal)", an:9, a:"metal", bn:6, b:"leather", mob:"Eregalt"},
        {slot:"Chest (cloth)", an:9, a:"cloth", bn:6, b:"leather", mob:"Faja"},
        {slot:"Arms", an:7, a:"leather", bn:4, b:"metal", mob:"Hagglish"},
        {slot:"Wrist", an:4, a:"wood", bn:3, b:"leather", mob:"Tessa"},
        {slot:"Hands", an:4, a:"cloth", bn:3, b:"leather", mob:"Hagglish"},
        {slot:"Weapon (combat)", an:9, a:"metal", bn:6, b:"wood", mob:"Badgit"},
        {slot:"Weapon (finesse)", an:9, a:"wood", bn:6, b:"metal", mob:"Badgit"},
        {slot:"Weapon (magic)", an:9, a:"wood", bn:6, b:"metal", mob:"Badgit"},
        {slot:"Legs", an:7, a:"leather", bn:4, b:"metal", mob:"Hagglish"},
        {slot:"Feet", an:4, a:"leather", bn:3, b:"cloth", mob:"Hagglish"},
    }
    cecho("<white>Slot             Comp A      Comp B              Mob\n")
    cecho("<white>---------------------------------------------------------\n")
    for s in *slots
        atag = ctg[s.a]
        btag = ctg[s.b]
        str = string.format(
            "<white>%-17s%-3d"..atag.."%-9s<white>%-3d"..btag.."%-17s<white>%s\n",
            s.slot, s.an, s.a, s.bn, s.b, s.mob)
        cecho(str)
    return

Craft.ShowData = (t, name) ->
    Craft.debug("ShowData:"..t..":"..name..":")
    -- Get the relevant component
    name = string.gsub(name, "-","")
    cl = [c for n, c in pairs Craft[t] when string.find name, string.gsub(n, "-", "")]
    if not cl or #cl == 0
        Craft.error("ShowData Failed")
        return
    c = cl[1]
    s = ""
    -- Print the info
    if t == "gemstone"
        s = string.format(" <turquoise>"..c.class)
        if c.points > 0
            s ..= " <white>+" ..c.points
        s ..= " <turquoise>[<white>"..c.count.."<turquoise>]"
    elseif c.name == "jewel fragments"
        s ..= " <yellow>Total:<white>"..c.count
    else
        -- Set the tag color, green for component and salmon for scraps
        showcount = 0
        tag = "<green>"
        if t == "scraps"
            tag = "<DarkSalmon>"
            showcount = c.count
        else
            -- Always keep 1 component in reserve - makes it easier to not know about it
            if c.count > 1 then showcount = c.count-1
        s = " "..tag..c.tier..c.class.."[<white>"..showcount..tag.."]"
    moveCursorEnd!
    cecho(s)
    return

string_explode = (div,str) ->
    if div == '' then return false
    pos = 0
    arr = {}
    for st,sp in -> return string.find(str, div, pos, true)
        table.insert(arr, string.sub(str, pos, st-1))
        pos = sp + 1
    table.insert(arr, string.sub(str, pos))
    return arr

Craft.ShowRecipes = (t1, t2, filter) ->
    f = ""
    fa = {}
    res = {}
    if filter and filter != ""
        f = string.lower(filter)
        fa = string_explode(",", f)
    for i=1,#Craft.recipes
        r = Craft.recipes[i]
        skip = false
        if t1 and t1 != ""
            t1 = string.upper(t1)
            if t2 and t2 != ""
                t2 = string.upper(t2)
                if r.class != (t1..t2) and r.class != (t2..t1)
                    skip = true
            else
                if not string.match(r.class, t1) then skip = true
        if not skip
            for i=1,#fa
                if not string.match(r.stats, fa[i])
                    skip = true
        if not skip
            gs = ""
            if r.transform
                total = Craft.gemstone[r.transform].count
                ct = "<OliveDrab>"
                if total > 0 then ct = "<LawnGreen>"
                gs = string.format "<white>%-6s %s%s", "["..total.."]", ct, r.transform
            s = string.format "<white>%-7s<white>+%-6d<white>%-13s %s",
                r.class, r.points, r.stats, gs
            res[#res+1] = s

    if #res > 0
        cecho("<white>Crafting Recipes\n")
        cecho("<white>Class  Bonus  Stats        Transform\n")
        cecho("<white>---------------------------------------------------\n")
        for s in *res
            cecho(s.."\n")
        cecho("<white>---------------------------------------------------\n")
        cecho("<white>Class  Bonus  Stats        Transform\n")
    else
        cecho("No recipes matching criteria: "..t1..t2.." "..filter.."\n")
    return

Craft.ShowGems = ->
    div = "<white>------------------------------------------------\n"
    cecho("<white>Gemstones\n")
    cecho(string.format "<white>%-7s%-20s%-4s%s\n","Points","Name","#","Class")
    c = {"A","B","C","D","E","F","G","altering","IA level cap +1","IB level cap +2"}
    for i=1,#c
        cecho(div)
        gems = [g for n, g in pairs Craft.gemstone when g.class == c[i]]
        for i=1,#gems
            nt = "<LightGray>"
            ct = "<LightGray>"
            pts = " "
            if gems[i].points > 0 then pts = "+"..gems[i].points
            if gems[i].count > 0
                nt = "<LawnGreen>"
                ct = "<white>"
            s = string.format "<white>%-7s"..nt.."%-20s"..ct.."%-6d%s\n",
                pts, gems[i].name, gems[i].count, gems[i].class
            cecho(s)
    cecho(div)
    cecho(string.format "<white>%-7s%-20s%-4s%s\n","Points","Name","#","Class")
    return

Craft.ShowComps = ->
    s = string.format("<LightSkyBlue>  AE   S|C   %-22sAE   S|C   %-22sAE   S|C   %-22sAE   S|C   %s", "Tier 1", "Tier 2", "Tier 3", "Tier 4")
    cecho(s.."\n")
    for i, material in ipairs({"metal", "cloth", "wood", "leather"}) do
        cecho("<LightSkyBlue>             "..ctg[material]..material.."\n")
        for i, cl in ipairs({"A", "B", "C", "D", "E", "F", "G", "H"}) do
            s = "<LightSkyBlue>"..cl
            for tier=1,4 do
                c = [c for n, c in pairs Craft.component when c.material == material and c.tier == tier and c.class == cl]
                if c[1]
                    c = c[1]
                    a = " "
                    e = " "
                    n = c.name
                    ct = "<LightGray>"
                    st = "<SlateGrey>"
                    if c.artistry then a = "A"
                    if c.expertise then e = "E"
                    count = 0
                    if c.count == 1 then ct = "<OliveDrab>"
                    if c.count > 1
                        ct = "<LawnGreen>"
                        -- hide 1 comp
                        count = c.count-1
                    if c.trade then n ..= "*"
                    sc = Craft.scraps[c.name]
                    if sc.count >= sc.cost then st = "<OrangeRed>"
                    cs = string.format(" <white>%1s%1s%s%4d<DimGray>|%s%-4d%-21s", a, e, st, sc.count, ct, count, n)
                    s ..= string.format("%-60s", cs)
                    if tier == 4
                        s = s.."<LightSkyBlue>"..cl
            cecho(s.."\n")
    c = Craft.scraps["jewel fragments"]
    st = "<white>"
    if c.count >= 50 then st = "<OrangeRed>"
    s = string.format("<gold>jewel fragments: %s%d", st, c.count)
    cecho(s.."\n")
    result = [name for name,comp in pairs Craft.component when comp.artistry]
    s = string.format("<white>Artistry:%5d", #result or 0)
    cecho(s.."\n")
    result = [name for name,comp in pairs Craft.component when comp.expertise]
    s = string.format("<white>Expertise:%4d", #result or 0)
    cecho(s.."\n")
    cecho("<white>* tradeable\n")
    return
