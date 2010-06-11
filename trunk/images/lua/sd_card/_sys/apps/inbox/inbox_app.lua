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
		local newstr, is_new = self:count_str(id)
		local item = {text = inbox_names[id].." "..newstr, value = {inbox = id}}
		if is_new then
			item.textcolor = highlight_color
		end
		table.insert (menu.items, item)
	end
	table.insert(menu.items, {text = "Mark all as read", value = {action = "mark_all_read"}})
	table.insert(menu.items, {text = "Delete all", value = {action = "delete_all"}})
	local menuwin = self:new_menuwindow(menu)
	menuwin.menu:render()
	menuwin:push()
end

function app:menu_cancelled(menu)
	if menu.flags.inbox then
		menu.window:pop()
		menu:_delete()
		self:display_root_menu()
	else
		assert(menu.flags.root)
	end
end

function app:menu_item_selected(args)
	local value = assert(args.item.value)
	--log(dynawa.file.serialize(value))
	local menu = args.menu
	if menu.flags.root then --Clicking anything in root menu usually results in change of its contents.
							--So we simply destroy it right now and it gets redrawn later.
		local win = menu.window:pop()
		win:_delete()
		if value.action then
			if value.action == "mark_all_read" then
				for i,id in ipairs(inbox_ids) do
					self:mark_all_read(id)
				end
			else
				assert(value.action == "delete_all")
				for i,id in ipairs(inbox_ids) do
					self.prefs.storage[id] = {}
				end
			end
			self:display_root_menu()
			dynawa.popup:info("Done!")
		else
			assert(value.inbox)
			self:display_inbox(value.inbox)
		end
	elseif menu.flags.inbox then --We clicked something in one of the inboxes
		local win = menu.window:pop()
		win:_delete()
	end
	--self["menu_action_"..value.jump](self,value) #todo
end

function app:display_inbox(box_id)
	local menu = {
		banner = "Inbox: "..inbox_names[box_id],
		flags = {inbox = box_id},
		items = {}
	}
	for i, item in ipairs(self.prefs.storage[box_id]) do
		local item = {text = item.header}
		if not item.read then
			item.textcolor = highlight_color
		end
		table.insert (menu.items, item)
	end
	if not next(menu.items) then --No items in menu
		table.insert (menu.items,{text="[No items in this inbox]", value = {action = "show_item", item = i}})
	else
		table.insert(menu.items, {text = "Mark all as read", value = {action = "mark_all_read", inbox = box_id}})
		table.insert(menu.items, {text = "Delete all", value = {action = "delete_all", box_id}})
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

