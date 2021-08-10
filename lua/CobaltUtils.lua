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
		if funcname then
			out = out .. " [" .. color(35) .. "CobaltDB" .. color(0) .. "] "
			if host then out = out .. "[" .. color(32) .. host .. color(0) .. "] " end
			out = out .. "["
			if funcColor[funcname] then out = out .. color(funcColor[funcname]) end
			out = out .. funcname .. color(0) .. "] " .. string
		else
			out = out .. " [" .. color(35) .. "CobaltDB" .. color(0) .. "] " .. color(0) .. string
		end
	elseif heading == "CHAT" then
		out = out .. " [" .. color(32) .. "CHAT" .. color(0) .. "] " .. color(0) .. string
	elseif heading == "DEBUG" and (config == nil or config.enableDebug.value == true) then
		out = out .. " [" .. color(97) .. "DEBUG" .. color(0) .. "] " .. color(0) .. string
	else
		out = out .. " [" .. color(94) .. heading .. color(0) .. "] " .. color(0) .. string
	end


	out = out .. color(0)
	print(out)
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

-- https://stackoverflow.com/a/40195356/7137271
local function exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

local function isDir(path)
	-- "/" works on both Unix and Windows
	--print(debug.getinfo(2).name)
	--print(path)
	return exists(path.."/")
end

local function createDirectory(path)
	if os.getenv('HOME') then
		os.execute("mkdir " .. path:gsub("\\","/"))
	else
		os.execute("mkdir " .. path:gsub("/","\\"))
	end
end

local function createDirectoryRec(path)
	if isDir(path) then return end
	path = path:sub(1,#path-1)
	local parent = string.match(path, "(.*[\\/])")
	if not isDir(parent) then createDirectoryRec(parent) end

	createDirectory(path)
end

local function copyFile(src, dst)
	if os.getenv('HOME') then
		os.execute(string.format("cp %s %s",src:gsub('\\', '/'), dst:gsub('\\','/')))
	else
		os.execute(string.format("copy %s %s",src:gsub('/', '\\'), dst:gsub('/','\\')))
	end
end

local function getPathSplit(path)
	local dir = string.match(path, "(.*[\\/])")
	path = path:sub(#(dir and dir..' ' or ''))
	local name, ext = string.match(path, "(.+)(%.%w+)$")
	return dir or '', name, ext
end

local function readJson(path)
	local jsonFile, error = io.open(path,"r")
	if error then return nil, error end

	local jsonText = jsonFile:read("*a")
	jsonFile:close()
	local success, data = pcall(json.parse, jsonText)
	
	if not success then
		print("error while parsing file", path, data)
		return nil, true
	end

	return data, false
end

local function writeJson(path, data)
	local dir, fname, ext = getPathSplit(path)

	if not isDir(dir) then createDirectoryRec(dir) end

	local jsonFile, error = io.open(path,"w")
	if error then return false end

	jsonFile:write(json.stringify(data or {}))
	jsonFile:close()

	return true
end

--read a .cfg file and return a table containing it's files
local function readCfg(path)
	print("readcfg")
	local cfg = {}
	
	local n = 1

	local file = io.open(path,"r")

	local line = file:read("*l") --get first value for line
	while line ~= nil do

		--remove comments
		local c = line:find("#")

		if c ~= nil then
			line = line:sub(1,c-1)
		end

		--see if this line even contians a value
		local equalSignIndex = line:find("=")
		if equalSignIndex ~= nil then
			
			local k = line:sub(1, equalSignIndex - 1)
			k = k:gsub(" ", "") --remove spaces in the key, they aren't required and will serve to make thigns more confusing.

			local v = line:sub(equalSignIndex + 1)

			v = load("return " ..  v)()
			
			cfg[k] = v
		end


		--get next line ready
		line = file:read("*line")
	end

	if cfg.Name then
		cfg.rawName = cfg.Name
		local s,e = cfg.Name:find("%^")
		while s ~= nil do

			if s ~= nil then
				cfg.Name = cfg.Name:sub(0,s-1) .. cfg.Name:sub(s+2)
			end
		
			s,e = cfg.Name:find("%^")
		end
	end

	return cfg
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

M.copyFile = copyFile
M.exists = exists
M.isDir = isDir
M.getPathSplit = getPathSplit
M.createDirectory = createDirectory

M.readJson = readJson
M.writeJson = writeJson
M.readCfg = readCfg

return M