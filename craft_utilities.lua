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
  if #names > 0 then
    if (#names > 1) then
      Craft.echo("Multiple components match " .. name)
      for _index_0 = 1, #names do
        local i = names[_index_0]
        Craft.echo(i)
      end
      return 
    end
    return names[1]
  end
end
