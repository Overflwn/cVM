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
			"rom/testfolder/test"
		},
		["fileData"] = {
			"Hello!"
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
	hdPath = path

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
	for k, v in ipairs(inhalt.sector1.files) do
		local file = fs.open("/tmp/"..fs.getName(path).."/"..v, "w")
		file.write(inhalt.sector1.fileData[k])
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
	local thisHD = inhalt
	local file = fs.open("/dummyFS", "r")
	local inhalt = file.readAll()
	file.close()
	local file = fs.open("/tmpfs", "w")
	file.writeLine("rootPath='".."/tmp/"..fs.getName(path).."/'")
	file.write(inhalt)
	file.close()
	os.loadAPI("/tmpfs")
	env.fs = tmpfs
	local forbidden = {"colors", "colours", "disk", "gps", "help", "io", "keys", "paintutils", "parallel", "peripheral", "rednet", "settings", "textutils", "vector", "window"}
	for k, v in ipairs(forbidden) do
		env[v] = nil
	end
	env._G = env
	setfenv(bios, env)
	--shell.setPath("/tmp/"..fs.getName(path).."/")
	print("Starting HD")
	local c1 = coroutine.create(bios)
	local evt = {}
	local function rb()
		c1 = coroutine.create(bios)
	end

	local function sd()
		local function nothin()
			return "shutdown"
		end
		c1 = coroutine.create(nothin)
	end



	env.os.shutdown = function()
		return sd()
	end

	env.os.reboot = function()
		return rb()
	end
	while true do
		local ok, err = coroutine.resume(c1, unpack(evt))
		if ok == false then
			printError("Bios:"..err)
		elseif err == "shutdown" then
			break
		end
		evt = {os.pullEventRaw()}
		if evt[1] == "key" and evt[2] == keys.delete then
			break
		elseif coroutine.status(c1) == "dead" then
			break
		end
	end
	local function list(path)
		local root = {}
		local fData = {}
		for k, v in ipairs(fs.list(path)) do
			table.insert(root, v)
			if fs.isDir(path.."/"..v) then
				local g, h = list(path.."/"..v)
				for _, a in ipairs(g) do
					table.insert(root, v.."/"..a)
				end
				for _, a in ipairs(h) do
					table.insert(fData, a)
				end
			else
				local file, err = fs.open(path.."/"..v, "r")

				local inhalt = file.readAll()
				file.close()
				table.insert(fData, inhalt)
			end
		end
		return root, fData
	end
	local roott, rootf = list("/tmp/"..fs.getName(hdPath).."/")
	thisHD.sector1.folders = {}
	thisHD.sector1.files = {}
	thisHD.sector1.fileData = {}
	for k, v in ipairs(roott) do
		if fs.isDir("/tmp/"..fs.getName(hdPath).."/"..v) then
			table.insert(thisHD.sector1.folders, v)
		else
			table.insert(thisHD.sector1.files, v)
		end
	end
	for k, v in ipairs(rootf) do
		table.insert(thisHD.sector1.fileData, v)
	end
	local file = fs.open(hdPath, "w")
	file.write(textutils.serialize(thisHD))
	file.close()
	fs.delete("/tmp/"..fs.getName(hdPath))
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