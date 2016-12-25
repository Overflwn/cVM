--[[
		cVMWare

	A WIP "virtual machine"-manager in CC.

	In case I didn't commit in a long time and this
	is not working, you are free to modify and maybe
	fix the code.

	~Piorjade
]]

--[[
		INFO:

	This is the "core" of cVM

	It has no GUI, so it's meant to be used in the commandline
	with arguments.

	The current idea of virtual machines has a problem:

	It makes "gigantic" virtual "hard-drives".

]]

--Variablen
_ver=0.1

_hdTemplate = {
	["bootSector"] = {
		["bios.lua"] = nil
	},
	["sector0"] = {
		["disk"] = nil,
	},
	["sector1"] = {
		["folders"] = {
			"rom",
			"rom/testfolder"
		},
		["files"] = {
			["rom/testfolder/test"] = "print('hello')"
		}
	}
}
--Funktionen

local function createHardDrive(path)
	if fs.exists(path) then return false, "File already exists." end
	local file, err = fs.open(path, "w")
	if not file then return false, err end
	file.write(textutils.serialize(_hdTemplate))
	file.close()
end

local function runHardDrive(path)
	if fs.exists("/tmp/"..fs.getName(path)) then fs.delete("/tmp/"..fs.getName(path)) end
	sleep(2)
	if not fs.exists(path) then return false, "File does not exist." end
	local file, err = fs.open(path, "r")
	if not file then return false, err end
	local inhalt = file.readAll()
	inhalt = textutils.unserialize(inhalt)
	file.close()
	if not inhalt.bootSector["bios.lua"] then return false, "No bios.lua." end
	fs.makeDir("/tmp/"..fs.getName(path))
	for k, v in ipairs(inhalt.sector1.folders) do
		fs.makeDir("/tmp/"..fs.getName(path).."/"..v)
	end
	for k, v in pairs(inhalt.sector1.files) do
		local file = fs.open("/tmp/"..fs.getName(path).."/"..k, "w")
		file.write(v)
		file.close()
	end
	print("Loading bios.")
	local bios, err = loadstring(inhalt.bootSector["bios.lua"])
	if not bios then return false, err end
	print(tostring(bios))
	local env = {}
	for k, v in pairs(_G) do
		env[k] = v
	end

	local forbidden = {"colors", "colours", "disk", "gps", "help", "io", "keys", "paintutils", "parallel", "peripheral", "rednet", "settings", "term", "textutils", "vector", "window"}
	for k, v in ipairs(forbidden) do
		env[v] = nil
	end
	env["_vmpath"] = "/tmp/"..fs.getName(path).."/"
	env._G = env
	--[[env.fs.open = function(p, mode)
		return env.old.fs.open(env._vmpath..p, mode)
	end
	env.fs.list = function(p)
		return fs.list(env._vmpath..p)
	end
	env.fs["test"] = function()
		print(env._vmpath)
		print(type(env.old))
		return print(type(fs))
	end
	env.fs.getDrive = function(p)
		return env.old.fs.getDrive(env._vmpath..p)
	end
	env.fs.getSize = function(p)
		return env.old.fs.getSize(env._vmpath..p)
	end
	env.fs.getFreeSpace = function(p)
		return env.old.fs.getFreeSpace(env._vmpath..p)
	end
	env.fs.makeDir = function(p)
		return env.old.fs.makeDir(env._vmpath..p)
	end
	env.fs.move = function(p1, p2)
		return env.old.fs.move(envd._vmpath..p1, env._vmpath..p2)
	end
	env.fs.copy = function(p1, p2)
		return env.old.fs.copy(env._vmpath..p1, env._vmpath..p2)
	end
	env.fs.delete = function(p)
		return env.old.fs.delete(env._vmpath..p)
	end
	env.fs.find = function(p)
		return env.old.fs.find(env._vmpath..p)
	end]]
	setfenv(bios, env)
	--shell.setPath("/tmp/"..fs.getName(path).."/")
	print("Starting HD")
	local oldG = {}
	for k, v in pairs(_G) do
		oldG[k] = v
	end
	local ok, err = bios()
	for k, v in pairs(oldG) do
		_G[k] = v
	end
	--shell.setPath("/")
	print("Finished!")
end

local function setBios(p, bp)
	if not fs.exists(p) then return false, "HD not found!" end
	if not fs.exists(bp) then return false, "BIOS not found!" end
	local file = fs.open(p, "r")
	local inhalt = file.readAll()
	inhalt = textutils.unserialize(inhalt)
	file.close()
	local file = fs.open(bp, "r")
	inhalt.bootSector["bios.lua"] = file.readAll()
	file.close()
	local file = fs.open(p, "w")
	file.write(textutils.serialize(inhalt))
	file.close()
end
--Code

local tArgs = {...}

if #tArgs < 1 then
	print("Usage:")
	print("		createHD <path>")
	print("		runHD <path> <pathToBios>")
	print("		insertDisk <folder> <pathToHD>")
	print("		insertBios <pathToHD> <pathToBios>")
elseif tArgs[1] == "info" then
	print("		INFO:")
	print("- Virtual Machines can have only 1 disk inserted")
	print("- Other peripherals are currently NOT supported")
elseif tArgs[1] == "createHD" and #tArgs == 2 then
	local ok, err = createHardDrive(tArgs[2])
	if ok == false then
		printError(err)
	else
		print("Successfully created!")
	end
elseif tArgs[1] == "insertBios" and #tArgs == 3 then
	local ok, err = setBios(tArgs[2], tArgs[3])
	if ok == false then
		printError(err)
	else
		print("End.")
	end
elseif tArgs[1] == "runHD" and #tArgs == 2 then
	local ok, err = runHardDrive(tArgs[2])
	if ok == false then
		printError(err)
	else
		print("End.")
	end
else
	print("Usage:")
	print("		createHD <path>")
	print("		runHD <path>")
	print("		insertDisk <folder> <pathToHD>")
	print("		insertBios <pathToHD> <pathToBios>")
end