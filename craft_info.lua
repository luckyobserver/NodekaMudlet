Craft.debugging = false
Craft.info = { }
Craft.info.expertiseLevels = {
  0,
  8,
  20,
  35,
  50,
  65,
  80,
  95,
  110,
  125,
  140,
  155
}
Craft.info.artistryLevels = {
  0,
  6,
  18,
  27,
  36,
  54,
  63,
  72,
  90,
  99,
  108,
  126
}
Craft.info.armorLevelCost = {
  0,
  3,
  6,
  10,
  15,
  19,
  23,
  28,
  34,
  40,
  46,
  53
}
Craft.info.weaponLevelCost = {
  0,
  5,
  10,
  15,
  19,
  23,
  28,
  34,
  40,
  46,
  53,
  61
}
local craft_tag = "<112,229,0>(<73,149,0>craft<112,229,0>): <255,255,255>"
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
end
Craft.echo = function(what, debug, err)
  local tag = craft_tag
  if debug then
    tag = tag .. debug_tag
  end
  if err then
    tag = tag .. err_tag
  end
  do_echo(what, tag)
end
Craft.error = function(what)
  Craft.echo(what, false, true)
end
Craft.debug = function(what)
  if Craft.debugging then
    Craft.echo(what, true)
  end
end
local ctg = { }
ctg["metal"] = "<SlateGray>"
ctg["cloth"] = "<purple>"
ctg["wood"] = "<ForestGreen>"
ctg["leather"] = "<SaddleBrown>"
local help = { }
help.help = {
  title = "Craft Help",
  command = "#craft <yellow>help<gray> <command>",
  short = "Display detailed help about a specified command.",
  long = "Display detailed help about a specified command:\n\n        - components\n        - gemstones\n        - recipes\n        - slots\n        - get\n        - put\n        - tradecomponents\n        - tradescraps\n        - tradejewels\n        - initialize"
}
help.components = {
  title = "Components",
  command = "#craft <yellow>components<gray>",
  short = "Display component and scrap info",
  long = "Displays a table with detailed info about component and scrap types, tiers,\namount you have as well as artistry and expertise techs."
}
help.gemstones = {
  title = "Gemstones",
  command = "#craft <yellow>gemstones<gray>",
  short = "Displays gemstone info",
  long = "Displays gemstone types, bonus points, amount you have, etc..."
}
help.recipes = {
  title = "Item Stat Recipes",
  command = "#craft <yellow>recipes<gray> [class1] [class2] [stats]",
  short = "Show recipes filtered by class or stats",
  long = "Searches possible crafting recipes by component class or stat bonus\n\n<white>example:<gray>\n    #craft r a b\n    #craft r a str,hit\n    #craft r str,con"
}
help.slots = {
  title = "Item Slot Recipes",
  command = "#craft <yellow>slots<gray>",
  short = "Display recipes to make items for each slot",
  long = "Display recipes to make items for each slot"
}
help.get = {
  title = "Get",
  command = "#<yellow>get<gray><components|scraps> [#] [name]",
  short = "Add item to retrieval queue or execute retrieval",
  long = "If you provide # and name then it adds the item to the retrieval queue. To\nretrieve all the components in the queue then run the command without any\narguments.\n\n<white>example:<gray>\n    #getc 10 elysian\n    #getcomp thorned\n    #getc amber\n    #getc"
}
help.put = {
  title = "Put",
  command = "#<yellow>put<gray>[components|scraps|all]",
  short = "Put away items",
  long = "Puts away items into the bags defined by your bag variables:\n\n<white>bag variable example:<gray>\n    Craft.bags = {rucksack:{1,45},explorer:{6,18}}\n\n<white>example:<gray>\n    #putc\n    #puta\n    #puts\n    #put"
}
help.tradecomponents = {
  title = "Trade Components",
  command = "#<yellow>tradecomponents<gray> [#] [item]",
  short = "Add item to queue or execute trade",
  long = "Add # components to the trade queue and if executed without arguments then\nbegins executing all trades in the queue. Components to offer in trade are\nautomatically selected. You choose which components you want to make available\nby setting the Craft.tradeAny variable. If you do not have artistry and\nexpertise techs in the component then it will keep 1 component, otherwise it\nwill trade all components that match the filter.\n\n<white>Craft.tradeAny variable example:<gray>\n        Craft.tradeAny = {}\n        -- Trades all tier 1 materials\n        Craft.tradeAny[1] = {material:{'metal','cloth','wood','leather'}}\n        -- Trades all tier 2 materials\n        Craft.tradeAny[2] = {material:{'metal','cloth','wood','leather'}}\n        -- Trades all tier 3 wood components as well as the specific named comps\n        Craft.tradeAny[3] = {material:{'wood'}, components:{\n            'galvanic alloy',\n            'limpid iron',\n            'siren-steel',\n            'dewstrand',\n            'sable silk',\n            'irongrowth',\n            'whip-wing beech',\n            'lustrous silver pelt',\n            'phytoderm husk',\n            'spored lamella',\n        }}\n\n<white>example:<gray>\n    #tradec 10 wyrm\n    #tradec gypsy\n    #tradec"
}
help.tradescraps = {
  title = "Trade Scraps",
  command = "#<yellow>tradescraps<gray>",
  short = "Trade all scraps into components",
  long = "Gathers all scraps that are available to trade and executes trades with Stacy"
}
help.tradejewels = {
  title = "Trade Jewels",
  command = "#<yellow>tradejewels<gray> [#]",
  short = "Trade # jewels with Stacy, defaults to 50",
  long = "Trade # jewels with Stacy, defaults to 50"
}
help.initialize = {
  title = "Initialize",
  command = "#craft <yellow>initialize<gray>",
  short = "Initializes craft plugin and does inventory.",
  long = "Initializes craft plugin and does inventory."
}
help.initialize = {
  title = "Reset",
  command = "#craft <yellow>reset<gray>",
  short = "Resets craft plugin.",
  long = "Resets craft plugin."
}
Craft.Help = function(topic)
  topic = string.lower(topic)
  topic = string.trim(topic)
  if not topic or topic == "" then
    cecho("\n\n<white>Craft Help<gray>\n\n")
    cecho("The following commands are available from the craft module. For additional info\nuse #craft help <command> for any highlighted word. Most words can be shortened\n")
    for n, c in pairs(help) do
      local str = string.format("\n%-60s - %s", c.command, c.short)
      cecho(str)
    end
  else
    local topics
    do
      local _accum_0 = { }
      local _len_0 = 1
      for n, c in pairs(help) do
        if string.match(n, topic or help[n]) then
          _accum_0[_len_0] = c
          _len_0 = _len_0 + 1
        end
      end
      topics = _accum_0
    end
    for _index_0 = 1, #topics do
      local t = topics[_index_0]
      cecho("\n<white>Craft " .. t.title .. " Help<gray>\n")
      cecho("Command: <white>" .. t.command .. "\n\n")
      cecho(t.long .. "\n")
    end
  end
