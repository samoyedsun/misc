local skynet = require "skynet"
require "luaext"
require "print_r"
require "utils.utils"

log4 = require "log4"
log4.configure(require('etc.' .. skynet.getenv("env") .. ".log4"))

local logmode = skynet.getenv("logmode")
IS_DEBUG = logmode == "DEBUG"