app.name = "HTTP Request Service"
app.id = "dynawa.http_request"

function app:start()
	self.requests = {}
	dynawa.app_manager:after_app_start("dynawa.dyno", function(dyno)
		dyno.events:register_for_events(self, function(ev)
			return (ev.data and ev.data.command == "HTTP_response")
		end)
	end)
--	self:handle_event_timed_event()
end

function app:make_request(request)
	assert(request.address, "No server specified in HTTP request")
	request.id = dynawa.unique_id()
	request.port = request.port or 80
	request.path = request.path or "/"
	request.headers = request.headers or {}
	if not request.headers.Host then
		request.headers.Host = request.address
	end
	local dyno = dynawa.app_manager:app_by_id("dynawa.dyno")
	if not dyno then
		dynawa.popup:error("Dyno is not running, HTTP Request Service cannot control the phone")
		return false,"No Dyno"
	end
	local data = {command = "HTTP_request"}
	data.message = "GET "..request.path.." HTTP/1.0\r\n"
	data.address = request.address
	data.port = request.port
	data.id = request.id
	local headers_lines = {}
	for k,v in pairs(request.headers) do
		table.insert(headers_lines, k..": "..v)
	end
	data.message = data.message .. table.concat(headers_lines,"\r\n") .. "\r\n\r\n"
	local id,act
	for i,a in pairs(dyno.activities) do
		if a.status == "connected" then
			act = a
			break
		end
	end
	if not act then
		log("HTTP Requester: Dyno doesn't have any activity whose status is 'connected'.") --#todo
		return
	end 
	log("**** Sending http request "..request.id)
	request.bdaddr = act.bdaddr
	self.requests[request.id] = request
	local stat,err = dyno:bdaddr_send_data(act.bdaddr,data)
	if not stat then
		log("Cannot send http request: "..err)
	end
end

function app:parse_response(response)
	if not response.message then
		return {error = assert(response.error)}
	end
	local parsed = {timestamp = dynawa.ticks(), headers = {}}
	parsed.id = assert(response.id, "Missing id in response")
	local headers,body = response.message:match("(.-)\r\n\r\n(.*)")
	if not body then
		headers = response.message
	end
	local status_line,headers = headers:match("(.-)\r\n(.*)")
	assert(headers,"Cannot parse responses headers")
	parsed.protocol, parsed.status = status_line:match("(.-) (.*)")
	assert(#parsed.status >= 3, "No response status")
	headers = headers .. "\r\n"
	headers:gsub("(.-)\r\n", function(line)
		local key, val = line:match("(.-): (.*)")
		assert(val, "Cannot match value in "..line)
		parsed.headers[key] = val
	end)
	if body then
		parsed.body = body
	end
	local request = assert(self.requests[parsed.id],"HTTP response with uknown id.")
	self.requests[parsed.id] = nil
	return parsed, request
end

function app:handle_event_dyno_data_from_phone(ev)
	self:handle_response(assert(ev.data))
end

--[[function app:handle_event_timed_event(ev)
	self:send_request()
	dynawa.devices.timers:timed_event{delay = 30000, receiver = self}
end]]

function app:handle_response(response)
	--log("HTTP response: "..dynawa.file.serialize(response))
	local parsed, request = self:parse_response(response)
	request.callback(parsed,request)
end
