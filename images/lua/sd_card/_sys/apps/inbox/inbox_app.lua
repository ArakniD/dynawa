app.name = "Inbox"
app.id = "dynawa.inbox"

local inbox_names = {
	sms = "SMS messages",
	email = "E-mails",
	calendar = "Calendar events",
	call = "Voice calls",
}

local inbox_ids = {"sms","email","calendar","call"}

local highlight_color = {0,255,0}

function app:start()
	dynawa.bluetooth_manager = self
	self.prefs = self:load_data() or {storage = {email={},sms={},calendar={},call={}}}
	table.insert(self.prefs.storage.email,{header = "We should meet [obama@whitehouse.gov]",
			body={"From: Barack Obama <obama@whitehouse.gov>","Received 3 minutes ago","Dear Sir,","Please contact me, because we have to meet soon. The future","of the free world is currently at stake","Your truly, Barack"}})

	table.insert(self.prefs.storage.email,{header = "You inherited $80,000,000 congratulations!! [ahmed@niger.net]",
			body={"From: Ahmed Ahmed <ahmed@niger.net>","Received 1 hour ago","Dear Sir,","Please contact me, because we have to meet soon. You are the sole heir of","the great rich maharaja.","Your truly, Ahmed"}})	

	table.insert(self.prefs.storage.calendar,{header = "Meet Vaclav Klaus [in 30 minutes]",
			body={"Meet Vaclav Klaus","In 30 minutes","At Prague Castle"}})	

	dynawa.devices.bluetooth.high_level:register_for_events(self) --#todo specify function for just "inbox" commands
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
	return "("..unread.."/"..all..")", (unread > 0)
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
			local bitmap = dynawa.bitmap.text_lines{text=inbox_names[id].." "..newstr, color = color, width = assert(args.max_size.w)}
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
	end})
	table.insert(menu.items, {text = "Delete all", selected = function(_self,args)
		for i,id in ipairs(inbox_ids) do
			self.prefs.storage[id] = {}
		end
		dynawa.popup:info("Contents of all folders deleted.")
		args.menu:invalidate()
	end})
	local menuwin = self:new_menuwindow(menu)
	menuwin.menu:render()
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
		menu.banner = message.header
		for i, line in ipairs(message.body) do
			table.insert(menu.items, {text = line, textcolor = {255,255,0}})
		end
		if not message.read then
			message.read = true
			args.menu:invalidate()
			args.menu.flags.parent:invalidate()
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
		end})
		local menuwin = self:new_menuwindow(menu)
		menuwin.menu:render()
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
			local bitmap = dynawa.bitmap.text_lines{text="> ".._self.value.message.header, color = color, width = assert(args.max_size.w)}
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
		end})
		
		table.insert(menu.items, {text = "Delete all", selected = function(_self,args)
			self.prefs.storage[folder_id] = {}
			args.menu.flags.parent:invalidate()
			args.menu.window:pop()
			args.menu:_delete()
			dynawa.popup:info("Contents of this folder deleted.")
		end})
	end

	local menuwin = self:new_menuwindow(menu)
	menuwin.menu:render()
	menuwin:push()
end

function app:mark_all_read(box_id)
	for i,item in ipairs(assert(self.prefs.storage[box_id])) do
		item.read = true
	end
end

