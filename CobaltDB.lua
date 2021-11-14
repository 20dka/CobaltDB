--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE



local M = {}

local loadedDatabases = {}
local cobaltSysChar = string.char(0x99, 0x99, 0x99, 0x99)
local CobaltDBport = 10814


-- get plugin path
pluginPath = debug.getinfo(1).source:gsub("\\","/")
pluginPath = pluginPath:sub(1,(pluginPath:find("CobaltDB.lua"))-2)
print("Plugin path is: " .. pluginPath)

dbroot = pluginPath .. "/root/"
print("DB root is: " .. dbroot)


-- load modules
utils = require("CobaltUtils")
print("\n\n")
CElog(color(107,94) .. "-------------Loading CobaltDB-------------")

json = require("json")
CElog("json Lib Loaded")


CElog("-------------CobaltDB Loaded-------------")
-- load modules





-- uptime
local announceTick = 0
local announceStep = 300000 -- 5 minutes in ms

MP.CreateEventTimer("uptimeAnnounce", announceStep)
MP.RegisterEvent("uptimeAnnounce","uptimeAnnounce")
function uptimeAnnounce()
	announceTick = announceTick + 1

	CElog("DB Uptime: " .. (announceTick * announceStep)/60000 .. " Minutes")
end
--uptime




CElog("CobaltDB Initiated")








--give the CobaltDBconnector all the information it needs without having to re-calculate it all
function onInit()

	--json = require("json")
	socket = require("socket")
	--utils = require("CobaltUtils")
	--_G.dbroot = dbroot

	local configPath = dbroot .. "dbConfig.json"

	local configcontents, error = utils.readJson(configPath)
	if not error and configcontents ~= nil then
		if not configcontents.CobaltDBport then
			CElog("No CobaltDB port specified in the config, defaulting to '"..CobaltDBport.."'","WARN")
		else
			CobaltDBport = configcontents.CobaltDBport
		end
	else
		CElog("config could not be read, using default values","WARN")
		utils.writeJson(configPath, {CobaltDBport=CobaltDBport})
	end

	connector = socket.udp()
	connector:setsockname('*', CobaltDBport) -- was 0.0.0.0
	connector:settimeout(1)

	CElog("CobaltDB Ready on port "..tostring(CobaltDBport),"CobaltDB")

	MP.CreateEventTimer("checkforincoming", 50)
	MP.RegisterEvent("checkforincoming","checkforincoming")
end
----------------------------------------------------------MUTATORS---------------------------------------------------------

local function openDatabase(d, dontSend)
	local databaseLoaderResponse = { isNew = false } -- defines if the DB was created just now or if it was pre-existing.

	if not d.targetid then -- no target specified, check for local first
		CElog("no targetid specified")
		if FS.Exists(string.format("%s%s/%s.json", dbroot, d.id, d.dbname)) then -- local db exists
			d.targetid = d.id
			CElog("local db exists")
		else
			d.targetid = "shared"
			CElog("local db doesn't exist, using 'shared'")
		end
	end

	databaseLoaderResponse.targetID = d.targetid

	local dirPath = dbroot .. d.targetid ..'/'
	local jsonPath = dirPath .. d.dbname .. ".json"
	loadedDatabases[d.targetid] = loadedDatabases[d.targetid] or {}

	if FS.Exists(dirPath) then -- server folder exists
		local parsed, error = utils.readJson(jsonPath)

		if error then
			if error == "File does not exist" then
				CElog(d.targetid .. " db doesnt exist, creating it", "CobaltDB", d.event)
				databaseLoaderResponse.isNew = true

				local success, error = utils.writeJson(jsonPath, nil)

				if not success then
					CElog('failed to write file "' .. tostring(jsonPath) .. '", error: ' .. tostring(error),"WARN")
				end
				loadedDatabases[d.targetid][d.dbname] = {}
			else
				CElog('failed to open file "' .. tostring(jsonPath) .. '", error: ' .. tostring(error),"WARN")
				databaseLoaderResponse.isNew = true
			end
		else
			CElog("opened "..d.targetid.." db "..d.dbname, "CobaltDB", d.event)
			loadedDatabases[d.targetid][d.dbname] = parsed
		end
	else -- server folder doesnt exist, create it
		CElog("client folder doesnt exist, creating it", "CobaltDB", d.event)
		utils.writeJson(jsonPath, nil)
		loadedDatabases[d.targetid][d.dbname] = {}
		databaseLoaderResponse.isNew = true
	end

	if not dontSend then connector:sendto(json.stringify(databaseLoaderResponse), d.ip, d.port) end
end

