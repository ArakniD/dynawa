local Object = Class:get_by_name("Object")
local class = Class("MenuItem",nil,Object)

function class:_init(desc)
	Object._init(self)
	--#todo text-only so far
	self.text = desc.text
	self.id = desc.id
	if not self.id then
		self.id = dynawa.unique_id()
	end
end

function class:render(args)
	--#todo
	--return bitmap
end

function class:selected()
	return
end

Class:add_public(class)

return class

