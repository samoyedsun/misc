local skynet = require "skynet"
local game_rooms_db = require "server.common.game_rooms_db"
local common_conf = require "server.config.common_conf"
local common_util = require "server.common.common_util"
local http_util = require "server.common.http_util"
local logger = log4.get_logger("server_lualib_block_helper")

local prev_block_data = ""
local prev_time = 0
local recv_block_data = false
local timer = nil

local old_block_number = "0"
local old_channel = ""

local CMD = {}

function CMD.broadcast(block_data, channel)
    local current_time = skynet_time()
    local current_date = os.date("%Y-%m-%d %H:%M:%S", current_time)

    local pos_begin, pos_end = string.find(block_data, " ")
    local block_number = string.sub(block_data, 1, pos_begin)
    if tonumber(block_number) <= tonumber(old_block_number) then
        return {
            channel = channel,
            block_number = block_number,
            current_date = current_date,
            result = "==not-use=="
        }
    end
    old_block_number = block_number

    if old_channel ~= "" and old_channel ~= channel then
        local title = "区块链数据接收渠道切换通知!"
        local reason = "该渠道数据为最新!"
        -- local ok, text, title = common_util:alarm_format_block_data_recv_channel_switch(title, block_number, channel, reason)
        -- if ok then http_util.notify_dingtalk(title, text) end
    end
    old_channel = channel

    local skynet_service_id_list = game_rooms_db:fetch_skynet_service_id_list()
    for k, skynet_service_id in ipairs(skynet_service_id_list) do
        skynet.send(skynet_service_id, "lua", "push_block_data", block_data)
    end
    if not recv_block_data then
        local title = "接收到了区块数据通知!"
        local first_block_data = block_data
        local offset_time = current_time - prev_time
        local block_time = ((offset_time == current_time) and {prev_time} or {offset_time})[1]
        if block_time > 0 then
            local ok, text, title = common_util:alarm_format_recv_block_data(title, first_block_data, block_time)
            if ok then http_util.notify_dingtalk(title, text) end
        end
    end
    prev_time = current_time
    recv_block_data = true

    prev_block_data = block_data
	if timer and (not timer.is_timeout()) then
		timer.delete()
	end
	timer = create_timeout(common_conf.TIME_LIMIT_WAIT_BLOCK_DATA * 100, function(bd)
        if prev_block_data == bd then
            recv_block_data = false
            local title = "等待区块数据超时报警!"
            local ok, text, title = common_util:alarm_format_wait_block_data(title, bd, common_conf.TIME_LIMIT_WAIT_BLOCK_DATA)
            if ok then http_util.notify_dingtalk(title, text) end
		end
    end, block_data)
    
    local res = {
        channel = channel,
        block_number = block_number,
        current_date = current_date,
        result = "==is-use=="
    }
    return res
end

function CMD.fetch_module_info()
	if timer and (not timer.is_timeout()) then
		timer.delete()
	end
    local self_info = {
        prev_block_data = prev_block_data,
        prev_time = prev_time,
        recv_block_data = recv_block_data,

        old_block_number = old_block_number,
        old_channel = old_channel
    }
    return cjson_encode(self_info)
end

function CMD.update_module_info(tmp_info)
    local self_info = cjson_decode(tmp_info)
    prev_block_data = self_info.prev_block_data
    prev_time = self_info.prev_time
    recv_block_data = self_info.recv_block_data

    old_block_number = self_info.old_block_number
    old_channel = self_info.old_channel
end

return CMD
