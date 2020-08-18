local skynet = require "skynet"
local httpc = require "http.httpc"
local common_conf = require "server.config.common_conf"
local md5 = require "md5"
local common_util = require "server.common.common_util"
local logger = log4.get_logger("server_common_http_util")

local function http_request(method, host, path, param, sendheader)
    local recvheader = {}
    local sendheader = sendheader or {
        ["Content-Type"] = "application/json",
        ["Accept-Charset"] = "utf-8"
    }
    
    if method == "GET" then
        local i = 0
        for k, v in pairs(param) do 
            path = string.format("%s%s%s=%s", path, i == 0 and "?" or "&", k, v)
            i = i + 1
        end
        param = nil
    elseif type(param) == "table" then
        param = cjson_encode(param)
    end

    local req = param
    local status, content = httpc.request(method, host, path, recvheader, sendheader, req)
    local debug_info = {status, method, host, path, tostring(recvheader), tostring(sendheader), tostring(req), content}
    logger.debug("http_request, status:%s, method:%s, host:%s, path:%s, recvheader:%s, sendheader:%s, req:%s, res:%s", table.unpack(debug_info))

    local ok, res = pcall(cjson_decode, content)
    if not ok then
        return content
    end
    return res
end

local root = {}

function root.wechat_pay_unifiedorder(nonce_str, total_fee, spbill_create_ip, notify_url, out_trade_no)
	local param_str = [[
		<xml>
		  <appid>%s</appid>
		  <mch_id>%s</mch_id>
		  <trade_type>%s</trade_type>
		  <body>%s</body>
		  <nonce_str>%s</nonce_str>
		  <total_fee>%d</total_fee>
		  <spbill_create_ip>%s</spbill_create_ip>
		  <notify_url>%s</notify_url>
		  <out_trade_no>%s</out_trade_no>
		  <sign>%s</sign>
		</xml>
    ]]
    local platform = common_conf.WECHAT_APP_PLATFORM_MOBILE
    local appid = common_conf.WECHAT_APP_CONFIG[platform].appid
	local params = {}
	table.insert(params, "appid=" .. appid)
	table.insert(params, "mch_id=" .. common_conf.WECHAT_MCH_ID)
	table.insert(params, "trade_type=" .. common_conf.WECHAT_MCH_TRADE_TYPE)
	table.insert(params, "body=" .. common_conf.WECHAT_MCH_BODY)
	table.insert(params, "nonce_str=" .. nonce_str)
	table.insert(params, "total_fee=" .. total_fee)
	table.insert(params, "spbill_create_ip=" .. spbill_create_ip)
	table.insert(params, "notify_url=" .. notify_url)
	table.insert(params, "out_trade_no=" .. out_trade_no)
    table.sort(params)
	local source_sign = table.concat(params , "&") .. "&key=" .. common_conf.WECHAT_MCH_SECRET
	local sign = string.upper(md5.sumhexa(source_sign))
	local param = string.format(
		param_str,
		appid,
		common_conf.WECHAT_MCH_ID,
		common_conf.WECHAT_MCH_TRADE_TYPE,
		common_conf.WECHAT_MCH_BODY,
		nonce_str,
		total_fee,
		spbill_create_ip,
		notify_url,
		out_trade_no,
		sign
    )
    local sendheader = {
        ["Content-Type"] = "application/xml",
        ["Accept-Charset"] = "utf-8"
    }
    local path = "/pay/unifiedorder"
    local host = common_conf.WECHAT_MCH_HOST
    local xml = http_request("POST", host, path, param, sendheader)
    local ok, return_code = common_util:xml_get_value_by_field_name(xml, "return_code")
    if return_code == "FAIL" then
        local ok, return_msg = common_util:xml_get_value_by_field_name(xml, "return_msg")
        logger.debug("pay unifiedorder fail; return_code:%s, return_msg:%s", return_code, return_msg)
        return false
    end
    local ok, appid = common_util:xml_get_value_by_field_name(xml, "appid")
    local ok, mch_id = common_util:xml_get_value_by_field_name(xml, "mch_id")
    local ok, nonce_str = common_util:xml_get_value_by_field_name(xml, "nonce_str")
    local ok, sign = common_util:xml_get_value_by_field_name(xml, "sign")

    local ok, result_code = common_util:xml_get_value_by_field_name(xml, "result_code")
    if result_code == "FAIL" then
        local ok, err_code = common_util:xml_get_value_by_field_name(xml, "err_code")
        local ok, err_code_des = common_util:xml_get_value_by_field_name(xml, "err_code_des")
        logger.debug("pay unifiedorder fail; err_code:%s, err_code_des:%s", err_code, err_code_des)
        return false
    end

    local ok, trade_type = common_util:xml_get_value_by_field_name(xml, "trade_type")
    local ok, prepay_id = common_util:xml_get_value_by_field_name(xml, "prepay_id")
    local current_time = skynet_time()
    local packge = common_conf.WECHAT_MCH_PACKAGE
    return true, {
        appid = appid,
        mch_id = mch_id,
        nonce_str = nonce_str,
        sign = sign,
        prepay_id = prepay_id,
        timestamp = current_time,
        trade_type = trade_type,
        packge = packge,
        out_trade_no = out_trade_no
    }
