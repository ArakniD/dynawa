local class = Class("MenuItem")

function class:_init(desc)
	--#todo text-only so far
	self.text = desc.text
	self.textcolor = desc.textcolor
	self.id = dynawa.unique_id()
	if desc.on_select then
		self.on_select = desc.on_select
	end
	if desc.value then
		self.value = desc.value
	end
end

function class:render(args)
	local bitmap = dynawa.bitmap.text_lines{text=self.text, font = nil, width = assert(args.max_size.w), color = self.textcolor}
	return bitmap
end

function class:selected(args)
	local menu = assert(args.menu)
	return menu:item_selected(args)
end

return class

