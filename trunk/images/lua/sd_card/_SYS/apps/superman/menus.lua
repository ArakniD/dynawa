--menus for SuperMan
my.globals.menus = {}

my.globals.menus.root = function()
	local menu = {banner = "SuperMan"}
	menu.items = {
		{text = "Bluetooth", after_select = {go_to="app_menu:/_sys/apps/bluetooth/"}},
		{text = "File Browser", after_select = {go_to="file_browser"}},
		{text = "Bynari Clock app menu", after_select = {go_to = "app_menu:/apps/clock_bynari/"}},
		{text = "Core app menu (test)", after_select = {go_to = "app_menu:/_sys/apps/core/"}},
		{text = "Apps (not yet)"},
		{text = "Shortcuts (not yet)"},
	}
	return menu
end

local function app_menu2(event)
	if event.reply then
		local menu = event.reply
		menu.proxy = assert(event.sender.app)
		dynawa.event.send{type = "open_my_menu", menu = menu}
	else
		dynawa.event.send{type="open_popup", text="This app has no menu", style = "error"}
	end
end

my.globals.menus.app_menu = function(app_id)
	local app = assert(dynawa.apps[app_id],"There is no active app with id '"..app_id.."'")
	dynawa.event.send{type = "your_menu", receiver = app, reply_callback = app_menu2}
end

my.globals.menus.file_browser = function(dir)
	if not dir then
		dir = "/"
	end
	log("opening dir "..dir)
	local dirstat = dynawa.file.dir_stat(dir)
	local menu = {banner = "Dir: "..dir, items={}}
	if not dirstat then
		table.insert(menu.items,{text="(Invalid directory)"})
	else
		for k,v in pairs(dirstat) do
			local txt = k.." ("..v..")"
			--log("Adding dirstat item: "..txt)
			local location = nil
			if v == "dir" then
				location = "file_browser:"..dir..k.."/"
			end
			table.insert(menu.items,{text=txt,after_select={go_to = location}})
		end
		table.sort(menu.items,function(it1,it2)
			return it1.text < it2.text
		end)
	end
	return menu
end

