app.name = "HTTP Request Service"
app.id = "dynawa.http_request"

function app:start()
	dynawa.app_manager:after_app_start("dynawa.dyno", function(dyno)
		dyno.events:register_for_events(self, function(ev)
			return (ev.data and ev.data.command == "HTTP_response")
		end)
	end)
	self:handle_event_timed_event()
end

function app:send_request(request)
	local dyno = dynawa.app_manager:app_by_id("dynawa.dyno")
	if not dyno then
		dynawa.popup:error("Dyno is not running, HTTP Request Service cannot control the phone")
		return false,"No Dyno"
	end
	local data = {command = "HTTP_request"}
	data.message = "GET / HTTP/1.0\r\n\r\n"
	data.address = "www.kompost.cz"
	data.port = 80
	data.id = dynawa.unique_id()
	local id,act
	for i,a in pairs(dyno.activities) do
		if a.status == "connected" then
			act = a
			break
		end
	end
	if not act then
		log("HTTP Requester: Dyno doesn't have any activity whose status is 'connected'. Trying again in a while.")
		return
	end 
	log("**** Sending http request")
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
		parsed.body = "<BODY OK! (omitted for testing)>"
	end
	return parsed
end

function app:handle_event_dyno_data_from_phone(ev)
	self:handle_response(assert(ev.data))
end

function app:handle_event_timed_event(ev)
	self:send_request()
	dynawa.devices.timers:timed_event{delay = 30000, receiver = self}
end

function app:handle_response(response)
	--log("HTTP response: "..dynawa.file.serialize(response))
	log("HTTP response parsed: "..dynawa.file.serialize(self:parse_response(response)))
end
