local skynet = require "skynet"
local rpc_mysql = require "rpc_mysql"
local mysql_obj = rpc_mysql.get_mysql("zhongyouhui")
local common_db = require "server.common.common_db"
local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"
local logger = log4.get_logger("server_common_wechat_tokens_db")

local root = {}

function root:fetch_wechat_token(platform, unionid)
    local command_fetch_wechat_token = [[
        SELECT
            expires_in, refresh_time, openid, access_token, refresh_token
        FROM
            wechat_tokens
        WHERE
            platform='%s' and unionid='%s'
        LIMIT 1;
    ]]
    local command_fetch_wechat_token = string.format(command_fetch_wechat_token, platform, unionid)
    local res = mysql_obj:query(command_fetch_wechat_token)
    local results = {}
    while next(res) do 
        local tmp = table.remove(res)
        results.expires_in = tmp.expires_in
        results.refresh_time = tmp.refresh_time
        results.openid = tmp.openid
        results.access_token = tmp.access_token
        results.refresh_token = tmp.refresh_token
    end
    return results
end

function root:update_wechat_tokens(platform, unionid, param)
    local command_update_wechat_tokens = [[
        UPDATE
            wechat_tokens
        SET
            expires_in=%d, refresh_time=%d, openid='%s', access_token='%s', refresh_token='%s'
        WHERE
            platform='%s' and unionid='%s'
        LIMIT 1;
    ]]
    local command_update_wechat_tokens = string.format(
            command_update_wechat_tokens,
            param.expires_in, param.refresh_time, param.openid, param.access_token, param.refresh_token,
            platform, unionid
        )
    mysql_obj:query(command_update_wechat_tokens)
end

function root:is_exist_wechat_token_by_unionid(platform, unionid)
    local command_is_exist_wechat_token = [[
        SELECT IFNULL( ( SELECT 'Y' FROM `wechat_tokens` WHERE `unionid` = '%s' and `platform` = '%s' LIMIT 1 ), 'N' ) is_exist;
    ]]
    local command_is_exist_wechat_token = string.format(command_is_exist_wechat_token, unionid, platform)
    local res = mysql_obj:query(command_is_exist_wechat_token)
    local is_exist = "N"
    while next(res) do 
        local tmp = table.remove(res)
        is_exist = tmp.is_exist
    end
    return (is_exist == "Y" and {true} or {false})[1]
end

function root:insert_wechat_tokens(param)
    local command_insert_wechat_tokens = [[
        INSERT INTO `wechat_tokens` (
            `expires_in`, `refresh_time`, `platform`, `openid`, `access_token`,
            `refresh_token`, `unionid`
        ) VALUES (
            %d, %d, '%s', '%s', '%s',
            '%s', '%s'
        );
    ]]
    local command_insert_wechat_tokens = string.format(command_insert_wechat_tokens,
        param.expires_in, param.refresh_time, param.platform, param.openid, param.access_token,
        param.refresh_token, param.unionid
    )
    mysql_obj:query(command_insert_wechat_tokens)
end

return root