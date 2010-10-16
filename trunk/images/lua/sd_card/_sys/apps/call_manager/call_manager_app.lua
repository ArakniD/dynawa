--This app monitors the duration of voice calls made to the phone which is connected to TCH1 through Dyno

app.name = "Call Manager"
app.id = "dynawa.call_manager"

function app:start()
	self.phones = {} --indexed by bdaddr
	dynawa.app_manager:after_app_start("dynawa.dyno",function (dyno)
		dyno.events:register_for_events(self, function(ev)
			if ev.type ~= "dyno_data_from_phone" then
				return false
			end
			local comm = ev.data.command
			return (comm == "incoming_call" or comm == "call_start" or comm == "call_end")
		end)
	end)
end

function app:handle_event_dyno_data_from_phone(event)
	local data = assert(event.data)
	if data.command == "incoming_call" then
		self.phones[data.bdaddr] = {status = "ringing"}
		log("--INCOMING CALL")
		self:incoming_call_popup(data)
		--show window
	elseif data.command == "call_start" then
		log("--CALL START")
		self.phones[data.bdaddr] = {status = "in_progress", since = dynawa.ticks()}
	else
		assert(data.command == "call_end")
		log("--CALL END")
	end
end

function app:phone_action(action,bdaddr)
	local dyno = dynawa.app_manager:app_by_id("dynawa.dyno")
	if not dyno then
		dynawa.popup:error("Dyno is not running, cannot control the phone")
		return false,"No Dyno"
	end
	local stat,err = dyno:bdaddr_send_data(bdaddr,{command="call_resolution",resolution=assert(action)})
	if not stat then
		dynawa.popup:error(err)
	end
end

function app:incoming_call_popup(data)
	local rows = {"Call: "..(data.contact_name or data.contact_phone)}
	for i, row in ipairs(rows) do
		if type(row) == "string" then
			rows[i] = dynawa.bitmap.text_lines{text = row, width = 140, autoshrink = true, center = true}
		end
	end
	local bdaddr = assert(data.bdaddr)
	local actions = {}
	
	local popup_def = {}
	
	if data.possible_actions.pick_up then
		table.insert(actions,"CONFIRM = Pick up")
		popup_def.on_confirm = function()
			self:phone_action("pick_up",bdaddr)
		end
	end
	if data.possible_actions.reject then
		table.insert(actions,"CANCEL = Reject")
		popup_def.on_cancel = function()
			self:phone_action("reject",bdaddr)
		end
	end
	if data.possible_actions.voicemail then
		table.insert(actions,"TOP = To voicemail")
		popup_def.on_top = function()
			self:phone_action("voicemail",bdaddr)
		end
	end
	if data.possible_actions.silence then
		table.insert(actions,"BOTTOM = Silence")
		popup_def.on_bottom = function()
			self:phone_action("silence",bdaddr)
		end
	end
	table.insert(rows, table.concat(actions,"; "))
	
	for i, row in ipairs(rows) do
		if type(row) == "string" then
			rows[i] = dynawa.bitmap.text_lines{text = row, width = 140, autoshrink = true, center = true}
		end
	end
	
	if data.contact_icon then
		table.insert(rows,2,assert(dynawa.bitmap.from_png(data.contact_icon["45"])))
		--item.icon = assert(data.contact_icon["30"])
	end
	dynawa.busy()
	popup_def.bitmap = dynawa.bitmap.layout_vertical(rows, {align = "center", border = 5, spacing = 2, bgcolor={80,0,80}})
	dynawa.bitmap.border(popup_def.bitmap,1,{255,255,255})
	local popup_id = dynawa.popup:open(popup_def)
	dynawa.devices.vibrator:alert()
end

return app
