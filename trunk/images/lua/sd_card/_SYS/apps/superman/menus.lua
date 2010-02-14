--menus for SuperMan
my.globals.menus = {}
my.globals.menus.file_browser = function(dir)
	assert(type(dir)=="string")
	assert(#dir >= 1)
	log("opening dir "..dir)
	local dirstat = dynawa.file.dir_stat(dir)
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
