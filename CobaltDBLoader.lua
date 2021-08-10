--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

cobaltVersion = "1.5.3A"

pluginPath = debug.getinfo(1).source:gsub("\\","/")
pluginPath = pluginPath:sub(2,(pluginPath:find("CobaltDBLoader.lua"))-1)
print("Plugin path is: " .. pluginPath)

package.path = package.path .. ";;" .. pluginPath .. "/?.lua;;".. pluginPath .. "/lua/?.lua"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.dll;;" .. pluginPath .. "/lib/?.dll"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.so;;" .. pluginPath .. "/lib/?.so"


utils = require("CobaltUtils")
print("\n\n")
CElog(color(107,94) .. "-------------Loading CobaltDB v" .. cobaltVersion .. "-------------")
CE = require("CobaltEssentials")

json = require("json")
CElog("json Lib Loaded")

TriggerLocalEvent("initDB", package.path, package.cpath, pluginPath .. "CobaltDB/")


CElog("-------------CobaltDB v" .. cobaltVersion .. " Loaded-------------")