--saves the db to disk
local function updateDatabase(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to local", "CobaltDB", d.event)
		d.targetid = d.id
	end

	local dirPath = dbroot .. d.targetid ..'/'
	local jsonPath = dirPath .. d.dbname .. ".json"

	local dataToWrite = loadedDatabases[d.targetid][d.dbname]

	if FS.Exists(dirPath) then -- server folder exists
		if FS.Exists(jsonPath) then
			local parsed, error = utils.writeJson(jsonPath, dataToWrite)

			if error then
				CElog("oops could not write json", "updateDatabase")
			else
				CElog("wrote ".. d.targetid .. " json to disk", "updateDatabase")
			end
		else
			CElog(d.targetid .. " db doesnt exist, creating it", "updateDatabase")
			utils.writeJson(jsonPath, dataToWrite)
		end
	else -- server folder doesnt exist, create it
		CElog("server folder doesnt exist, creating it", "updateDatabase")
		utils.writeJson(jsonPath, dataToWrite)
	end

end

--should this exist?
local function closeDatabase(d)
	updateDatabase(d)

	--loadedDatabases[d.targetid][d.dbname] = nil
end


--changes the table
local function set(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to local", "CobaltDB", d.event)
		d.targetid = d.id
	end

	if loadedDatabases[d.targetid][d.dbname] ~= nil then

		if loadedDatabases[d.targetid][d.dbname][d.table] == nil then
			loadedDatabases[d.targetid][d.dbname][d.table] = {}
		end

		if d.key ~= nil then
			if d.value == "null" then
				loadedDatabases[d.targetid][d.dbname][d.table][d.key] = nil
			else
				loadedDatabases[d.targetid][d.dbname][d.table][d.key] = json.parse(d.value)
			end
			updateDatabase(d)
		end

	else --db(file) DOESN'T EXIST
		CElog("CobaltDB File " .. d.dbname .. " not loaded on " .. d.targetid, "WARN")
		openDatabase(d, true)
		set(d)
	end

end

--changes the table
local function setKeys(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to local", "CobaltDB", d.event)
		d.targetid = d.id
	end

	if loadedDatabases[d.targetid][d.dbname] ~= nil then

		if loadedDatabases[d.targetid][d.dbname][d.table] == nil then
			loadedDatabases[d.targetid][d.dbname][d.table] = {}
		end

		if d.key ~= nil then
			if loadedDatabases[d.targetid][d.dbname][d.table][d.key] == nil then
				loadedDatabases[d.targetid][d.dbname][d.table][d.key] = d.values
				updateDatabase(d)
			else
				if type(loadedDatabases[d.targetid][d.dbname][d.table][d.key]) ~= "table" then
					
				else
					for k,v in pairs(d.values) do
						loadedDatabases[d.targetid][d.dbname][d.table][d.key][k] = v
					end
					updateDatabase(d)
				end
			end
		end

	else --db(file) DOESN'T EXIST
		error("CobaltDB File " .. d.dbname .. " not loaded on " .. d.targetid)
	end

end




---------------------------------------------------------ACCESSORS---------------------------------------------------------

--returns a specific value from the table
local function query(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to 'shared'", "CobaltDB", d.event)
		d.targetid = "shared"
	end

	local data

	if loadedDatabases[d.targetid][d.dbname] == nil then
		--error here, database isn't open
		data = cobaltSysChar .. "E:" .. d.dbname .. "not found."
		openDatabase(d, true)
		query(d)
		return
	else
		if loadedDatabases[d.targetid][d.dbname][d.table] == nil then
			--error here, table doesn't exist
			data = cobaltSysChar .. "E:" .. d.dbname .. " > " .. d.table .. " not found."
		else
			if loadedDatabases[d.targetid][d.dbname][d.table][d.key] == nil then
				--error here, key doesn't exist in table
				data = cobaltSysChar .. "E:" .. d.dbname .. " > " .. d.table .. " > " .. d.key .. " not found."
			else
				--send the value as json
				data = json.stringify(loadedDatabases[d.targetid][d.dbname][d.table][d.key])
			end
		end
	end

	connector:sendto(data, d.ip, d.port)
end

--returns values for specific keys of the table
local function queryKeys(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to 'shared'", "CobaltDB", d.event)
		d.targetid = "shared"
	end

	local data

	if loadedDatabases[d.targetid][d.dbname] == nil then
		--error here, database isn't open
		data = cobaltSysChar .. "E:" .. d.dbname .. "not found."
	else
		if loadedDatabases[d.targetid][d.dbname][d.table] == nil then
			--error here, table doesn't exist
			data = cobaltSysChar .. "E:" .. d.dbname .. " > " .. d.table .. " not found."
		else
			if loadedDatabases[d.targetid][d.dbname][d.table][d.key] == nil then
				--error here, key doesn't exist in table
				data = cobaltSysChar .. "E:" .. d.dbname .. " > " .. d.table .. " > " .. d.key .. " not found."
			else
				if type(loadedDatabases[d.targetid][d.dbname][d.table][d.key]) ~= "table" then
					--error here, key isn't a in table
					data = cobaltSysChar .. "E:" .. d.dbname .. " > " .. d.table .. " > " .. d.key .. " is not a table."
				else
					local respTable = {}
					for k,v in pairs(d.keys) do
						respTable[v] = loadedDatabases[d.targetid][d.dbname][d.table][d.key][v]
					end
					--send the value as json
					data = json.stringify(respTable)
				end
			end
		end
	end

	connector:sendto(data, d.ip, d.port)
end

--returns a read-only version of the table as json.
local function getTable(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to local", "CobaltDB", d.event)
		d.targetid = d.id
	end

	local data

	if loadedDatabases[d.targetid][d.dbname] == nil then
		--error here, database isn't open
		data = cobaltSysChar .. "E:" .. d.dbname .. "not found."
		openDatabase(d, true)
		getTable(d)
		return
	else
		if loadedDatabases[d.targetid][d.dbname][d.table] == nil then
			--error here, table doesn't exist
			data = cobaltSysChar .. "E:" .. d.dbname .. " > " .. d.table .. " not found."
		else
			--send the table as json
			data = json.stringify(loadedDatabases[d.targetid][d.dbname][d.table])
		end
	end

	connector:sendto(data, d.ip, d.port)
end

--returns a read-only list of all table names within the database
local function getTables(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to local", "CobaltDB", d.event)
		d.targetid = d.id
	end

	if loadedDatabases[d.targetid][d.dbname] == nil then
		--error here, database isn't open
		openDatabase(d, true)
		getTables(d)
		return
	end

	local data = {}
	for id, _ in pairs(loadedDatabases[d.targetid][d.dbname]) do
		data[id] = id
	end

	data = json.stringify(data)

	connector:sendto(data, d.ip, d.port)
end

local function getKeys(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to local", "CobaltDB", d.event)
		d.targetid = d.id
	end

	if loadedDatabases[d.targetid][d.dbname] == nil then
		--error here, database isn't open
		openDatabase(d, true)
		getKeys(d)
		return
	end

	local data = {}
	for id, _ in pairs(loadedDatabases[d.targetid][d.dbname][d.table]) do
		data[id] = id
	end

	data = json.stringify(data)

	connector:sendto(data, d.ip, d.port)
end

local function tableExists(d)
	if not d.targetid then
		CElog("no targetid was specified! defaulting to local", "CobaltDB", d.event)
		d.targetid = d.id
	end

	local data = "E: table doesnt exist"

	if loadedDatabases[d.targetid][d.dbname] == nil then
		--error here, database isn't open
		openDatabase(d, true)
		tableExists(d)
		return
	end


	if loadedDatabases[d.targetid][d.dbname][d.table] ~= nil then
		data = d.table
	end

	connector:sendto(data, d.ip, d.port)
end

local function pong(d)
	connector:sendto("pong", d.ip, d.port)
end

---------------------------------------------------------FUNCTIONS---------------------------------------------------------



------------------------------------------------------PUBLIC INTERFACE------------------------------------------------------

local actionTable = {
	["openDatabase"]   = function(d) openDatabase(d) end,
	["closeDatabase"]  = function(d) closeDatabase(d) end,
	["query"]          = function(d) query(d) end,
	["querykeys"]      = function(d) queryKeys(d) end,
	["set"]            = function(d) set(d) end,
	["getTable"]       = function(d) getTable(d) end,
	["getTables"]      = function(d) getTables(d) end,
	["getKeys"]        = function(d) getKeys(d) end,
	["tableExists"]    = function(d) tableExists(d) end,
	["ping"]           = function(d) pong(d) end -- used to check if connections are alive
}


local function concatAll(tbl)
	local str = ''
	for k,v in pairs(tbl) do str = str .. '.' .. v end
	return str:sub(2)
end

function checkforincoming()
	local data, ip, port = connector:receivefrom(32768)
	while data do
		local parsed = json.parse(data)
		parsed.ip = ip; parsed.port = port -- add return address
		
		local targetstr = concatAll({parsed.targetid or parsed.id, parsed.dbname, parsed.table, parsed.key, parsed.value})

		CElog(targetstr, 'CobaltDB', parsed.event, ip..':'..port)

		actionTable[parsed.event](parsed) -- process request and reply

		data, ip, port = connector:receivefrom(32768) -- check for new requests
	end
end

------------------------------------------------------PUBLIC INTERFACE------------------------------------------------------


----EVENTS-----

----MUTATORS-----

----ACCESSORS----

----FUNCTIONS----


return M
