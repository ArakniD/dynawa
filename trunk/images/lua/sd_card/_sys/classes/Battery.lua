local class = Class("Battery", Class.EventSource)

local function log_file(txt)
	local time = os.date("*t")
	local timetxt = string.format("%02d:%02d:%02d", time.hour, time.min, time.sec)
	local fd = assert(io.open("/battery_log.txt","a"))
	assert(fd:write(timetxt.." "..txt.."\n"))
	fd:close()
end

function class:_init()
	Class.EventSource._init(self,"battery")
	self.last_status = false
	self.pct0 = 3400
	self.pct100 = 4150
	self.critical_voltage = 3500
	dynawa.devices.timers:timed_event{delay = 10000, receiver = self}
	log_file("REBOOT")
end

function class:voltage_to_percent(v)
	-- 3000 - 4150
	local pct = (v - self.pct0) / (self.pct100 - self.pct0) * 100
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
	status.percentage = self:voltage_to_percent(status.voltage)
	if false then
		status.charging = true --#todo
	end
	if status.voltage <= self.critical_voltage and not status.charging then
		status.critical = true
	end
	self.last_status = {timestamp = status.timestamp, voltage = status.voltage, percentage = status.percentage}
	local logtxt = "Voltage = "..status.voltage .. " ("..status.percentage.."%)"
	log(logtxt)
	log_file(logtxt)
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
	local delay = 60000
	dynawa.devices.timers:timed_event{delay = delay, receiver = self}
end

return class
