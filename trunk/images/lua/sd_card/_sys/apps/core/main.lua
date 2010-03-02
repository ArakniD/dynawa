require("dynawa")

my.app.name="System Core"

dynawa.task.start(my.dir.."display.lua")
dynawa.task.start(my.dir.."task_manager.lua")
dynawa.task.start(my.dir.."buttons.lua")