end
Craft.ShowSlots = function()
  local slots = {
    {
      slot = "Light",
      an = 14,
      a = "cloth",
      bn = 7,
      b = "wood",
      mob = "Faja"
    },
    {
      slot = "Head",
      an = 7,
      a = "metal",
      bn = 4,
      b = "cloth",
      mob = "Eregalt"
    },
    {
      slot = "Neck",
      an = 4,
      a = "wood",
      bn = 3,
      b = "wood",
      mob = "Tessa"
    },
    {
      slot = "Body (cloth)",
      an = 7,
      a = "cloth",
      bn = 4,
      b = "cloth",
      mob = "Faja"
    },
    {
      slot = "Body (leather)",
      an = 7,
      a = "leather",
      bn = 4,
      b = "leather",
      mob = "Tessa"
    },
    {
      slot = "Chest (metal)",
      an = 9,
      a = "metal",
      bn = 6,
      b = "leather",
      mob = "Eregalt"
    },
    {
      slot = "Chest (cloth)",
      an = 9,
      a = "cloth",
      bn = 6,
      b = "leather",
      mob = "Faja"
    },
    {
      slot = "Arms",
      an = 7,
      a = "leather",
      bn = 4,
      b = "metal",
      mob = "Hagglish"
    },
    {
      slot = "Wrist",
      an = 4,
      a = "wood",
      bn = 3,
      b = "leather",
      mob = "Tessa"
    },
    {
      slot = "Hands",
      an = 4,
      a = "cloth",
      bn = 3,
      b = "leather",
      mob = "Hagglish"
    },
    {
      slot = "Weapon (combat)",
      an = 9,
      a = "metal",
      bn = 6,
      b = "wood",
      mob = "Badgit"
    },
    {
      slot = "Weapon (finesse)",
      an = 9,
      a = "wood",
      bn = 6,
      b = "metal",
      mob = "Badgit"
    },
    {
      slot = "Weapon (magic)",
      an = 9,
      a = "wood",
      bn = 6,
      b = "metal",
      mob = "Badgit"
    },
    {
      slot = "Legs",
      an = 7,
      a = "leather",
      bn = 4,
      b = "metal",
      mob = "Hagglish"
    },
    {
      slot = "Feet",
      an = 4,
      a = "leather",
      bn = 3,
      b = "cloth",
      mob = "Hagglish"
    }
  }
  cecho("<white>Slot             Comp A      Comp B              Mob\n")
  cecho("<white>---------------------------------------------------------\n")
  for _index_0 = 1, #slots do
    local s = slots[_index_0]
    local atag = ctg[s.a]
    local btag = ctg[s.b]
    local str = string.format("<white>%-17s%-3d" .. atag .. "%-9s<white>%-3d" .. btag .. "%-17s<white>%s\n", s.slot, s.an, s.a, s.bn, s.b, s.mob)
    cecho(str)
  end
