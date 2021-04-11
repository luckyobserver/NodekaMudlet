Craft.full = { }
Craft.bag = nil
local put = { }
put.type = nil
put.index = nil
put.sawPut = false
put.sawFull = false
Craft.DoPut = function()
  Craft.debug("Craft.DoPut")
  if put.sawPut and not put.sawFull then
    Craft.PutComplete()
    return 
  end
  local bags
  do
    local _accum_0 = { }
    local _len_0 = 1
    local _list_0 = Craft.baglist
    for _index_0 = 1, #_list_0 do
      local bag = _list_0[_index_0]
      if not Craft.full[bag] then
        _accum_0[_len_0] = bag
        _len_0 = _len_0 + 1
      end
    end
    bags = _accum_0
  end
  if Craft.debugging then
    Craft.debug("Got " .. #bags .. " free bags:")
    if #bags > 0 then
      display(bags)
    end
  end
  Craft.bag = bags[1]
  if Craft.bag then
    put.sawPut = false
    put.sawFull = false
    Craft.debug("Putting:" .. Craft.bag)
    send("put all." .. put.type .. ", " .. Craft.bag)
  else
    Craft.debug("No more bags.")
    Craft.PutComplete()
  end
end
Craft.SawPut = function(amount, t, name)
  Craft.debug("SawPut:" .. amount .. ":" .. t .. ":" .. name)
  local c = Craft[t][name]
  if c.bag['inventory'] then
    c.bag['inventory'] = c.bag['inventory'] - amount
  end
  if Craft.bag then
    c = Craft[t][name]
    c.bag[Craft.bag] = (c.bag[Craft.bag] or 0) + amount
    if not put.sawPut then
      put.sawPut = true
      registerAnonymousEventHandler("onPoolPrompt", "Craft.DoPut", true)
    end
  end
end
Craft.BagFull = function()
  Craft.debug("BagFull")
  if Craft.bag then
    put.sawFull = true
    Craft.full[Craft.bag] = true
    Craft.bag = nil
    if not put.sawPut then
      Craft.DoPut()
    end
  end
end
Craft.Put = function(t)
  if t == nil then
    t = "component"
  end
  Craft.debug("Put:" .. t)
  if t == "scraps" then
    put.type = "scraps"
  else
    put.type = "component"
  end
  Craft.DoPut()
end
Craft.PutComplete = function()
  Craft.debug("PutComplete")
  Craft.bag = nil
  put = { }
  raiseEvent("onCraftPutComplete")
end
