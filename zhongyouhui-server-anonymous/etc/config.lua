cloudroot="./cloud/"
skynetroot = cloudroot .. "skynet/"
thread = 8
harbor = 0
start = "server/main"  -- main script
bootstrap = "snlua bootstrap"   -- The service for bootstrap

gameservice = cloudroot .. "service/?.lua;" .. "./test/?.lua;" .. "./?.lua"
luaservice = skynetroot .. "service/?.lua;" .. gameservice

lualoader = skynetroot .. "lualib/loader.lua"
preload = "./etc/preload.lua"   -- run preload.lua before every lua service run
snax = gameservice
cpath = skynetroot .. "cservice/?.so;" .. "" .. cloudroot .. "cservice/?.so" 

lua_path = skynetroot .. "lualib/?.lua;" ..
            cloudroot .. "lualib/?.lua;" ..
            cloudroot .. "lualib/rpc/?.lua;" ..
            "./lualib/?.lua;" ..
            "./test/?.lua;" ..
            "./?.lua"
            
lua_cpath = skynetroot .. "luaclib/?.so;" .. cloudroot .."luaclib/?.so"

logpath = $LOG_PATH
logmode = $DEBUG_MODE
nodename = $NODENAME
etcdhost = $ETCDHOST
env = $ENV or "dev"
api_env = $API_ENV
if $DAEMON then
      daemon = "./run/skynet-gate.pid"
      logger = logpath .. "skynet-error.log"
end
