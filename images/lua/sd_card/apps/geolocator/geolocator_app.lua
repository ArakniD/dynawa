app.name = "Geolocator"
app.id = "dynawa.geolocator"


function app:switching_to_front()
	local menu = {
		banner = "Geolocator",
		items = {
			{
				text = "Geo request [debug]", value = {jump = "request"},
			},
		},
	}
	local menuwin = self:new_menuwindow(menu)
	menuwin:push()
end

function app:menu_action_request()
	local georeq = dynawa.app_manager:app_by_id("dynawa.geo_request")
	if not georeq then
		dynawa.popup:error("Geo Request app is not running")
		return nil, "No Geo Request App"
	end
	local request = {command = "geo_request", method = "cached", callback = function(reply,request)
		self:response(reply,request)
	end}
	local stat,err = georeq:make_request(request)
end

function app:menu_item_selected(args)
	local value = args.item.value
	if not value then
		return
	end
	self["menu_action_"..value.jump](self,value)
end

function app:response(response,request)
	log("Geo response: "..dynawa.file.serialize(response))
	if response.network then
		self:reverse_geoloc_request(response.network)
	end
	if response.gps then
		self:reverse_geoloc_request(response.gps)
	end
end

function app:reverse_geoloc_request(data)
	local params = "latlng="..data.location.latitude..","..data.location.longitude.."&sensor=true"
	local request = {timeout = 10000, sanitize_text = true, address = "maps.googleapis.com", path = "/maps/api/geocode/json?"..params}
	request.callback = function(response, request)
		self:reverse_geoloc_response(response,request)
	end
	local http_app = dynawa.app_manager:app_by_id("dynawa.http_request")
	if not http_app then
		log("HTTP Request app not available!")
		return
	end
	log("Asking for reverse geoloc (accuracy="..data.accuracy..")")
	local status,err = http_app:make_request(request)
	if not status then
		dynawa.popup:error("Cannot do reverse geolocation: "..err)
	end
end

function app:reverse_geoloc_response(response)
	log("Got reverse geoloc: Status = "..tostring(response.status).." ("..tostring(response.error)..")")
	log(tostring(response.body))
end

--[[function app:going_to_sleep()
	return "remember"
end]]

function app:start()
end


