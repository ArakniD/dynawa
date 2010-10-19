--This app monitors the duration of voice calls made to the phone which is connected to TCH1 through Dyno

app.name = "Call Manager"
app.id = "dynawa.call_manager"

function app:start()
	self.phones = {} --indexed by bdaddr
	self.events = Class.EventSource("call_manager")
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
		self.phones[data.bdaddr] = {status = "ringing", since = dynawa.ticks(), data = data}
		log("--INCOMING CALL")
		self:incoming_call_popup(data)
		return
	elseif data.command == "call_start" then
		log("--CALL START")
		local phone = self.phones[data.bdaddr]
		if not phone then
			--This must be an outgoing call because we have no record of this phone ringing. Ignore it.
			return
		end
		if phone.status ~= "ringing" then
			--Phone has a record but indicates other status than "ringing". Weird. Ignore & clear it.
			self.phones[data.bdaddr] = nil
			return
		end
		--Phone is ringing.
		if dynawa.ticks() - phone.since > 300000 then
			--Phone was ringing for more than 5 minutes before being picked up. This cannot be right.
			self.phones[data.bdaddr] = nil
			return
		end
		phone.status = "incoming_call"
		phone.since = dynawa.ticks()
		return
	else
		assert(data.command == "call_end")
		log("--CALL END")
		local phone = self.phones[data.bdaddr]
		if not phone then
			return
		end
		if phone.status ~= "incoming_call" then
			self.phones[data.bdaddr] = nil
			if phone.status == "ringing" and (dynawa.ticks() - phone.since < 300000) then
				--Generate voicecall event. It's MISSED CALL because duration == nil
				self.events:generate_event{type="incoming_call", data = assert(phone.data)}
			end
			return
		end
		local duration = math.floor((dynawa.ticks()-phone.since)/1000)
		if duration < 1 then
			duration = 1
		end
		self.phones[data.bdaddr] = nil
		local call_data = assert(phone.data)
		call_data.duration = string.format("%d:%02d",math.floor(duration / 60), duration % 60)
		--log("Call duration: "..duration)
		--generate voicecall event. It's ACCEPTED CALL because duration ~= nil
		self.events:generate_event{type="incoming_call", data = call_data}
		return
	end
	error("WTF")
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
	dynawa.busy()
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
			data.possible_actions.silence = nil
			self:incoming_call_popup(data)
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