end

function root.wechat_pay_orderquery(nonce_str, out_trade_no)
	local param_str = [[
		<xml>
		  <appid>%s</appid>
		  <mch_id>%s</mch_id>
		  <out_trade_no>%s</out_trade_no>
		  <nonce_str>%s</nonce_str>
		  <sign>%s</sign>
		</xml>
    ]]
    local platform = common_conf.WECHAT_APP_PLATFORM_MOBILE
    local appid = common_conf.WECHAT_APP_CONFIG[platform].appid
    local mch_id = common_conf.WECHAT_MCH_ID
	local params = {}
	table.insert(params, "appid=" .. appid)
	table.insert(params, "mch_id=" .. mch_id)
	table.insert(params, "out_trade_no=" .. out_trade_no)
	table.insert(params, "nonce_str=" .. nonce_str)
    table.sort(params)
	local source_sign = table.concat(params , "&") .. "&key=" .. common_conf.WECHAT_MCH_SECRET
	local sign = string.upper(md5.sumhexa(source_sign))
	local param = string.format(
		param_str,
		appid,
		mch_id,
		out_trade_no,
		nonce_str,
		sign
    )
    local sendheader = {
        ["Content-Type"] = "application/xml",
        ["Accept-Charset"] = "utf-8"
    }
    local path = "/pay/orderquery"
    local host = common_conf.WECHAT_MCH_HOST
    local xml = http_request("POST", host, path, param, sendheader)
    local ok, return_code = common_util:xml_get_value_by_field_name(xml, "return_code")
    if return_code == "FAIL" then
        local ok, return_msg = common_util:xml_get_value_by_field_name(xml, "return_msg")
        logger.debug("pay unifiedorder fail; return_code:%s, return_msg:%s", return_code, return_msg)
        return false
    end
    local ok, appid = common_util:xml_get_value_by_field_name(xml, "appid")
    local ok, mch_id = common_util:xml_get_value_by_field_name(xml, "mch_id")
    local ok, nonce_str = common_util:xml_get_value_by_field_name(xml, "nonce_str")
    local ok, sign = common_util:xml_get_value_by_field_name(xml, "sign")

    local ok, result_code = common_util:xml_get_value_by_field_name(xml, "result_code")
    if result_code == "FAIL" then
        local ok, err_code = common_util:xml_get_value_by_field_name(xml, "err_code")
        local ok, err_code_des = common_util:xml_get_value_by_field_name(xml, "err_code_des")
        logger.debug("pay unifiedorder fail; err_code:%s, err_code_des:%s", err_code, err_code_des)
        return false
    end
    local ok, openid = common_util:xml_get_value_by_field_name(xml, "openid")
    if not ok then openid = "" end
    local ok, is_subscribe = common_util:xml_get_value_by_field_name(xml, "is_subscribe")
    if not ok then is_subscribe = "" end
    local ok, trade_type = common_util:xml_get_value_by_field_name(xml, "trade_type")
    if not ok then trade_type = "" end
    local ok, bank_type = common_util:xml_get_value_by_field_name(xml, "bank_type")
    if not ok then bank_type = "" end
    local ok, total_fee = common_util:xml_get_value_by_field_name(xml, "total_fee")
    if not ok then total_fee = "" end
    local ok, fee_type = common_util:xml_get_value_by_field_name(xml, "fee_type")
    if not ok then fee_type = "" end
    local ok, transaction_id = common_util:xml_get_value_by_field_name(xml, "transaction_id")
    if not ok then transaction_id = "" end
    local ok, out_trade_no = common_util:xml_get_value_by_field_name(xml, "out_trade_no")
    if not ok then out_trade_no = "" end
    local ok, time_end = common_util:xml_get_value_by_field_name(xml, "time_end")
    if not ok then time_end = "" end
    local ok, trade_state = common_util:xml_get_value_by_field_name(xml, "trade_state")
    if not ok then trade_state = "" end
    local ok, cash_fee = common_util:xml_get_value_by_field_name(xml, "cash_fee")
    if not ok then cash_fee = "" end
    local ok, trade_state_desc = common_util:xml_get_value_by_field_name(xml, "trade_state_desc")
    if not ok then trade_state_desc = "" end
    local ok, cash_fee_type = common_util:xml_get_value_by_field_name(xml, "cash_fee_type")
    if not ok then cash_fee_type = "" end

    if trade_state ~= "SUCCESS" then
        return false
    end

    return true, {
        appid = appid, mch_id = mch_id, nonce_str = nonce_str, sign = sign, openid = openid,
        is_subscribe = is_subscribe, trade_type = trade_type, bank_type = bank_type, total_fee = total_fee, fee_type = fee_type,
        transaction_id = transaction_id, out_trade_no = out_trade_no, time_end = time_end, cash_fee = cash_fee, cash_fee_type = cash_fee_type,
        trade_state = trade_state, trade_state_desc = trade_state_desc
    }
