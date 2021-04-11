Craft.bags = { }
Craft.baglist = { }
Craft.tradeAny = { }
local bagindex = nil
local bag = false
local in_inventory = false
local set_trade_comps
set_trade_comps = function()
  for t = 1, 4 do
    local g = Craft.tradeAny[t]
    if g then
      local mats = g.material or {
        "metal",
        "cloth",
        "wood",
        "leather"
      }
      local comps = g.components or nil
      local keep = g.keep or 1
      if comps then
        for _index_0 = 1, #comps do
          local n = comps[_index_0]
          Craft.component[n].trade = true
        end
      end
      for _index_0 = 1, #mats do
        local m = mats[_index_0]
        local r
        do
          local _accum_0 = { }
          local _len_0 = 1
          for n, c in pairs(Craft.component) do
            if (c.material == m) and (c.tier == t) then
              _accum_0[_len_0] = c
              _len_0 = _len_0 + 1
            end
          end
          r = _accum_0
        end
        if r then
          for _index_1 = 1, #r do
            local c = r[_index_1]
            c.trade = true
          end
        end
      end
    end
  end
end
Craft.InitInspect = function()
  if not Craft.bags then
    Craft.error("Variable Craft.bags is not defined, please create a variable to specify what bags contain comps, example:")
    Craft.error("Craft.bags = {rucksack={1,10}, alpine={10,20}, explorer={1,5}}")
    return 
  end
  Craft.state = "initializing"
  for n, c in pairs(Craft.component) do
    c.expertise = false
    c.artistry = false
    c.trade = false
    c.count = 0
    c.bag = { }
  end
  for n, s in pairs(Craft.scraps) do
    s.count = 0
    s.bag = { }
  end
  for n, g in pairs(Craft.gemstone) do
    g.count = 0
    g.bag = { }
  end
  set_trade_comps()
  registerAnonymousEventHandler("onCraftCheckComplete", Craft.CheckInventory, true)
  send("quest action, crafting")
  send(" ")
  send(" ")
end
Craft.InitExpertise = function(id)
  local t = "expertise"
  if id > 1000 then
    t = "artistry"
    id = id - 1000
  end
  local c
  do
    local _accum_0 = { }
    local _len_0 = 1
    for n, c in pairs(Craft.component) do
      if c.id == id then
        _accum_0[_len_0] = c
        _len_0 = _len_0 + 1
      end
    end
    c = _accum_0
  end
  if c[1] then
    c = c[1]
    c[t] = true
  end
end
local reset_bags
reset_bags = function()
  bag = false
  bagindex = nil
  Craft.baglist = { }
  for bag, rng in pairs(Craft.bags) do
    for i = rng[1], rng[2] do
      table.insert(Craft.baglist, i .. "." .. bag)
    end
  end
end
local bag_check_complete
bag_check_complete = function()
  bag = false
  bagindex = nil
  raiseEvent("onCraftCheckComplete")
end
local do_bag
do_bag = function()
  bagindex, bag = next(Craft.baglist, bagindex)
  if bag then
    registerAnonymousEventHandler("onSawBag", "Craft.SawBag", true)
    send("examine " .. bag)
  else
    bag_check_complete()
  end
end
Craft.InitBags = function()
  reset_bags()
  do_bag()
end
Craft.DoneBag = function()
  bag = false
  do_bag()
end
Craft.SawBag = function()
  registerAnonymousEventHandler("onPoolPrompt", "Craft.DoneBag", true)
end
local add_bag
add_bag = function(amount, t, name, b)
  Craft.debug("add_bag:" .. amount .. ":" .. t .. ":" .. name .. ":" .. b)
  local c = Craft[t][name]
  if Craft.state == "initializing" then
    c.count = c.count + amount
  end
  c.bag[b] = (c.bag[b] or 0) + amount
end
Craft.SawComp = function(amount, t, name)
  Craft.debug("SawComp:" .. amount .. ":" .. t .. ":" .. name .. ":")
  local n = string.trim(name)
  if in_inventory then
    add_bag(amount, t, n, "inventory")
  elseif bag then
    add_bag(amount, t, n, bag)
  end
end
Craft.DoneInventory = function()
  in_inventory = false
  if Craft.state == "initializing" then
    Craft.state = ""
    raiseEvent("onCraftInitComplete")
  end
end
local reset_inventory
reset_inventory = function()
  local _list_0 = {
    "component",
    "scraps",
    "gemstone"
  }
  for _index_0 = 1, #_list_0 do
    local t = _list_0[_index_0]
    for n, c in pairs(Craft[t]) do
      c.bag['inventory'] = 0
    end
  end
end
Craft.CheckInventory = function()
  send("inventory")
end
Craft.OnInventory = function()
  in_inventory = true
  reset_inventory()
  registerAnonymousEventHandler("onPoolPrompt", "Craft.DoneInventory", true)
end
Craft.NoBag = function()
  if Craft.state == "initializing" then
    Craft.error("Bag not found, something is wrong.")
    bag = false
    bagindex = nil
    Craft.state = ""
  end
end
reset_bags()
registerAnonymousEventHandler("onInventory", "Craft.OnInventory")
return registerAnonymousEventHandler("onNoBag", "Craft.NoBag")
