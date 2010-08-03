app.name = "Sandman"
app.id = "dynawa.sandman"

--Handles sleep mode after period of button inactivity

function app:start()
	dynawa.devices.buttons:register_for_events(self, function(event)
		return (event.action == "button_down")
	end)
	self.sleeping = false
	self.last_timestamp = -1
	self.last_handle = false
	self:activity()
end

function app:activity(force)
	if self.sleeping then
		log("Waking up!")
		dynawa.window_manager:stack_cleanup()
		dynawa.devices.display.power(1)
		self.sleeping = false
		dynawa.busy()
		dynawa.window_manager:show_default()
	else
		local tstamp = dynawa.ticks()
		if not force and (tstamp - self.last_timestamp < 500) then
			--Ignore activity if not sleeping and received it less then 500 ms after previous activity and not "forced".
			return
		end
		if self.last_handle then
			dynawa.devices.timers:cancel(self.last_handle)
		end
		self.last_timestamp = tstamp
		self.last_handle = dynawa.devices.timers:timed_event{delay = 9999999999, timestamp = tstamp, receiver = self}
	end
end

function app:handle_event_timed_event(event)
	if event.timestamp ~= self.last_timestamp then
		--New timed event was triggered by Sandman AFTER his previous event fired! Ignore previous event.
		return
	end
	log("Going to sleep")
	dynawa.window_manager:stack_cleanup()
	self.sleeping = true
	self.last_timestamp, self.last_handle = -1, false
	dynawa.devices.display.power(0)
end

function app:handle_event_button(event)
	local t = dynawa.ticks()
	--log("Button down at "..t)
	self:activity()
end