end

function root.fetch_dfuse_block_data(begin_time)
    local param = {
        api_key = common_conf.DFUSE_API_KEY
    }
    local path = "/v1/auth/issue"
    local host = common_conf.DFUSE_AUTH_URL
    local res = http_request("POST", host, path, param)
    local token = res.token

    local sendheader = {
        ["Content-Type"] = "application/json",
        ["Accept-Charset"] = "utf-8",
        ["Authorization"] = "Bearer " .. token
    }
    local param = {
        time = begin_time,
        comparator = "gte"
    }
    local path = "/v0/block_id/by_time"
    local host = common_conf.DFUSE_BLOCK_ID_URL
    local res = http_request("GET", host, path, param, sendheader)
    local block = res.block

    local f, utc_timestamp = common_util:string2time(block.time)
    local utc_time = os.date("%H:%M:%S", utc_timestamp + 8 * 60 * 60) .. "." .. f

    local open_bet_slot_list_tab = common_util:parse_open_bet_slot_list_before(block.id)
    return {
        block_number = block.num,
        block_hash = block.id,
        utc_date = block.time,
        utc_time = utc_time,
        utc_timestamp = utc_timestamp,
        open_bet_slot_list_two = open_bet_slot_list_tab.open_bet_slot_list_two,
        open_bet_slot_list_three = open_bet_slot_list_tab.open_bet_slot_list_three,
		open_bet_slot_list_four = open_bet_slot_list_tab.open_bet_slot_list_four
    }
end

