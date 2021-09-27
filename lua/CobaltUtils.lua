--Copyright (C) 2020, Preston Elam (CobaltTetra) ALL RIGHTS RESERVED
--COBALTESSENTIALS IS PROTECTED UNDER AN GPLv3 LICENSE

local M = {}

local funcColor = {
	["openDatabase"]   = 31,
	["closeDatabase"]  = 32,
	["query"]          = 33,
	["set"]            = 34,
	["getTable"]       = 36,
	["getTables"]      = 37,
	["getKeys"]        = 96,
	["tableExists"]    = 92
}

function CElog(string, heading, funcname, host)
	heading = heading or "Cobalt"

	local out = ("[" .. color(90) .. os.date("%d/%m/%Y %X", os.time()) .. color(0) ..  "]"):gsub("/0","/"):gsub("%[0","[")

	if heading == "WARN" then
		out =  out .. " [" .. color(31) .. "WARN" .. color(0) .. "] " .. color(31) .. string
	elseif heading == "RCON" then
		out = out .. " [" .. color(33) .. "RCON" .. color(0) .. "] " .. color(0) .. string
	elseif heading == "CobaltDB" then

		out = out .. " [" .. color(35) .. "CobaltDB" .. color(0) .. "] "

		if funcname then
			if host then out = out .. "[" .. color(32) .. host .. color(0) .. "] " end
			out = out .. "["
			if funcColor[funcname] then out = out .. color(funcColor[funcname]) end
			out = out .. funcname .. color(0) .. "] " .. string
		else
			out = out .. color(0) .. string
		end

	elseif heading == "CHAT" then
		out = out .. " [" .. color(32) .. "CHAT" .. color(0) .. "] " .. color(0) .. string
	elseif heading == "DEBUG" and (config == nil or config.enableDebug.value == true) then
		out = out .. " [" .. color(97) .. "DEBUG" .. color(0) .. "] " .. color(0) .. string
	else
		out = out .. " [" .. color(94) .. heading .. color(0) .. "] " .. color(0) .. string
	end


	out = out .. color(0)
	MP.PrintRaw(out)
	return out
end

--changes the color of the console.
function color(fg,bg)
	if (config == nil or config.enableColors.value == true) and true then
		if bg then
			return string.char(27) .. '[' .. tostring(fg) .. ';' .. tostring(bg) .. 'm'
		else
			return string.char(27) .. '[' .. tostring(fg) .. 'm'
		end
	else
		return ""
	end
end

function split(s, sep)
	local fields = {}

	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

	return fields
end

--PRE: ID is passed in, representing a player ID, an RCON ID, or C to print into console with message, a valid string.
--POST: message is output to the desired destination, if sent to players \n is seperated.

--IDs | "C" = console | "R<N>" = RCON | "<number>" = player
function output(ID, message)
	if ID == nil then
		error("ID is nil")
	end
	if message == nil then
		error("message is nil")	
	end

	if type(ID) == "string" then

		if ID == "C" then
			CElog(message)
		elseif ID:sub(1,1) == "R" then
			TriggerGlobalEvent("RCONsend", ID, message)
		end
	
	elseif type(ID) == "number" then
		SendChatMessage(ID, message)
	else
		error("Invalid ID")
	end
end

-- PRE: number, time in seconds is passed in, followed by boolean hours, boolean minutes, boolean seconds, boolean milliseconds.
--POST: the formatted time is output as a string.
function formatTime(time)
	time = math.floor((time * 1000) + 0.5)
	local milliseconds = time % 1000
	time = math.floor(time/1000)
	local seconds = time % 60
	time = math.floor(time/60)
	if seconds < 10 then
		seconds = "0" .. seconds
	end
	if time < 10 then
		time = "0" .. time
	end
	if milliseconds < 10 then
		milliseconds = "00" .. milliseconds
	elseif milliseconds < 100 then
		milliseconds = "0" .. milliseconds
	end

	return  time ..":".. seconds .. ":" .. milliseconds
end






-- FS related functions
local function readJson(path)
	if not FS.Exists(path) then
		return nil, "File does not exist"
	end

	local jsonFile, error = io.open(path,"r")
	if not jsonFile or error then
		return nil, error
	end

	local jsonText = jsonFile:read("*a")
	jsonFile:close()
	local success, data = pcall(json.parse, jsonText)

	if not success then
		print("Error while parsing file", path, data)
		return nil, "Error while parsing JSON"
	end

	return data, nil
end

local function writeJson(path, data)
	local success, error = FS.CreateDirectory(FS.GetParentFolder(path))

	if not success then
		CElog('failed to create directory for file "' .. tostring(path) .. '", error: ' .. tostring(error),"WARN")
		return false, error
	end

	local jsonFile, error = io.open(path,"w")
	if not jsonFile or error then
		return nil, error
	end

	jsonFile:write(json.stringify(data or {}))
	jsonFile:close()

	return true, nil
end
-- FS related functions



M.readJson = readJson
M.writeJson = writeJson


return M