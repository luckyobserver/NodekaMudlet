local getQ = { }
local gotQ = { }
local get = { }
Craft.GetName = function(name)
  Craft.debug("GetName:" .. name .. ":")
  if Craft.scraps[name] then
    return name
  end
  if Craft.gemstone[name] then
    return name
  end
  local cn
  do
    local _accum_0 = { }
    local _len_0 = 1
    for n, c in pairs(Craft.scraps) do
      _accum_0[_len_0] = string.lower(n)
      _len_0 = _len_0 + 1
    end
    cn = _accum_0
  end
  local gn
  do
    local _accum_0 = { }
    local _len_0 = 1
    for n, c in pairs(Craft.gemstone) do
      _accum_0[_len_0] = string.lower(n)
      _len_0 = _len_0 + 1
    end
    gn = _accum_0
  end
  local cl = table.n_union(cn, gn)
  local names
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #cl do
      local n = cl[_index_0]
      if string.find(n, name) then
        _accum_0[_len_0] = n
        _len_0 = _len_0 + 1
      end
    end
    names = _accum_0
  end
  if Craft.debugging then
    display(names)
  end
  if #names > 0 then
    if (#names > 1) then
      Craft.echo("Multiple components match " .. name)
      for _index_0 = 1, #names do
        local i = names[_index_0]
        Craft.echo(i)
      end
      return 
    end
    name = names[1]
    return name
  end
end
Craft.GetAddQ = function(amount, t, n)
  Craft.debug("GetAddQ:" .. amount .. ":" .. t .. ":" .. n .. ":")
  n = string.trim(n) or ""
  local name = Craft.GetName(n)
  if t == "component" and not Craft.component[name] then
    if Craft.gemstone[name] then
      t = "gemstone"
    end
  end
  Craft.debug("Got name:" .. name .. " type:" .. t)
  local total = Craft[t][name].count
  if total < amount then
    Craft.echo("You have " .. total .. " " .. t .. " of " .. name .. " unable to retrieve " .. amount .. ".")
    return 
  end
  if name ~= "" then
    table.insert(getQ, {
      amount,
      t,
      name
    })
    Craft.echo("Added " .. amount .. " " .. t .. " of " .. name .. " to retrieval queue.")
  end
end
Craft.GetComplete = function()
  Craft.debug("GetComplete")
  Craft.bag = nil
  get = { }
  getQ = { }
  Craft.state = ""
  if gotQ and (#gotQ > 0) then
    local _list_0 = gotQ
    for _index_0 = 1, #_list_0 do
      local i = _list_0[_index_0]
      Craft.echo("Retrieved " .. i[1] .. " " .. i[2] .. " of " .. i[3])
    end
    raiseEvent("onCraftGetComplete", gotQ)
  end
end
local get_next_bag
get_next_bag = function()
  Craft.debug("get_next_bag:" .. get.want .. ":" .. get.type .. ":" .. get.name .. ":")
  local c = Craft[get.type][get.name]
  local b
  do
    local _accum_0 = { }
    local _len_0 = 1
    for name, count in pairs(c.bag) do
      if count > 0 and name ~= "inventory" then
        _accum_0[_len_0] = {
          name,
          count
        }
        _len_0 = _len_0 + 1
      end
    end
    b = _accum_0
  end
  local amount
  do
    local _obj_0 = b[1]
    Craft.bag, amount = _obj_0[1], _obj_0[2]
  end
  if Craft.bag then
    local s = ""
    if get.want >= amount then
      s = "all."
    end
    send("get " .. s .. get.type .. " " .. get.name .. ", " .. Craft.bag)
  end
end
local do_get
do_get = function()
  Craft.debug("do_get")
  if not getQ or (#getQ == 0) then
    Craft.GetComplete()
    return 
  end
  get.want, get.type, get.name = unpack(getQ[1])
  local c = Craft[get.type][get.name]
  if c.bag['inventory'] then
    get.want = get.want - c.bag['inventory']
  end
  if get.want > 0 then
    get_next_bag()
    return 
  else
    table.insert(gotQ, getQ[1])
    table.remove(getQ, 1)
    do_get()
    return 
  end
  Craft.GetComplete()
end
Craft.SawGet = function(amount, t, name)
  Craft.debug("SawGet:" .. amount .. ":" .. t .. ":" .. name .. ":")
  if Craft.bag then
    Craft.full[Craft.bag] = false
  end
  local c = Craft[t][name]
  c.bag['inventory'] = (c.bag['inventory'] or 0) + amount
  if (get.name == name) and (get.type == t) and Craft.bag then
    get.want = get.want - amount
    c = Craft[get.type][get.name]
    c.bag[Craft.bag] = (c.bag[Craft.bag] or 0) - amount
    if get.want <= 0 then
      table.insert(gotQ, getQ[1])
      table.remove(getQ, 1)
      get = { }
      do_get()
    else
      get_next_bag()
    end
  end
end
Craft.Get = function(amount, t, n)
  amount = amount or 0
  t = t or ""
  n = n or ""
  Craft.debug("Get:" .. amount .. ":" .. t .. ":" .. n .. ":")
  gotQ = { }
  if n ~= "" then
    Craft.GetAddQ(amount, t, n)
  end
  do_get()
end
Craft.NotInBag = function()
  Craft.debug("NotInBag")
  Craft.GetComplete()
end
registerAnonymousEventHandler("onNotInBag", "Craft.GetComplete")
return registerAnonymousEventHandler("onInventoryFull", "Craft.GetComplete")
