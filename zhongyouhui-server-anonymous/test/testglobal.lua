local skynet = require "skynet"
local md5 = require "md5"
local http_util = require "server.common.http_util"
local common_util = require "server.common.common_util"

skynet.start(function()
	local ok, data = pcall(http_util.fetch_dfuse_block_data, "2019-10-18T13:38:23.500Z")
	print(ok, data)
	local ok, data = pcall(http_util.fetch_eosflare_block_data, 85199582)
	print(ok, data)
    skynet.sleep(100 * 10)
    skynet.exit()
end)