function root.fetch_eosflare_block_data(block_num)
    local param = {
        block_num = block_num
    }
    local path = "/chain/get_block"
    local host =common_conf.EOSFLARE_BLOCK_ID_URL
    local res = http_request("POST", host, path, param)
    local block = res.block

    local f, utc_timestamp = common_util:string2time(block.timestamp)
    local utc_time = os.date("%H:%M:%S", utc_timestamp + 8 * 60 * 60) .. "." .. f

    block.id = string.lower(block.id)
    local open_bet_slot_list_tab = common_util:parse_open_bet_slot_list_before(block.id)
    return {
        block_number = block.block_num,
        block_hash = block.id,
        utc_date = block.timestamp,
        utc_time = utc_time,
        utc_timestamp = utc_timestamp,
        open_bet_slot_list_two = open_bet_slot_list_tab.open_bet_slot_list_two,
        open_bet_slot_list_three = open_bet_slot_list_tab.open_bet_slot_list_three,
		open_bet_slot_list_four = open_bet_slot_list_tab.open_bet_slot_list_four
    }
end

function root.fetch_wechat_access_token(platform, code)
    local appid = common_conf.WECHAT_APP_CONFIG[platform].appid
    local secret = common_conf.WECHAT_APP_CONFIG[platform].secret
    local grant_type = "authorization_code"
    local param = {
        appid = appid,
        secret = secret,
        code = code,
        grant_type = grant_type
    }
    local host = common_conf.WECHAT_APP_CONFIG[platform].host
    local path = "/sns/oauth2/access_token"
    local res = http_request("GET", host, path, param)
    if res.errcode then
        return false, res
    end
    return true, res
end

function root.fetch_wechat_user_info(platform, access_token, openid)
    local param = {
        access_token = access_token,
        openid = openid
    }
    local host = common_conf.WECHAT_APP_CONFIG[platform].host
    local path = "/sns/userinfo"
    local res = http_request("GET", host, path, param)
    if res.errcode then
        return false, res
    end
    return true, res
end

function root.refresh_wechat_token(platform, refresh_token)
    local appid = common_conf.WECHAT_APP_CONFIG[platform].appid
    local grant_type = "refresh_token"
    local param = {
        appid = appid,
        grant_type = grant_type,
        refresh_token = refresh_token
    }
    local host = common_conf.WECHAT_APP_CONFIG[platform].host
    local path = "/sns/oauth2/refresh_token"
    local res = http_request("GET", host, path, param)
    if res.errcode then
        return false, res
    end
    return true, res
end

function root.auth_wechat_token(platform, openid, access_token)
    local param = {
        openid = openid,
        access_token = access_token
    }
    local host = common_conf.WECHAT_APP_CONFIG[platform].host
    local path = "/sns/auth"
    local res = http_request("GET", host, path, param)
    if res.errcode ~= 0 then
        return false, res
    end
    return true
end

function root.notify_dingtalk(title, text)
    local host = common_conf.DINGTALK_HOST
    local path = common_conf.DINGTALK_PATH[skynet.getenv("env")]
    local param = {
        msgtype = "markdown",
        markdown = {
            title = title,
            text = text
        }
    }
    local res = http_request("POST", host, path, param)
    if res.errcode ~= 0 then
        return false, res
    end
    return true
end

function root.send_auth_code(phone_number, auth_code)
    local host = common_conf.SMS_SERVICE_HOST

    local path = "/auth_code"
    local param = {
        phone_number = phone_number,
        auth_code = auth_code,
        sign_name = common_conf.SMS_SIGN_NAME,
        template_code = common_conf.SMS_TEMPLATE_CODE
    }
    return http_request("GET", host, path, param)
end

function root.apple_pay_verify(reciept_data)
    local host = common_conf.APPLE_ITUNES_HOST_DEV
    if skynet.getenv("env") == common_conf.ENV_TYPE_TEST then
        host = common_conf.APPLE_ITUNES_HOST_TEST
    elseif skynet.getenv("env") == common_conf.ENV_TYPE_PROD then
        host = common_conf.APPLE_ITUNES_HOST_PROD
    end
    local path = "/verifyReceipt"
    local param = {
        ["receipt-data"] = reciept_data
    }
    local res = http_request("POST", host, path, param)
    local status = res.status
    if status ~= 0 then
        return false
    end
    return true, res.receipt
end

return root
