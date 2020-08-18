local skynet = require "skynet"
local common_util = require "server.common.common_util"
local code = require "server.config.code"
local game_db = require "server.common.game_db"
local wechat_tokens_db = require "server.common.wechat_tokens_db"
local game_users_db = require "server.common.game_users_db"
local common_conf = require "server.config.common_conf"
local http_util = require "server.common.http_util"
local logger = log4.get_logger("server_frontend_request_web_user")

local REQUEST = {}

function REQUEST:local_login(msg)
    local uid = msg.uid
    local avatar = msg.avatar
    local nick_name = msg.nick_name
    if type(uid) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if skynet.getenv("env") == common_conf.ENV_TYPE_PROD then
        -- return {code = code.ERROR_PLEASE_DOWNLOAD_NEWEST, err = code.ERROR_PLEASE_DOWNLOAD_NEWEST_MSG}
    end
    if uid < 1000000 then -- guest uid is 7 bit.
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end

    local token = "76491a8d530c11f397789e45bb7c5237a67f185e"
    local avatar = 'http://thirdwx.qlogo.cn/mmopen/vi_32/6M9ribII6fhN4jwHXfZiaNibpjuekNdPWiaHCRdT7XVjBYaHojL0gUJkdxwpK2NZ4GsbF6ocj8WQmKgMj5Y1PKthRw/132'
    local nick_name = nick_name or "HelloWorld"
    local gender = 1
    local language = ""
    local city = ""
    local province = ""
    local country = ""
    local privilege = cjson_encode({})
    local unionid = ""

    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        local param = {
            uid = uid, avatar = avatar, nick_name = nick_name, gold_coin = 0, diamond = 0,
            room_card = common_conf.NEW_USER_DEFAULT_ROOM_CARD_AMOUNT, gender = gender, sound = 50, music = 50, rid = common_conf.NOT_IN_ROOM,
            agency = 0, language = language, city = city, province = province, country = country,
            privilege = privilege, unionid = unionid
        }
        game_users_db:insert_game_users(param)
    end
    local data = {
        token = token
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:wechat_login(msg)
    local tmp_code = msg.code
    local platform = msg.platform
    if type(tmp_code) ~= "string" or
        type(platform) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not table.member(common_conf.WECHAT_APP_PLATFORM_LIST, platform) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok, res = http_util.fetch_wechat_access_token(platform, tmp_code)
    if not ok then
        return {code = res.errcode, err = res.errmsg}
    end
    local access_token = res.access_token
    local openid = res.openid
    local refresh_token = res.refresh_token
    local expires_in = res.expires_in

    local ok, res = http_util.fetch_wechat_user_info(platform, access_token, openid)
    if not ok then
        return {code = res.errcode, err = res.errmsg}
    end
    local avatar = res.headimgurl
    local nick_name = res.nickname
    local gender = res.sex

    local language = res.language
    local city = res.city
    local province = res.province
    local country = res.country
    local privilege = cjson_encode(res.privilege)
    local unionid = res.unionid

    local ok = game_users_db:is_exist_game_user_by_unionid(unionid)
    if not ok then
        local uid = game_db:fetch_uid()
        local param = {
            uid = uid, avatar = avatar, nick_name = nick_name, gold_coin = 0, diamond = 0,
            room_card = common_conf.NEW_USER_DEFAULT_ROOM_CARD_AMOUNT, gender = gender, sound = 50, music = 50, rid = common_conf.NOT_IN_ROOM,
            agency = 0, language = language, city = city, province = province, country = country,
            privilege = privilege, unionid = unionid
        }
        game_users_db:insert_game_users(param)
    else
        local param = {
            nick_name = nick_name, avatar = avatar, gender = gender, language = language, city = city,
            province = province, country = country, privilege = privilege
        }
        game_users_db:update_game_user_info_by_unionid(unionid, param)
    end

    local refresh_time = skynet_time()
    local ok = wechat_tokens_db:is_exist_wechat_token_by_unionid(platform, unionid)
    if not ok then
        local param = {
            expires_in = expires_in, refresh_time = refresh_time, platform = platform, openid = openid, access_token = access_token,
            refresh_token = refresh_token, unionid = unionid
        }
        wechat_tokens_db:insert_wechat_tokens(param)
    else
        local param = {
            expires_in = expires_in, refresh_time = refresh_time, openid = openid, access_token = access_token, refresh_token = refresh_token
        }
        wechat_tokens_db:update_wechat_tokens(platform, unionid, param)
    end

    local uid = game_users_db:fetch_game_user_uid_by_unionid(unionid)
    local data = {
        token = access_token,
        uid = uid
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:fetch_token(msg)
    local uid = msg.uid
    local platform = msg.platform
    if type(uid) ~= "number" or
        type(platform) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not table.member(common_conf.WECHAT_APP_PLATFORM_LIST, platform) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local unionid = game_users_db:fetch_game_user_unionid_by_uid(uid)
    local ok = wechat_tokens_db:is_exist_wechat_token_by_unionid(platform, unionid)
    if not ok then
        return {code = code.ERROR_WECHAT_TOKEN_UNFOUND, err = code.ERROR_WECHAT_TOKEN_UNFOUND_MSG}
    end
    local wechat_token = wechat_tokens_db:fetch_wechat_token(platform, unionid)

    local expires_in = wechat_token.expires_in
    local refresh_time = wechat_token.refresh_time
    local openid = wechat_token.openid
    local access_token = wechat_token.access_token
    local refresh_token = wechat_token.refresh_token
    local current_time = skynet_time()
    local offset_time = current_time - refresh_time
    if offset_time > (expires_in / 2) then -- 7200 / 2 = 3600s
        local ok, res = http_util.refresh_wechat_token(platform, refresh_token)
        if not ok then
            return {code = res.errcode, err = res.errmsg}
        end
        local openid = res.openid -- 如果扩展其他第三方平台或者小程序的话可能有用，暂时这一步倒没什么用
        local access_token = res.access_token
        local expires_in = res.expires_in
        local refresh_token = res.refresh_token
        local refresh_time = current_time
        local param = {
            expires_in = expires_in, refresh_time = refresh_time, openid = openid, access_token = access_token, refresh_token = refresh_token
        }
        wechat_tokens_db:update_wechat_tokens(platform, unionid, param)
    end
    local wechat_token = wechat_tokens_db:fetch_wechat_token(platform, unionid)
    local openid = wechat_token.openid
    local access_token = wechat_token.access_token
    
    local ok, res = http_util.fetch_wechat_user_info(platform, access_token, openid)
    if not ok then
        return {code = res.errcode, err = res.errmsg}
    end
    local avatar = res.headimgurl
    local nick_name = res.nickname
    local gender = res.sex

    local language = res.language
    local city = res.city
    local province = res.province
    local country = res.country
    local privilege = cjson_encode(res.privilege)
    --local unionid = res.unionid

    local param = {
        nick_name = nick_name, avatar = avatar, gender = gender, language = language, city = city,
        province = province, country = country, privilege = privilege
    }
    game_users_db:update_game_user_info_by_unionid(unionid, param)

    local data = {
        token = access_token,
        uid = uid
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:wechat_config(msg)
    local platform = msg.platform
    if type(platform) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    if not table.member(common_conf.WECHAT_APP_PLATFORM_LIST, platform) then
        return {code = code.ERROR_CLIENT_PARAMETER_VALUE, err = code.ERROR_CLIENT_PARAMETER_VALUE_MSG}
    end
    local appid = common_conf.WECHAT_APP_CONFIG[platform].appid
    local secret = common_conf.WECHAT_APP_CONFIG[platform].secret
    local data = {
        app_id = appid,
        app_secret = secret
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:wechat_pay_unifiedorder(msg)
    local uid = msg.uid
    local id = msg.id
    if type(uid) ~= "number" or
        type(id) ~= "number" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_db:is_exist_recharge_setting_by_id(id)
    if not ok then
        return {code = code.ERROR_RECHARGE_SETTINGS_UNFOUND, err = code.ERROR_RECHARGE_SETTINGS_UNFOUND_MSG}
    end

    local recharge_setting = game_db:fetch_recharge_setting_by_id(id)
    local price = recharge_setting.price
    local buy = recharge_setting.buy
    local source_ip = self.ip

	local nonce_str = common_util:random_string_generate(32)
    local out_trade_no = "weixin" .. common_util:random_string_generate(26)
    local total_fee = price * 100

    -- 充值折扣
    local game_user = game_users_db:fetch_game_user_by_uid(uid)
    local discount = game_user.discount
    local invite_code = game_user.invite_code
    local ok = game_db:is_exist_invite_code_by_uid(uid)
    if discount == common_conf.DEFAULT_DISCOUNT and
        (invite_code > common_conf.DEFAULT_INVITE_CODE or ok) then
        
        if invite_code == common_conf.DEFAULT_INVITE_CODE and ok then -- 自己是合伙人
            local invite_code_info = game_db:fetch_invite_code_by_uid(uid)
            discount = invite_code_info.partner_recharge_discount
        elseif invite_code > common_conf.DEFAULT_INVITE_CODE and ok then -- 自己是代理
            local invite_code_info = game_db:fetch_invite_code_by_id(invite_code)
            discount = invite_code_info.super_agent_recharge_discount
        else -- 自己是绑定邀请码的普通成员 invite_code > common_conf.DEFAULT_INVITE_CODE and (not ok)
            local invite_code_info = game_db:fetch_invite_code_by_id(invite_code)
            discount = invite_code_info.next_agent_recharge_discount
        end

    end
    
    if discount > common_conf.DEFAULT_DISCOUNT then
        total_fee = math.floor(total_fee * discount / 100)
    end

	local spbill_create_ip = source_ip
    local notify_url = "/user/wechat_pay"
    local notify_url_switch = {
        [common_conf.ENV_TYPE_DEV] = common_conf.GAME_SERVER_HOST_DEV .. notify_url,
        [common_conf.ENV_TYPE_TEST] = common_conf.GAME_SERVER_HOST_TEST .. notify_url,
        [common_conf.ENV_TYPE_PROD] = common_conf.GAME_SERVER_HOST_PROD .. notify_url
    }
    local notify_url = notify_url_switch[skynet.getenv("env")]
    local ok, res = http_util.wechat_pay_unifiedorder(nonce_str, total_fee, spbill_create_ip, notify_url, out_trade_no)
    if not ok then
        return {code = code.ERROR_APP_WECHAT_PAY_UNIFIEDORDER, err = code.ERROR_APP_WECHAT_PAY_UNIFIEDORDER_MSG}
    end
    
    local type = 3      -- 1:金币，2:钻石，3:房卡
    local state = 1     -- 1:未支付,2:成功
    local mode = 1      -- 1:微信,2:公众号,3:苹果
    local order_number = out_trade_no
    game_db:insert_payment_records(uid, type, price, buy, state, mode, order_number, discount)

    local data = {
        appid = res.appid,
        mch_id = res.mch_id,
        nonce_str = res.nonce_str,
        sign = res.sign,
        prepay_id = res.prepay_id,
        timestamp = res.timestamp,
        trade_type = res.trade_type,
        packge = res.packge,
        out_trade_no = res.out_trade_no
    }
    return {code = code.SUCCEED, err = code.SUCCEED_MSG, data = data}
end

function REQUEST:wechat_pay(msg)
    local uid = msg.uid
    local id = msg.id
    local out_trade_no = msg.out_trade_no
    if type(uid) ~= "number" or
        type(id) ~= "number" or
        type(out_trade_no) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_db:is_exist_recharge_setting_by_id(id)
    if not ok then
        return {code = code.ERROR_RECHARGE_SETTINGS_UNFOUND, err = code.ERROR_RECHARGE_SETTINGS_UNFOUND_MSG}
    end
	local nonce_str = common_util:random_string_generate(32)
	local ok, res = http_util.wechat_pay_orderquery(nonce_str, out_trade_no)
    if not ok then
        return {code = code.ERROR_APP_WECHAT_PAY_ORDERQUERY, err = code.ERROR_APP_WECHAT_PAY_ORDERQUERY_MSG}
    end
    local ok = game_db:is_exist_payment_record_by_ordernumber(out_trade_no)
    if not ok then
        return {code = code.ERROR_PAYMENT_RECORD_UNFOUND, err = code.ERROR_PAYMENT_RECORD_UNFOUND_MSG}
    end

    local state = 2     -- 1:未支付,2:成功
    local ok = game_db:is_exist_payment_record_succeed_by_ordernumber(out_trade_no, state)
    if ok then
        return {code = code.SUCCEED, err = code.SUCCEED_MSG}
    end

    local recharge_setting = game_db:fetch_recharge_setting_by_id(id)
    local price = recharge_setting.price
    local buy = recharge_setting.buy

    local order_number = out_trade_no
    game_db:update_payment_record_state(state, order_number)

    game_users_db:increase_game_user_room_card(buy, uid)

    -- 奖励佣金
    local game_user = game_users_db:fetch_game_user_by_uid(uid)
    local discount = game_user.discount
    local invite_code = game_user.invite_code
    local ok = game_db:is_exist_invite_code_by_uid(uid)
    if discount == common_conf.DEFAULT_DISCOUNT and
        (invite_code > common_conf.DEFAULT_INVITE_CODE or ok) then

        local current_time = skynet_time()
        if invite_code == common_conf.DEFAULT_INVITE_CODE and ok then -- 自己是合伙人
            local detail = "合伙人充值时 不需要反佣给任何人"
        elseif invite_code > common_conf.DEFAULT_INVITE_CODE and ok then -- 自己是代理
            local partner_invite_code_info = game_db:fetch_invite_code_by_id(invite_code)
            local partner_uid = partner_invite_code_info.uid
            local super_agent_recharge_discount = partner_invite_code_info.super_agent_recharge_discount
            local super_agent_recharge_partner_rebate = partner_invite_code_info.super_agent_recharge_partner_rebate

            local cost = price * 100
            if super_agent_recharge_discount > common_conf.DEFAULT_DISCOUNT then
                cost = math.floor(cost * super_agent_recharge_discount / 100)
            end

            local brokerage = math.floor(cost * super_agent_recharge_partner_rebate / 100)
            game_db:insert_brokerage_records(partner_uid, uid, cost, brokerage, current_time)
        else -- 自己是绑定邀请码的普通成员 invite_code > common_conf.DEFAULT_INVITE_CODE and (not ok)
            -- 给上级代理反佣
            local prev_level_agent_invite_code_info = game_db:fetch_invite_code_by_id(invite_code)
            local prev_level_agent_role = prev_level_agent_invite_code_info.role
            local prev_level_agent_uid = prev_level_agent_invite_code_info.uid
            local next_agent_recharge_discount = prev_level_agent_invite_code_info.next_agent_recharge_discount
            local next_agent_recharge_current_agent_rebate = prev_level_agent_invite_code_info.next_agent_recharge_current_agent_rebate

            local cost = price * 100
            if next_agent_recharge_discount > common_conf.DEFAULT_DISCOUNT then
                cost = math.floor(cost * next_agent_recharge_discount / 100)
            end

            local brokerage = math.floor(cost * next_agent_recharge_current_agent_rebate / 100)
            game_db:insert_brokerage_records(prev_level_agent_uid, uid, cost, brokerage, current_time)

            -- 给合伙人反佣
            local super_agent_game_user = game_users_db:fetch_game_user_by_uid(prev_level_agent_uid)
            local super_agent_invite_code = super_agent_game_user.invite_code

            local partner_invite_code_info = game_db:fetch_invite_code_by_id(super_agent_invite_code)
            local partner_uid = partner_invite_code_info.uid
            local normal_agent_recharge_partner_rebate = partner_invite_code_info.normal_agent_recharge_partner_rebate

            local brokerage = math.floor(cost * normal_agent_recharge_partner_rebate / 100)
            game_db:insert_brokerage_records(partner_uid, uid, cost, brokerage, current_time)
        end
    end

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

function REQUEST:apple_pay(msg)
    local uid = msg.uid
    local id = msg.id
    local reciept_data = msg.reciept_data
    if type(uid) ~= "number" or
        type(id) ~= "number" or
        type(reciept_data) ~= "string" then
        return {code = code.ERROR_CLIENT_PARAMETER_TYPE, err = code.ERROR_CLIENT_PARAMETER_TYPE_MSG}
    end
    local ok = game_users_db:is_exist_game_user_by_uid(uid)
    if not ok then
        return {code = code.ERROR_GAME_USER_UNFOUND, err = code.ERROR_GAME_USER_UNFOUND_MSG}
    end
    local ok = game_db:is_exist_recharge_setting_by_id(id)
    if not ok then
        return {code = code.ERROR_RECHARGE_SETTINGS_UNFOUND, err = code.ERROR_RECHARGE_SETTINGS_UNFOUND_MSG}
    end
    local ok, reciept_info = http_util.apple_pay_verify(reciept_data)
    if not ok then
        return {code = code.ERROR_APPLY_PAY_VERIFY_FAIL, err = code.ERROR_APPLY_PAY_VERIFY_FAIL_MSG}
    end
    local order_number = (reciept_info.in_app[1] or {}).transaction_id or "not_found"
    local recharge_setting = game_db:fetch_recharge_setting_by_id(id)
    local buy = recharge_setting.buy
    local price = recharge_setting.price
    local discount = common_conf.DEFAULT_DISCOUNT

    local type = 3      -- 1:金币，2:钻石，3:房卡
    local state = 2     -- 1:未支付,2:成功
    local mode = 3      -- 1:微信,2:公众号,3:苹果
    game_db:insert_payment_records(uid, type, price, buy, state, mode, order_number, discount)

    game_users_db:increase_game_user_room_card(buy, uid)

    return {code = code.SUCCEED, err = code.SUCCEED_MSG}
end

local root = {}

function root.request(req)
    local name = req.params.name
    if not REQUEST[name] then
        return {code = code.ERROR_NAME_UNFOUND, err = code.ERROR_NAME_UNFOUND_MSG}
    end
    local msg
    if req.method == "GET" then
        msg = req.query
    else
        msg = cjson_decode(req.body)
    end
    local trace_err = ""
    local trace = function (e)
        trace_err = e .. debug.traceback()
    end
    local ok, res = xpcall(REQUEST[name], trace, req, msg)
    if not ok then
        logger.error("%s %s %s", req.path, tostring(msg), trace_err)
        return {code = code.ERROR_INTERNAL_SERVER, err = code.ERROR_INTERNAL_SERVER_MSG}
    end
    return res
end

return root