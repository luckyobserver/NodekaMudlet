local dir = getMudletHomeDir():gsub("\\","/").."/NodekaMudlet/"
Bot = {}
Craft = {}
Map = {}
Counter = {}
flag = {}
dofile(dir..'bot.lua')
dofile(dir..'counter.lua')
dofile(dir..'craft_db.lua')
dofile(dir..'craft_get.lua')
dofile(dir..'craft_info.lua')
dofile(dir..'craft_init.lua')
dofile(dir..'craft_put.lua')
dofile(dir..'craft_trade.lua')
dofile(dir..'craft_utilities.lua')
dofile(dir..'map_info.lua')
dofile(dir..'map.lua')
dofile(dir..'player.lua')
