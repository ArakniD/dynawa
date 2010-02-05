require("dynawa")

my.app.name="System core"

local function start_sys_apps()
	local dir = "_SYS"
	local stat = dynawa.file.dir_stat(dir)
	for k,v in pairs(stat) do
		log("DIRSTAT "..k..":"..v)
	end
end

--start_sys_apps()

dynawa.task.start(my.dir.."display.lua")
dynawa.task.start(my.dir.."task_manager.lua")
dynawa.task.start(my.dir.."buttons.lua")

