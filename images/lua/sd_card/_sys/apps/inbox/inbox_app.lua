app.name = "Inbox"
app.id = "dynawa.inbox"

function app:start()
	dynawa.bluetooth_manager = self
	self.prefs = self:load_data() or {storage = {email={},sms={},calendar={},call={}}}
	dynawa.devices.bluetooth.high_level:register_for_events(self) --#todo specify function for just "inbox" commands
end

function app:count(typ)
	local unread = 0
	for item in ipairs(self.prefs.storage[typ]) do
		if not item.read then
			unread = unread + 1
		end
	end
	return unread, #self.prefs.storage[typ]
end

function app:count_str(typ)
	local unread, all = self:count(typ)
	return ("("..unread.."/"..all..")")
end

function app:switching_to_front()
	local menu = {
		banner = "Inbox",
		items = {
			{
				text = "SMS Messages "..self:count_str("sms"), value = {inbox = "sms"},
			},
			{
				text = "E-mails "..self:count_str("email"), value = {inbox = "email"},
			},
			{
				text = "Calendar events "..self:count_str("calendar"), value = {inbox = "calendar"},
			},
			{
				text = "Voice calls "..self:count_str("call"), value = {jump = "call"},
			},
			{
				text = "Mark all as read", value = {inbox = "mark_all_read"},
			},
			{
				text = "Delete all", value = {jump = "delete_all"},
			},
		},
	}
	local menuwin = self:new_menuwindow(menu)
	menuwin.menu:render()
	menuwin:push()
end

--[[
function app:menu_cancelled(menu)
	menu.window:pop()
end
]]

function app:menu_item_selected(args)
	local value = assert(args.item.value)
	log(dynawa.file.serialize(value))
	--self["menu_action_"..value.jump](self,value) #todo
end


