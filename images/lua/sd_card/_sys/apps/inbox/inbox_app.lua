app.name = "Default Inbox"
app.id = "dynawa.inbox"

local inbox_names = {
	sms = "SMS messages",
	email = "E-mails",
	calendar = "Calendar",
	call = "Voice calls",
}

local inbox_ids = {"sms","email","calendar","call"}

local highlight_color = {0,226,240}

function app:start()
	local bmap = assert(dynawa.bitmap.from_png_file(self.dir.."gfx.png"))
	self.gfx = {}
	for i,id in ipairs {"email","sms","call","calendar"} do
		self.gfx[id] = dynawa.bitmap.copy(bmap, i*25 - 25, 0, 25, 25)
	end
	self.events = Class.EventSource("inbox")
	self.prefs = self:load_data() or {storage = {email={},sms={},calendar={},call={}}}
	table.insert(self.prefs.storage.email,{header = "We should meet (obama@whitehouse.gov)",
			body={"From: Barack Obama <obama@whitehouse.gov>",{"(Received %s)",os.time() - 300},"Dear Sir,","Please contact me, because we have to meet soon. The future","of the free world is currently at stake","Your truly, Barack"}})

	table.insert(self.prefs.storage.email,{header = "You inherited $80,000,000 congratulations!! (ahmed@niger.net)",
			body={"From: Ahmed Ahmed <ahmed@niger.net>",{"(Received %s)",os.time() - 60 * 60 * 12},"Dear Sir,","Please contact me, because we have to meet soon. You are the sole heir of","the great rich maharaja.","Your truly, Ahmed"}})	

	table.insert(self.prefs.storage.calendar,{header = {"Meet Vaclav Klaus (%s)",os.time() + 60*60*24*7 + 1000},
			body={"At Prague Castle"}})
	local my_events
	dynawa.app_manager:after_app_start("dynawa.bt.openwatch",function (openwatch)
		openwatch.events:register_for_events(self, function(ev)
			if not ev.type == "from_watch" then
				return false
			end
			local com = ev.data.command
			return (com == "incoming_sms" or com == "incoming_email" or com == "incoming_call" or com == "calendar_event")
		end)
	end)
end

function app:handle_event_from_watch(ev)
	local data = assert(ev.data)
	dynawa.popup:open{text = "from_watch: "..ev.data.command, autoclose=true, bgcolor = {0,0,200}}
end

function app:text_or_time(arg)
	if type(arg)=="string" then
		return arg
	end
	local t_mins = math.floor((arg[2] - os.time() + 30) / 60)
	local result = "right now"
	if t_mins ~= 0 then
		result = {}
		local future = t_mins > 0
		t_mins = math.abs(t_mins)
		local t_weeks = math.floor(t_mins / 60 / 24 / 7)
		local t_days = math.floor(t_mins / 60 / 24) % 7
		local t_hours = math.floor(t_mins / 60) % 24
		t_mins = t_mins % 60
		if t_weeks == 1 then
			table.insert(result, "1 week")
		elseif t_weeks > 1 then
			table.insert(result, t_weeks.." weeks")
		end
		if t_days == 1 then
			table.insert(result, "1 day")
		elseif t_days > 1 then
			table.insert(result, t_days.." days")
		end
		if t_hours == 1 then
			table.insert(result, "1 hour")
		elseif t_hours > 1 then
			table.insert(result, t_hours.." hours")
		end
		if t_mins == 1 then
			table.insert(result, "1 minute")
		elseif t_mins > 1 then
			table.insert(result, t_mins.." minutes")
		end
		result = table.concat(result, ", ")
		if future then
			result = "in " .. result
		else
			result = result .. " ago"
		end
		result = string.format(arg[1], result)
	end
	return result
end

function app:count(typ)
	local unread = 0
	for i,item in ipairs(self.prefs.storage[typ]) do
		if not item.read then
			unread = unread + 1
		end
	end
	return unread, #self.prefs.storage[typ]
end

function app:count_str(typ)
	local unread, all = self:count(typ)
	return unread.."/"..all, (unread > 0)
end

function app:switching_to_front()
	self:display_root_menu()
end

