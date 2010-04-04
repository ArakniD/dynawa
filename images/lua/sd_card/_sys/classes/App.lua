local class = Class("App")

function class:_init(id)
	self.id = assert(id)
	self.is_app = true
end

function class:start(id)
	log("Start method not defined for "..self)
end

function class:_del()
	error("Attempt to delete an App: "..self)
end

return class

