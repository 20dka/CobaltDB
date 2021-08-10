--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

cobaltVersion = "1.5.3A"

pluginPath = debug.getinfo(1).source
pluginPath = pluginPath:sub(2,(pluginPath:find("CobaltEssentialsLoader.lua"))-1):gsub("\\","/")
print(pluginPath)

package.path = package.path .. ";;" .. pluginPath .. "/?.lua;;".. pluginPath .. "/lua/?.lua"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.dll;;" .. pluginPath .. "/lib/?.dll"


utils = require("CobaltUtils")
print("\n\n")
CElog(color(107,94) .. "-------------Loading CobaltDB v" .. cobaltVersion .. "-------------")
CE = require("CobaltEssentials")

json = require("json")
CElog("json Lib Loaded")

TriggerLocalEvent("initDB", package.path, package.cpath, pluginPath .. "CobaltDB/")


CElog("-------------CobaltDB v" .. cobaltVersion .. " Loaded-------------")