end
Craft.ShowData = function(t, name)
  Craft.debug("ShowData:" .. t .. ":" .. name .. ":")
  name = string.gsub(name, "-", "")
  local cl
  do
    local _accum_0 = { }
    local _len_0 = 1
    for n, c in pairs(Craft[t]) do
      if string.find(name, string.gsub(n, "-", "")) then
        _accum_0[_len_0] = c
        _len_0 = _len_0 + 1
      end
    end
    cl = _accum_0
  end
  if not cl or #cl == 0 then
    Craft.error("ShowData Failed")
    return 
  end
  local c = cl[1]
  local s = ""
  if t == "gemstone" then
    s = string.format(" <turquoise>" .. c.class)
    if c.points > 0 then
      s = s .. (" <white>+" .. c.points)
    end
    s = s .. (" <turquoise>[<white>" .. c.count .. "<turquoise>]")
  elseif c.name == "jewel fragments" then
    s = s .. (" <yellow>Total:<white>" .. c.count)
  else
    local showcount = 0
    local tag = "<green>"
    if t == "scraps" then
      tag = "<DarkSalmon>"
      showcount = c.count
    else
      if c.count > 1 then
        showcount = c.count - 1
      end
    end
    s = " " .. tag .. c.tier .. c.class .. "[<white>" .. showcount .. tag .. "]"
  end
  moveCursorEnd()
  cecho(s)
end
local string_explode
string_explode = function(div, str)
  if div == '' then
    return false
  end
  local pos = 0
  local arr = { }
  for st, sp in function()
    return string.find(str, div, pos, true)
  end do
    table.insert(arr, string.sub(str, pos, st - 1))
    pos = sp + 1
  end
  table.insert(arr, string.sub(str, pos))
  return arr
