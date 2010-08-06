local class = Class("Battery", Class.EventSource)


function class:_init()
	Class.EventSource._init(self,"battery")
	self.last_status = false
	self.critical_percentage = self:voltage_to_percent(3500)
	dynawa.devices.timers:timed_event{delay = 10000, receiver = self}
end

function class:voltage_to_percent(v)
	--Linear, for now...
	local pct = (v - 3400) / 8
	pct = math.floor(pct + 0.5)
	if pct < 0 then
		return 0
	end
	if pct > 100 then
		return 100
	end
	return pct
end

function class:status()
	local status = {timestamp = os.time()}
	status.voltage = dynawa.x.battery_voltage()
	--status.voltage = 4000
	status.percentage = self:voltage_to_percent(status.voltage)
	if false then
		status.charging = true --#todo
	end
	if status.percentage <= self.critical_percentage and not status.charging then
		status.critical = true
	end
	self.last_status = {timestamp = status.timestamp, voltage = status.voltage, percentage = status.percentage}
	log("Voltage = "..status.voltage .. " ("..status.percentage.."%)")
	return status
end

function class:broadcast_update(event) --Broadcast the change
	event.type = "battery_status"
	self:generate_event(event)
end

function class:handle_event_timed_event(event)
	local status = self:status()
	if self.last_status and self.last_status.voltage ~= status.voltage then
		self:broadcast_update(status)
	end
	--#todo Dynamic delay?
	local delay = 10000
	dynawa.devices.timers:timed_event{delay = delay, receiver = self}
end

return class
