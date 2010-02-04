#!/usr/bin/env lua
--[[
This client should be run on your PC
]]

from_watch="/dev/ttyUSB2"
local local_dir = "../"
if arg[1] then
	from_watch=tostring(arg[1])
end
local file_types = {".+%.lua$",".+%.pnnng$"}
to_watch=from_watch

local fd=io.open(local_dir.."_SYS")
if not fd then
	print ("****ERROR: bad local_dir value ("..tostring(local_dir)..")")
	print ("It should point to SD card root dir (where _SYS is located)")
	os.exit()
else
	fd:close()
end

local serfunc = {
	boolean = function (x) return tostring(x) end,
	number = function (x) return tostring(x) end,
	string = function(str) return string.format("%q",str) end,
}

local function serialize(neco)
	if type(neco)=="table" then
		local result = {}
		for k,v in pairs(neco) do
			local serk=nil
			serk="["..serialize(k).."]"
			table.insert(result, serk.."="..serialize(v))
		end
		table.sort(result)
		return "{"..table.concat(result,",").."}"
	else
		local fun = serfunc[type(neco)]
		assert(fun, "Unable to serialize ".. tostring(neco) ..".")
		return fun(neco)
	end
end

local function split_string(str)
	assert(type(str)=="string" and #str > 0)
	local chunks={}
	local chunksize=200
	for pointer = 1, #str, chunksize do
		local to = pointer + chunksize - 1
		if to > #str then
			to = #str
		end
		local chunk=str:sub(pointer,to)
		chunk = chunk:gsub(".",function(chr)
			if chr >"!" and chr <= "~" then
				return chr
			else
				return string.format("!%03d",string.byte(chr))
			end
		end)
		table.insert(chunks, chunk)
	end
	return chunks
end

local function get_files()
	local stats={}
	local dirmatch = local_dir:gsub("%.","%%%.")
	--print("dirmatch = "..dirmatch)
	local lsd=assert(io.popen("ls -Rl "..local_dir,"r"))
	local dir_name
	for line in lsd:lines() do
		--print ("line:"..line)
		local dirname0 = line:match("^"..dirmatch.."(.-):$")
		if dirname0 then
			dir_name=dirname0
			--print ("dir: "..dir_name)
		else
			--print (line)
			local fname = line:match("%d%d%d%d%-%d%d%-%d%d %d%d:%d%d (.+)$")
			if fname then 
				local match=false
				for i,typ in ipairs(file_types) do
					if fname:match(typ) then
						match=true
						break
					end
				end
				if match then
					local fullname=fname
					if dir_name ~= "" then
						fullname = dir_name.."/"..fname
					end
					--print(fullname)
					stats[fullname]=line
				end
				--print("file: "..fname.." - "..local_dir..fname)
			end
		end
	end
	lsd:close()
	return stats
end

local function decode(str)
	local decoded=str:gsub("!(%d%d%d)",function(ch4)
		--print("HAVE CHAR")
		return string.char(tonumber(ch4))
	end)
	return decoded
	--return (decoded:gsub("\\\n","\n"))
end

--get_files(local_dir)
--split_file("pc.lua")

--os.exit()

local function send_raw(str)
	assert(fd_to):write(str.."\n")
end

function send(data)
	assert(type(data)=="table", "Data is not a table but "..type(data))
	local ser = assert(serialize(data))
	local chunks = split_string(ser)
	send_raw("DATA_START")
	io.write("Sending data")
	for i, chunk in ipairs(chunks) do
		send_raw("CHUNK "..chunk)
		io.write(".")
		io.output():flush()
	end
	send_raw("DATA_END")
	io.write("\n")
end

local function main_loop(fd_from)
	local id=0
	while(true) do
		local line=fd_from:read("*l")
		if not line then 
			fd_from:close()
			fd_to:close()
			print("Disconnected. Trying to reconnect...")
			os.execute("sleep 5")
			return
		end
		id=id+1
		if line=="DATA_START" then
			local chunks = {"return "}
			repeat
				local chunk = assert(fd_from:read())
				if chunk == "DATA_END" then
					chunk=nil
				end
				if chunk then
					local str=assert(chunk:match("CHUNK (%S+)"),"No chunk data in "..chunk)
					table.insert(chunks,str)
				end
			until not chunk
			local data0 = decode(table.concat(chunks))
			local load = loadstring(data0)
			if not load then
				print("*** DATA TRANSFER ERROR ***")
				print("Received and decoded: "..data0)
				error()
			end
			local data = loadstring(data0)()
			assert(type(data)=="table")
			if data.runtime_error then
				print("*** RUNTIME ERROR ***")
				print (data.runtime_error)
			else
				print("*** Unknown data: "..data0)
			end
		elseif line=="WHATS_NEW?" then
			local to_send={}
			local msg = ""
			local num=0
			local new_stats=get_files()
			for k,v in pairs(new_stats) do
				if old_stats[k] ~= v then
					local fd=assert(io.open(local_dir..k))
					local file=assert(fd:read("*a"))
					fd:close()
					to_send["/"..k]=file
					msg=msg..";"..k
					num=num+1
				end
			end
			print("Updating "..num.." files on device.")
			send{message=msg,files_to_update=to_send}
			old_stats=new_stats
		else
			print (id.." <"..line..">")
		end

	end
end

old_stats={}

print("Connecting to "..from_watch)
while(true) do
	local fd_from = io.open(from_watch)
	if fd_from then
		fd_to = assert(io.open(to_watch,"w"))
		print("Connected")
		main_loop(fd_from)
	end
	--os.execute("sleep 1")
end

--[[
	TCH vraci $0a na konci radku.
	V Lue na Linuxu: "\n" = $0a, "\r" = $0c
]]

