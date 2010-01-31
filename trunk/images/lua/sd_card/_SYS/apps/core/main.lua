require("dynawa")

my.app.name="System core"
dynawa.task.start(my.dir.."buttons.lua")

dynawa.app.start(dynawa.dir.sys.."apps/clock/")
