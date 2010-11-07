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
	data.server = "www.google.com"
	data.port = 80
	data.id = dynawa.unique_id()
	local id,act = next(dyno.activities)
	if not act then
		return nil,"No Dyno activities" --#todo
	end
	log("**** Sending http request")
	local stat,err = dyno:bdaddr_send_data(act.bdaddr,data)
	if not stat then
		log("Cannot send http request: "..err)
	end
end

function app:handle_event_dyno_data_from_phone(ev)
	self:handle_response(assert(ev.data))
end

function app:handle_event_timed_event(ev)
	self:send_request()
	dynawa.devices.timers:timed_event{delay = 30000, receiver = self}
end

function app:handle_response(response)
	log("HTTP response: "..dynawa.file.serialize(response))
end
