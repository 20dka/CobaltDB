--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE


local M = {}

age = 0 --age of the server in milliseconds
local lastAnnounce = 0
local announceStep = 300000

CreateThread("onTick", 250)

CElog("CobaltDB Initiated")


function onTick()
	age = os.clock() * 1000
	if age > lastAnnounce + announceStep then
		local output = "DB Uptime: " .. (lastAnnounce + announceStep)/60000 .. " Minutes"

		CElog(output)

		lastAnnounce = lastAnnounce + announceStep
	end
end

return M