function app:display_root_menu()
	local menu = {
		banner = "Inbox",
		flags = {root = true},
		items = {}
	}
	for i, id in ipairs(inbox_ids) do
		local item = {render = function(_self, args)
			local newstr, is_new = self:count_str(id)
			local color
			if is_new then
				color = highlight_color
			end
			local width = args.max_size.w
			local bitmap = dynawa.bitmap.new(width, 25,0,0,0,0)
			dynawa.bitmap.combine(bitmap, self.gfx[id],width - 25, 0)
			dynawa.bitmap.combine(bitmap, dynawa.bitmap.text_line(inbox_names[id]..":","/_sys/fonts/default10.png"), 0, 10)
			dynawa.bitmap.combine(bitmap, dynawa.bitmap.text_line(newstr, "/_sys/fonts/default15.png", color),87,6)
			
			--dynawa.bitmap.combine(bitmap, dynawa.bitmap.text_lines{text=inbox_names[id].." "..newstr, color = color, width = assert(width - 25)}, 0, 0)
			return bitmap
		end}
		item.value = {open_folder = id}
		table.insert (menu.items, item)
	end
	table.insert(menu.items, {text = "Mark all as read", selected = function(_self,args)
		for i,id in ipairs(inbox_ids) do
			self:mark_all_read(id)
		end
		dynawa.popup:info("Contents of all folders marked as read.")
		args.menu:invalidate()
		self:save_data(self.prefs)
		self:broadcast_update()
	end})
	table.insert(menu.items, {text = "Delete all", selected = function(_self,args)
		for i,id in ipairs(inbox_ids) do
			self.prefs.storage[id] = {}
		end
		dynawa.popup:info("Contents of all folders deleted.")
		args.menu:invalidate()
		self:save_data(self.prefs)
		self:broadcast_update()
	end})
	local menuwin = self:new_menuwindow(menu)
	menuwin:push()
end

function app:menu_item_selected(args)
	local value = args.item.value
	if not value then
		return
	end
	if value.open_folder then
		self:display_folder(value.open_folder)
	elseif value.message then
		local message = value.message
		local menu = {flags = {parent = assert(args.menu)}, items = {}}
		menu.banner = self:text_or_time(message.header)
		for i, line in ipairs(message.body) do
			table.insert(menu.items, {text = self:text_or_time(line), textcolor = {255,255,0}})
		end
		if not message.read then
			message.read = true
			args.menu:invalidate()
			args.menu.flags.parent:invalidate()
			self:save_data(self.prefs)
			self:broadcast_update()
		end
		table.insert(menu.items, {text = "Delete this message", selected = function(_self,args)
			local folder_id = assert(args.menu.flags.parent.flags.folder_id)
			for i, msg_iter in ipairs(self.prefs.storage[folder_id]) do
				if msg_iter == message then
					table.remove(self.prefs.storage[folder_id],i)
					break
				end
			end
			dynawa.window_manager:pop():_delete() --Pop the message menu
			dynawa.window_manager:pop():_delete() --And the original folder menu
			self:display_folder(folder_id)
			dynawa.popup:info("Message deleted.")
			self:save_data(self.prefs)
			self:broadcast_update()
		end})
		local menuwin = self:new_menuwindow(menu)
		menuwin:push()
	end
end

function app:display_folder(folder_id)
	local folder = self.prefs.storage[folder_id]
	local menu = {
		banner = "Inbox: "..assert(inbox_names[folder_id]),
		flags = {parent = assert(dynawa.window_manager:peek().menu), folder_id = folder_id},
		items = {},
	}

	for i, item in ipairs(folder) do
		local item = {value = {message = item}}
		item.render = function(_self,args)
			local color
			if not _self.value.message.read then
				color = highlight_color
			end
			local bitmap = dynawa.bitmap.text_lines{text="> "..self:text_or_time(_self.value.message.header), color = color, width = assert(args.max_size.w)}
			return bitmap
		end
		table.insert (menu.items, item)
	end
	if not next(menu.items) then --No items in menu
		table.insert (menu.items,{text="[No messages in this folder]", textcolor = {255,255,0}})
	else

		table.insert(menu.items, {text = "Mark all as read", selected = function(_self,args)
			self:mark_all_read(folder_id)
			dynawa.popup:info("Contents of this folder marked as read.")
			args.menu:invalidate()
			args.menu.flags.parent:invalidate()
			self:save_data(self.prefs)
			self:broadcast_update()
		end})
		
		table.insert(menu.items, {text = "Delete all", selected = function(_self,args)
			self.prefs.storage[folder_id] = {}
			args.menu.flags.parent:invalidate()
			args.menu.window:pop()
			args.menu:_delete()
			dynawa.popup:info("Contents of this folder deleted.")
			self:save_data(self.prefs)
			self:broadcast_update()
		end})
	end

	local menuwin = self:new_menuwindow(menu)
	menuwin:push()
end

function app:broadcast_update() --Broadcast the change
	self.events:generate_event{type = "inbox_updated", folders = self.prefs.storage}
end

function app:mark_all_read(box_id)
	for i,item in ipairs(assert(self.prefs.storage[box_id])) do
		item.read = true
	end
end

