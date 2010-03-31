local class = Class("MenuItem")

function class:_init(desc)
	--#todo text-only so far
	self.text = desc.text
	self.id = dynawa.unique_id()
end

function class:render(args)
	local bitmap = dynawa.bitmap.text_lines{text=self.text, font = nil, width = assert(args.max_size.w)}
	return bitmap
end

function class:selected()
	log(self.." selected!")
end

return class

