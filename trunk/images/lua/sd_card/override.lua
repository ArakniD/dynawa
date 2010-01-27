_G.dynawa.debug = {}

local serfunc = {
	boolean = function (x) return tostring(x) end,
	number = function (x) return tostring(x) end,
	string = function(str) return string.format("%q",str) end,
	userdata = function(str) return ("<!"..tostring(x)..">") end,
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
	local chunksize=100
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

function dynawa.debug.send_raw(str)
	io.write(str.."\n")
	io.output():flush()
end

function dynawa.debug.receive_raw()
	local line = io.read("*l")
	assert(line,"Cannot read from stdin")
	return line
end

local function chunks_decode(str)
	local decoded=str:gsub("!(%d%d%d)",function(ch4)
		return string.char(tonumber(ch4))
	end)
	return decoded
end

function dynawa.debug.receive(line1)
	local rec = dynawa.debug.receive_raw
	if not line1 then
		line1 = rec()
	end
	assert(line1=="DATA_START","Expected DATA_START, got "..line1.." instead")
	
	local chunks = {"return "}
	repeat
		local chunk = rec()
		if chunk == "DATA_END" then
			chunk=nil
		end
		if chunk then
			local str=assert(chunk:match("CHUNK (%S+)"),"No chunk data in "..chunk)
			table.insert(chunks,str)
		end
	until not chunk
	local data = chunks_decode(table.concat(chunks))
	data = loadstring(data)()
	assert(type(data)=="table","Received data is not table but "..type(data))
	return data
end

function dynawa.debug.send(data)
	assert(type(data)=="table", "Data is not a table but "..type(data))
	local ser = assert(serialize(data))
	local send_raw = dynawa.debug.send_raw
	local chunks = split_string(ser)
	send_raw("DATA_START")
	for i, chunk in ipairs(chunks) do
		send_raw("CHUNK "..chunk)
	end
	send_raw("DATA_END")
end

local errfunc=function(errstat)
	local tback = debug.traceback(errstat)
	--[[local start,msg,rest = tback:match("^(%S- )([^\n]*)(.+)$")
	if rest == rest then
		tback = "<b>"..tostring(start) .. "<font color=red>"..tostring(msg).."</font></b>"..tostring(rest)
	end]]
	return tback
end
	
function dynawa.debug.update_files() --Asks for updated files and installs them to SD card
	dynawa.debug.send_raw("WHATS_NEW?")
	local reply=dynawa.debug.receive_raw()
	if reply=="BYE" then
		return
	end
	local data = dynawa.debug.receive(reply)
	dynawa.debug.send_raw("UPDATING_FILES")
	local files=data.files_to_update
	assert(files,"'files_to_update' not present in received data")
	for fname,file in pairs(files) do
		local fd = assert(io.open(fname,"w"),"Cannot open file "..fname.." for writing")
		fd:write(file)
		fd:close()
	end
	dynawa.debug.send_raw("FILES_UPDATED")
end

function dynawa.debug.main_handler(event)
	--dynawa.debug.send_raw("DEBUG.MAIN_HANDLER")
	
	if event.button == 4 and event.type == "button_hold" then --update files and restart WristOS]
		dynawa.debug.update_files()
		dynawa.debug.send_raw("RESTARTING")
		boot_init()
		return
	end
	
	local protected=function()
		if not dynawa.version then
			dofile(dynawa.dir.sys.."wristos.lua")
		end
		--dynawa.debug.send{event_received=event}
		return _G.private_main_handler(event)
	end

	local status,result=xpcall(protected,errfunc,event)
	if not status then --runtime error caught
		dynawa.debug.send{runtime_error=result}
	end
end

_G.log = function(stuff)
	dynawa.debug.send_raw("LOG: "..tostring(stuff))
end

