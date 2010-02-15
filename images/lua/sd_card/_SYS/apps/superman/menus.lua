--menus for SuperMan
my.globals.menus = {}
my.globals.menus.file_browser = function(dir)
	assert(type(dir)=="string")
	assert(#dir >= 1)
	log("opening dir "..dir)
	local dir2 = assert(dir:match("(.*)/"))
	if dir2 == "" then
		dir2 = "/"
	end
	local dirstat = dynawa.file.dir_stat(dir2)
	local menu = {banner = "Directory: "..dir, items={}}
	if not dirstat then
		table.insert(menu.items,{text="(Invalid directory)"})
	else
		for k,v in pairs(dirstat) do
			local txt = k.." ("..v..")"
			log("Adding dirstat item: "..txt)
			local location
			if v == "dir" then
				location = "file_browser:"..dir..k.."/"
			end
			table.insert(menu.items,{text=txt,location=location})
		end
	end
	return menu
end

my.globals.menus.bluetooth = function(item)
	local item = tonumber(item)
	local btapp = assert(dynawa.apps["/_sys/apps/bluetooth/"])
	local btitems = assert(btapp.globals.superman_menu)
	if item then
		btitems[item].callback()
	end
	local menu = {banner="Bluetooth", items={}}
	for i, item in ipairs(btitems) do
		table.insert(menu.items,{text=item.text,location="bluetooth:"..i,active_item = i})
	end
	return menu
end

