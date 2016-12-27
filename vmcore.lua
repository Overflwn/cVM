thisHD = {}

_fs = {}
function _fs.find(path)
	local inode = 0
	if #path < 1 then return end
	if string.find(path, "/") == 1 and #path > 1 then path = string.sub(path, 2) end
	if not string.find(path, "/", #path) then path = path.."/" end
	local h, j = string.find(path, "/")
	local nP = ""
	local nString = ""
	if h and #path > 1 then
		nP = string.sub(path, 1, h-1)
		nString = string.sub(path, h+1)
	end
	local cBlock = 2
	repeat
		if #nP > 1 and #nString > 1 then
			if not thisHD.sector1.blocks[cBlock][nP] then return false, "No such file." end
			local iNumbr = thisHD.sector1.blocks[cBlock][nP]
			if not thisHD.sector1.inodes[iNumbr].type==0 then return false, "Not a directory." end
			cBlock = thisHD.sector1.inodes[iNumbr].block
			h, j = string.find(nString, "/")
			if #nString > 1 and h then
				nP = string.sub(nString, 1, h-1)
				nString = string.sub(nString, h+1)
			elseif #nString > 1 and not h then
				nP = nString
				nString = ""
			else
				nString = ""
				nP = ""
			end
		elseif #nP > 1 and #nString < 1 then
			if not thisHD.sector1.blocks[cBlock][nP] then return false, "No such file." end
			if not thisHD.sector1.inodes[thisHD.sector1.blocks[cBlock][nP]].type==1 then return false, "No such file." end
			inode = thisHD.sector1.blocks[cBlock][nP]
			nP = ""
		end
	until #nP < 1
	return inode
end

function _fs.list(path)
	if #path < 1 then return end
	if string.find(path, "/") == 1 and #path > 1 then path = string.sub(path, 2) end
	if not string.find(path, "/", #path) then path = path.."/" end
	local h, j = string.find(path, "/")
	local nP = ""
	local nString = ""
	if h and #path > 1 then
		nP = string.sub(path, 1, h-1)
		nString = string.sub(path, h+1)
	end
	local root = {}
	for k, v in pairs(thisHD.sector1.blocks[2]) do
		table.insert(root, k)
	end
	local cBlock = 2
	repeat
		if #nP > 1 then
			if not thisHD.sector1.blocks[cBlock][nP] then return false, "No such directory." end
			local iNumbr = thisHD.sector1.blocks[cBlock][nP]
			if not thisHD.sector1.inodes[iNumbr].type==0 then return false, "Not a directory." end
			root = {}
			for k, v in pairs(thisHD.sector1.blocks[thisHD.sector1.inodes[iNumbr].block]) do
				table.insert(root, k)
			end
			cBlock = thisHD.sector1.inodes[iNumbr].block
			h, j = string.find(nString, "/")
			if #nString > 1 and h then
				nP = string.sub(nString, 1, h-1)
				nString = string.sub(nString, h+1)
			elseif #nString > 1 and not h then
				nP = nString
				nString = ""
			else
				nString = ""
				nP = ""
			end
		end
	until #nP < 1
	return root
end

function _fs.listData(path)
	local ind = _fs.find(path)
	if not type(ind) == "number" then return false, "Not such file." end
	if thisHD.sector1.inodes[ind].type == 0 then return false, "Is a directory." end
	return thisHD.sector1.blocks[thisHD.sector1.inodes[ind].block]
end

function _fs.fEdit(inode, operation, itype, data)
	if operation == "add" then
		thisHD.sector1.inodes[thisHD.sector1.inodes.last_inode+1] = {
			type = itype,
			block = thisHD.sector1.blocks.last_block+1,
		}
		thisHD.sector1.blocks[thisHD.sector1.blocks.last_block+1] = data
		thisHD.sector1.blocks.last_block = thisHD.sector1.blocks.last_block+1
		thisHD.sector1.inodes.last_inode = thisHD.sector1.inodes.last_inode+1
		return thisHD.sector1.inodes.last_inode
	elseif operation == "edit" then
		thisHD.sector1.inodes[inode].type = itype
		thisHD.sector1.blocks[thisHD.sector1.inodes[inode].block] = data
	end
end

function _fs.open(path, mode)
	local file = {}
	if mode == "w" then
		if type(_fs.find(path)) == "number" then
			if thisHD.sector1.inodes[_fs.find(path)].type == 0 then return false, "Is a directory." end
		end
		local ind = nil
		if _fs.find(path) then
			ind = _fs.find(path)
		end
		file = {
			dat = "",
			pth = path,
			id = ind,
			write = function(data)
				if type(data) == "string" then
					file.dat = data
				end
			end,
			writeLine = function(data)
				if type(data) == "string" then
					file.dat = file.dat.."\n"..data
				end
			end,
			close = function()
				if file.id then
					return _fs.fEdit(ind, "edit", 1, file.dat)
				else
					local newind = _fs.fEdit(0, "add", 1, file.dat)
					local nDat = thisHD.sector1.blocks[thisHD.sector1.inodes[2].block]
					nDat[_fs.getName("asdasdas/"..file.pth)] = newind
					return _fs.fEdit(2, "edit", 0, nDat)
				end
			end,
		}
		return file
	elseif mode == "r" then
		local dat, err = _fs.listData(path)

		if not type(dat) == "string" then return false, err end
		file = {
			readAll = function()
				return dat
			end,
			readLine = function()
				local h, j = string.find(dat, "[\]n")
				if h then
					local s = string.sub(dat, h-1)
					dat = string.sub(dat, j+1)
					return s
				else
					return dat
				end
			end,
			close = function()
				return nil
			end,
		}
		return file
	end
end

function _fs.makeDir(path)
	if string.find(path, "/") == 1 then path = string.sub(path, 2) end
	local ppp = string.reverse(path)
	local pp = string.reverse(path)
	local p = string.reverse(path)
	local h, j = string.find(ppp, "/")
	if h then
		p = string.sub(ppp, 1, h-1)
		pp = string.sub(ppp, h+1)
	end
	p = string.reverse(p)
	pp = string.reverse(pp)
	if type(_fs.find(path)) == "number" then return nil end
	if not thisHD.sector1.inodes[_fs.find(pp)].type == 0 then return nil end
	local newInode = _fs.fEdit(0, "add", 0, {})
	local t = thisHD.sector1.blocks[thisHD.sector1.inodes[_fs.find(pp)].block]
	t[p] = newInode
	_fs.fEdit(_fs.find(pp), "edit", 0, t)
	return true
end

function _fs.exists(path)
	local ok = _fs.find(path)
	if type(ok) == "boolean" then
		return false
	else
		return true
	end
end

function _fs.isDir(path)
	local ok = _fs.find(path)
	if type(ok) == "boolean" then return false, "Path doesn't exist." end
	if thisHD.sector1.inodes[ok].type == 0 then
		return true
	else
		return false
	end
end

function _fs.isReadOnly(path)
	if _fs.exists(path) then
		local ok = _fs.find(path)
		return thisHD.sector1.inodes[ok].readOnly
	end
end

function _fs.getName(path)
	if string.find(path, "/") == 1 then path = string.sub(path, 2) end
	if string.find(path, "/", #path) then path = string.sub(path, 1, #path-1) end
	local ppp = string.reverse(path)
	local pp = string.reverse(path)
	local p = string.reverse(path)
	local h, j = string.find(ppp, "/")
	if h then
		p = string.sub(ppp, 1, h-1)
		pp = string.sub(ppp, h+1)
	end
	p = string.reverse(p)
	pp = string.reverse(pp)
	return p
end

function _fs.getDir(path)
	if string.find(path, "/") == 1 then path = string.sub(path, 2) end
	local ppp = string.reverse(path)
	local pp = string.reverse(path)
	local p = string.reverse(path)
	local h, j = string.find(ppp, "/")
	if h then
		p = string.sub(ppp, 1, h-1)
		pp = string.sub(ppp, h+1)
	end
	p = string.reverse(p)
	pp = string.reverse(pp)
	return pp
end

function _fs.move(p1, p2)
	local parent1 = _fs.getDir(p1)
	local parent2 = _fs.getDir(p2)
	local name1 = _fs.getName(p1)
	local name2 = _fs.getName(p2)
	if _fs.exists(parent1) and _fs.exists(parent2) and _fs.exists(p1) and not _fs.exists(p2) then
		local parent1In = _fs.find(parent1)
		local parent2In = _fs.ind(parent2)
		local oldDat = thisHD.sector1.blocks[thisHD.sector1.inodes[parent1In].block][name1]
		thisHD.sector1.blocks[thisHD.sector1.inodes[parent1In].block][name1] = nil
		thisHD.sector1.blocks[thisHD.sector1.inodes[parent2In].block][name2] = oldDat
	end
end

function _fs.copy(p1, p2)
	local parent1 = _fs.getDir(p1)
	local parent2 = _fs.getDir(p2)
	local name1 = _fs.getName(p1)
	local name2 = _fs.getName(p2)
	if _fs.exists(parent1) and _fs.exists(parent2) and _fs.exists(p1) and not _fs.exists(p2) then
		local parent2In = fFind(parent2)
		local oldDat = thisHD.sector1.blocks[thisHD.sector1.inodes[parent1In].block][name1]
		local newIn = _fs.fEdit(0, "add", thisHD.sector1.inodes[fFind(p1)].type, oldDat)
		thisHD.sector1.blocks[thisHD.sector1.inodes[parent2In].block][name2] = newIn
	end
end

function _fs.combine(p1, p2)
	if string.find(p1, "/") == #p1 then p1 = string.sub(p1, 1, #p1-1) end
	if string.find(p2, "/") == 1 then p2 = string.sub(p2, 2) end
	return p1.."/"..p2
end

function _fs.complete()
	return nil
end

function _fs.delete(path)
	if _fs.exists(path) then
		local ind = _fs.find(path)
		thisHD.sector1.blocks[thisHD.sector1.inodes[ind].block] = nil
		thisHD.sector1.inodes[ind] = {}
		for k, v in pairs(thisHD.sector1.blocks) do
			if type(v) == "table" then
				for a, b in pairs(v) do
					if a == _fs.getName(path) and b == ind then
						thisHD.sector1.blocks[k][a] = nil
						break
					end
				end
			end
		end
		return true
	else
		return false, "Path doesn't exist."
	end
	return false, "unknown error"
end

function _fs.getDrive(path)
	if _fs.exists(path) then
		return "cVMBox"
	end
end

function _fs.getFreeSpace()
	return fs.getFreeSpace()
end

function _fs.getSize(path)
	if _fs.exists(path) and not _fs.isDir(path) then
		local ok = _fs.find(path)
		local inhalt = thisHD.sector1.blocks[_fs.inodes[ok].block]
		if type(inhalt) == "table" then
			inhalt = textutils.serialize(inhalt)
		end
		local size = string.byte(inhalt)
	end
end









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


--[[

							EXPERIMENTAL BUILD!!!!!


	This build uses the new filesystem (inode-system)

	This makes the filesystem "completely virtual"


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
		inodes = {
			[2] = {
				type = 0,
				block = 2,
				readOnly = false,
			},
			[1] = {
				type=1,
				block=1,
				readOnly = false,
			},
			[3] = {
				type=0,
				block=3,
				readOnly = false,
			},
			[4] = {
				type=1,
				block=4,
				readOnly = false,
			},
			last_inode = 4,
		},
		blocks = {
			[2] = {
				rom = 3,
				testFile=1,
			},
			[1] = "hello, world!",
			[3] = {
				romFile=4,
			},
			[4] = "Hello, ROM",
			last_block = 4,
		},
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
	--[[fs.makeDir("/tmp/"..fs.getName(path))
	for k, v in ipairs(inhalt.sector1.folders) do
		fs.makeDir("/tmp/"..fs.getName(path).."/"..v)
	end
	for k, v in ipairs(inhalt.sector1.files) do
		local file = fs.open("/tmp/"..fs.getName(path).."/"..v, "w")
		file.write(inhalt.sector1.fileData[k])
		file.close()
	end]]
	print("Loading bios.")
	local bios, err = loadstring(inhalt.bootSector["bios.lua"])
	if not bios then return false, err end
	print(tostring(bios))
	local env = {}

	--Here is the list of things that get imported from the current _G, usually basic LUA stuff and the term API
	local allowed = {
		"assert",
		"collectgarbage",
		"dofile",
		"error",
		"getfenv",
		"getmetatable",
		"ipairs",
		"load",
		"loadstring",
		"module",
		"next",
		"pairs",
		"pcall",
		"print",
		"rawequal",
		"rawget",
		"rawset",
		"require",
		"select",
		"setfenv",
		"setmetatable",
		"tonumber",
		"tostring",
		"type",
		"unpack",
		"xpcall",
		"coroutine",
		"io",
		"math",
		"os",
		"string",
		"table",
		"term",
		"peripheral",
		"http",
		"vector",
		"read",
		"loadfile"
	}
	--[[for k, v in pairs(_G) do
		env[k] = v
	end]]
	for k, v in ipairs(allowed) do
		env[v] = _G[v]
	end
	env['loadfile'] = function(p)
		local f = env.fs.open(p, "r")
		local inhalt = f.readAll()
		f.close()
		local a = loadstring(inhalt)
		setfenv(a, env)
		return a
	end
	thisHD = inhalt
	local file = fs.open("/dummyFS", "r")
	local inhalt = file.readAll()
	file.close()
	local file = fs.open("/tmpfs", "w")
	file.writeLine("rootPath='".."/tmp/"..fs.getName(path).."/'")
	file.write(inhalt)
	file.close()
	os.loadAPI("/tmpfs")
	env.fs = _fs
	--[[local forbidden = {"colors", "colours", "disk", "gps", "help", "keys", "paintutils", "parallel", "rednet", "settings", "textutils", "window"}
	for k, v in ipairs(forbidden) do
		env[v] = nil
	end]]
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
	--[[local roott, rootf = list("/tmp/"..fs.getName(hdPath).."/")
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
	end]]
	local file = fs.open(hdPath, "w")
	file.write(textutils.serialize(thisHD))
	file.close()
	--fs.delete("/tmp/"..fs.getName(hdPath))
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