end
Craft.ShowRecipes = function(t1, t2, filter)
  local f = ""
  local fa = { }
  local res = { }
  if filter and filter ~= "" then
    f = string.lower(filter)
    fa = string_explode(",", f)
  end
  for i = 1, #Craft.recipes do
    local r = Craft.recipes[i]
    local skip = false
    if t1 and t1 ~= "" then
      t1 = string.upper(t1)
      if t2 and t2 ~= "" then
        t2 = string.upper(t2)
        if r.class ~= (t1 .. t2) and r.class ~= (t2 .. t1) then
          skip = true
        end
      else
        if not string.match(r.class, t1) then
          skip = true
        end
      end
    end
    if not skip then
      for i = 1, #fa do
        if not string.match(r.stats, fa[i]) then
          skip = true
        end
      end
    end
    if not skip then
      local gs = ""
      if r.transform then
        local total = Craft.gemstone[r.transform].count
        local ct = "<OliveDrab>"
        if total > 0 then
          ct = "<LawnGreen>"
        end
        gs = string.format("<white>%-6s %s%s", "[" .. total .. "]", ct, r.transform)
      end
      local s = string.format("<white>%-7s<white>+%-6d<white>%-13s %s", r.class, r.points, r.stats, gs)
      res[#res + 1] = s
    end
  end
  if #res > 0 then
    cecho("<white>Crafting Recipes\n")
    cecho("<white>Class  Bonus  Stats        Transform\n")
    cecho("<white>---------------------------------------------------\n")
    for _index_0 = 1, #res do
      local s = res[_index_0]
      cecho(s .. "\n")
    end
    cecho("<white>---------------------------------------------------\n")
    cecho("<white>Class  Bonus  Stats        Transform\n")
  else
    cecho("No recipes matching criteria: " .. t1 .. t2 .. " " .. filter .. "\n")
  end
end
Craft.ShowGems = function()
  local div = "<white>------------------------------------------------\n"
  cecho("<white>Gemstones\n")
  cecho(string.format("<white>%-7s%-20s%-4s%s\n", "Points", "Name", "#", "Class"))
  local c = {
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "altering",
    "IA level cap +1",
    "IB level cap +2"
  }
  for i = 1, #c do
    cecho(div)
    local gems
    do
      local _accum_0 = { }
      local _len_0 = 1
      for n, g in pairs(Craft.gemstone) do
        if g.class == c[i] then
          _accum_0[_len_0] = g
          _len_0 = _len_0 + 1
        end
      end
      gems = _accum_0
    end
    for i = 1, #gems do
      local nt = "<LightGray>"
      local ct = "<LightGray>"
      local pts = " "
      if gems[i].points > 0 then
        pts = "+" .. gems[i].points
      end
      if gems[i].count > 0 then
        nt = "<LawnGreen>"
        ct = "<white>"
      end
      local s = string.format("<white>%-7s" .. nt .. "%-20s" .. ct .. "%-6d%s\n", pts, gems[i].name, gems[i].count, gems[i].class)
      cecho(s)
    end
  end
  cecho(div)
  cecho(string.format("<white>%-7s%-20s%-4s%s\n", "Points", "Name", "#", "Class"))
end
Craft.ShowComps = function()
  local s = string.format("<LightSkyBlue>  AE   S|C   %-22sAE   S|C   %-22sAE   S|C   %-22sAE   S|C   %s", "Tier 1", "Tier 2", "Tier 3", "Tier 4")
  cecho(s .. "\n")
  for i, material in ipairs({
    "metal",
    "cloth",
    "wood",
    "leather"
  }) do
    cecho("<LightSkyBlue>             " .. ctg[material] .. material .. "\n")
    for i, cl in ipairs({
      "A",
      "B",
      "C",
      "D",
      "E",
      "F",
      "G",
      "H"
    }) do
      s = "<LightSkyBlue>" .. cl
      for tier = 1, 4 do
        local c
        do
          local _accum_0 = { }
          local _len_0 = 1
          for n, c in pairs(Craft.component) do
            if c.material == material and c.tier == tier and c.class == cl then
              _accum_0[_len_0] = c
              _len_0 = _len_0 + 1
            end
          end
          c = _accum_0
        end
        if c[1] then
          c = c[1]
          local a = " "
          local e = " "
          local n = c.name
          local ct = "<LightGray>"
          local st = "<SlateGrey>"
          if c.artistry then
            a = "A"
          end
          if c.expertise then
            e = "E"
          end
          local count = 0
          if c.count == 1 then
            ct = "<OliveDrab>"
          end
          if c.count > 1 then
            ct = "<LawnGreen>"
            count = c.count - 1
          end
          if c.trade then
            n = n .. "*"
          end
          local sc = Craft.scraps[c.name]
          if sc.count >= sc.cost then
            st = "<OrangeRed>"
          end
          local cs = string.format(" <white>%1s%1s%s%4d<DimGray>|%s%-4d%-21s", a, e, st, sc.count, ct, count, n)
          s = s .. string.format("%-60s", cs)
          if tier == 4 then
            s = s .. "<LightSkyBlue>" .. cl
          end
        end
      end
      cecho(s .. "\n")
    end
  end
  local c = Craft.scraps["jewel fragments"]
  local st = "<white>"
  if c.count >= 50 then
    st = "<OrangeRed>"
  end
  s = string.format("<gold>jewel fragments: %s%d", st, c.count)
  cecho(s .. "\n")
  local result
  do
    local _accum_0 = { }
    local _len_0 = 1
    for name, comp in pairs(Craft.component) do
      if comp.artistry then
        _accum_0[_len_0] = name
        _len_0 = _len_0 + 1
      end
    end
    result = _accum_0
  end
  s = string.format("<white>Artistry:%5d", #result or 0)
  cecho(s .. "\n")
  do
    local _accum_0 = { }
    local _len_0 = 1
    for name, comp in pairs(Craft.component) do
      if comp.expertise then
        _accum_0[_len_0] = name
        _len_0 = _len_0 + 1
      end
    end
    result = _accum_0
  end
  s = string.format("<white>Expertise:%4d", #result or 0)
  cecho(s .. "\n")
  cecho("<white>* tradeable\n")
end
