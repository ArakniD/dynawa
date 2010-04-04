local class = Class("MenuItem")

function class:_init(desc)
	--#todo text-only so far
	self.text = desc.text
	self.id = dynawa.unique_id()
	if desc.on_select then
		self.on_select = desc.on_select
	end
end

function class:render(args)
	local bitmap = dynawa.bitmap.text_lines{text=self.text, font = nil, width = assert(args.max_size.w)}
	return bitmap
end

function class:selected(args)
	dynawa.superman:menu_item_selected(args)
end

return class

