local skynet = require "skynet"

local root = {}

function root:random(n, m)
    return math.random(n, m)
end

function root:random_number(len)
    local rt = ""
    for i = 1, len, 1 do 
        if i == 1 then
            rt = rt .. self:random(1, 9)
        else
            rt = rt .. self:random(0, 9)
        end
    end
    return rt
end

function root:random_string_generate(gen_len)
    local function random(n, m)
        return math.random(n, m)
    end
    local function random_number(len)
        local rt = ""
        for i = 1, len, 1 do 
            if i == 1 then
                rt = rt .. random(1, 9)
            else
                rt = rt .. random(0, 9)
            end
        end
        return rt
    end
    local function random_small_letter(len)
        local rt = ""
        for i = 1, len, 1 do 
            rt = rt .. string.char(random(97, 122))
        end
        return rt
    end
    local function random_big_letter(len)
        local rt = ""
        for i = 1, len, 1 do 
            rt = rt .. string.char(random(65, 90))
        end
        return rt
    end
    local function_list = {
        random_number,
        random_small_letter,
        random_big_letter
    }
    local random_string = ""
    for i = 1, gen_len do
        local pos = random(1, #function_list)
        local random_char = function_list[pos](1)
        random_string = random_string .. random_char
    end
    return random_string
end

function root:url_generate(path, param)
    local data = {}
    for k,v in pairs(param) do
        local s = string.format("%s=%s", k, v)
        table.insert(data, s)
    end   
    local param = table.concat(data , "&")
    return path .. "?" .. param
end

---检测某个值中是否等于数组中table里面的value字段
function root:value_member(array, val)
    for k, v in ipairs(array) do
        if v.value == val then
            return true
        end
    end
    return false
end

--检测某个值中是否等于数组中table里面的list元素
function root:list_member(array, list)
    for k, v in ipairs(array) do
        if v[1] == list[1] and
            v[2] == list[2] then 
            return true 
        end
    end
    return false
end

function root:time_info()
    local current_time = skynet_time()
    local first_time_today = current_time - (current_time + 8 * 3600) % 86400 -- 今天开始时间
    local last_time_today = first_time_today + 86400 - 1    -- 今天结束时间
    local distance_first_time = current_time - first_time_today -- 距离今天开始时间
    local distance_last_time = last_time_today - current_time  -- 距离今天结束时间
        
    return {
        first_time_today = first_time_today,
        last_time_today = last_time_today,
        distance_first_time = distance_first_time,
        distance_last_time = distance_last_time
    }
end

function root:string_time_sub_3s(timeString)
    local fun = string.gmatch( timeString, "%d+")
    local y = fun() or 0
    if not y then y=0 end
    local m = fun() or 0
    if not m then m=0 end
    local d = fun() or 0
    if not d then d=0 end
    local H = fun() or 0
    if not H then H=0 end
    local M = fun() or 0
    if not M then M=0 end
    local S = fun() or 0
    if not S then S=0 end
    local f = fun() or 0
    if not f then f=0 end

    local S = S - 3
    local time = os.time({year=y, month=m, day=d, hour=H,min=M,sec=S})
    return os.date("%Y-%m-%d", time) .. "T" .. os.date("%H:%M:%S", time) .. "." .. f .. "Z"
end

function root:string_time_add_3s(timeString)
    local fun = string.gmatch( timeString, "%d+")
    local y = fun() or 0
    if not y then y=0 end
    local m = fun() or 0
    if not m then m=0 end
    local d = fun() or 0
    if not d then d=0 end
    local H = fun() or 0
    if not H then H=0 end
    local M = fun() or 0
    if not M then M=0 end
    local S = fun() or 0
    if not S then S=0 end
    local f = fun() or 0
    if not f then f=0 end

    local S = S + 3
    local time = os.time({year=y, month=m, day=d, hour=H,min=M,sec=S})
    return os.date("%Y-%m-%d", time) .. "T" .. os.date("%H:%M:%S", time) .. "." .. f .. "Z"
end

function root:string2time(timeString)
    local fun = string.gmatch(timeString, "%d+")
    local y = fun() or 0
    if not y then y=0 end
    local m = fun() or 0
    if not m then m=0 end
    local d = fun() or 0
    if not d then d=0 end
    local H = fun() or 0
    if not H then H=0 end
    local M = fun() or 0
    if not M then M=0 end
    local S = fun() or 0
    if not S then S=0 end
    local f = fun() or 0
    if not f then f=0 end
    return f, os.time({year=y, month=m, day=d, hour=H,min=M,sec=S})
end

function root:xml_get_value_by_field_name(xml, field_name)
    local xml = string.gsub(xml, "CDATA", "")
    local xml = string.gsub(xml, "<!%[%[", "")
    local xml = string.gsub(xml, "]]>", "")
    local return_code_front_begin, return_code_front_end = string.find(xml, "<" .. field_name .. ">")
    local return_code_back_begin, return_code_back_end = string.find(xml, "</" .. field_name .. ">")
    if return_code_front_begin and
        return_code_front_end and
        return_code_back_begin and
        return_code_back_end then
        local field_value = string.sub(xml, return_code_front_end+1, return_code_back_begin-1)
        return true, field_value
    end
    return false
end

function root:fetch_combined(bet_slot_list)
    local results = {}
    local length = #bet_slot_list
    for i = 1, length-1 do
        for j = i + 1, length do
            table.insert(results, {bet_slot_list[i], bet_slot_list[j]})
            table.insert(results, {bet_slot_list[j], bet_slot_list[i]})
        end
    end
    return results
end

function root:parse_open_bet_slot_list_before(block_id)
    local tow_char_count_of_letter = 0
	local tow_char_of_letter = ""
	local tow_char_count_of_figure = 0
	local tow_char_of_figure = ""
	local three_char_count_of_figure = 0
	local three_char_of_figure = ""
	for i = string.len(block_id), 1, -1 do
		local target_char = string.sub(block_id, i, i)
		if table.member({"1","2","3","4","5","6"}, target_char) then
			tow_char_count_of_figure = tow_char_count_of_figure + 1
			three_char_count_of_figure = three_char_count_of_figure + 1
			if tow_char_count_of_figure <= 2 then
				tow_char_of_figure = tow_char_of_figure .. target_char
			end
			if three_char_count_of_figure <= 3 then
				three_char_of_figure = three_char_of_figure .. target_char
			end
        end
        if table.member({"a","b","c","d","e","f"}, target_char) then
			tow_char_count_of_letter = tow_char_count_of_letter + 1
			if tow_char_count_of_letter <= 2 then
                tow_char_of_letter = tow_char_of_letter .. target_char
            end
        end
    end
    local open_bet_slot_list_two = tow_char_of_figure
    local open_bet_slot_list_three = three_char_of_figure
    local open_bet_slot_list_four = tow_char_of_letter .. tow_char_of_figure

	local open_bet_slot_list_two = self:parse_open_bet_slot_list(open_bet_slot_list_two)
	local open_bet_slot_list_three = self:parse_open_bet_slot_list(open_bet_slot_list_three)
	local open_bet_slot_list_four = self:parse_open_bet_slot_list(open_bet_slot_list_four)
    return {
        open_bet_slot_list_two = open_bet_slot_list_two,
        open_bet_slot_list_three = open_bet_slot_list_three,
        open_bet_slot_list_four = open_bet_slot_list_four
    }
end

function root:parse_open_bet_slot_list(s)
    local k= string.len(s)
    local result ={}
    local switch = {
        ["1"] = 1, ["2"] = 2, ["3"] = 3,
        ["4"] = 4, ["5"] = 5, ["6"] = 6,
        ["a"] = 7, ["b"] = 8, ["c"] = 9,
        ["d"] = 10, ["e"] = 11, ["f"] = 12
    }
    for i=1,k do
        local char = string.sub(s,i,i)
        result[i] = switch[char]
    end
    return result
end

function root:create_expend_time()
    local t1 = skynet.time()
    return function()
        local t2 = skynet.time()
        local t3 = t1
        t1 = t2
        return t2 - t3
    end
end

function root:check_phone_number(phone_number)
    return string.match(phone_number,"[1][3,4,5,7,8,9]%d%d%d%d%d%d%d%d%d") == phone_number
end

function root:alarm_format_chat_command(title, rid, room_number, round, uid, command)
    local env = skynet.getenv("env")
    local text = "#### %s\n" ..
                "> ENV:%s\n\n" ..
                "> RID:%d\n\n" ..
                "> RNB:%s\n\n" ..
                "> RND:%d\n\n" ..
                "> UID:%d\n\n" ..
                "> CMD:%s\n\n"
    local text = string.format(text, title, env, rid, room_number, round, uid, command)
    return true, text, title
end

function root:alarm_format_open_award(title, rid, room_number, blist, open_award)
    local env = skynet.getenv("env")
    local text = "#### %s\n" ..
                "> ENV:%s\n\n" ..
                "> RID:%d\n\n" ..
                "> NMB:%s\n\n" ..
                "> DLT:%s\n\n" ..
                "> TID:%d\n\n"
    local text = string.format(text, title, env, rid, room_number, blist, open_award)
    return true, text, title
end

function root:alarm_format_block_data_disorder(title, rid, room_number, target_utc_date, times_retries)
    local current_utc_date = time_now_utc_str()
    if times_retries >= 0 then
        local env = skynet.getenv("env")
        local text = "#### %s\n" ..
                    "> 环境:%s\n\n" ..
                    "> 房间ID:%d\n\n" ..
                    "> 房间号:%s\n\n" ..
                    "> 区块时间(0时区):%s\n\n" ..
                    "> 当前时间(0时区):%s\n\n" ..
                    "> 重试次数:%d\n\n"
        local text = string.format(text, title, env, rid, room_number, target_utc_date, current_utc_date, times_retries)
        return true, text, title
    end
    return false
end

function root:alarm_format_wait_block_data(title, last_block_data, cost_time)
    local env = skynet.getenv("env")
    local text = "#### %s\n" ..
                "> 环境:%s\n\n" ..
                "> 最后区块:%s\n\n" ..
                "> 超时时间(s):%d\n\n"
    local text = string.format(text, title, env, last_block_data, cost_time)
    return true, text, title
end

function root:alarm_format_recv_block_data(title, first_block_data, block_time)
    local env = skynet.getenv("env")
    local text = "#### %s\n" ..
                "> 环境:%s\n\n" ..
                "> 最前区块:%s\n\n" ..
                "> 阻塞时间(s):%d\n\n"
    local text = string.format(text, title, env, first_block_data, block_time)
    return true, text, title
end

function root:alarm_format_block_data_recv_channel_switch(title, block_number, channel, reason)
    local env = skynet.getenv("env")
    local text = "#### %s\n" ..
                "> 环境:%s\n\n" ..
                "> 区块编号:%s\n\n" ..
                "> 渠道改为:%s\n\n" ..
                "> 切换原因:%s\n\n"
    local text = string.format(text, title, env, block_number, channel, reason)
    return true, text, title
end

function root:alarm_format_logic_expend_time(protocol, name, cost_time)
    if cost_time > 1 then
        local title = "请求逻辑执行耗时报警!"
        local env = skynet.getenv("env")
        local text = "#### 请求逻辑执行耗时报警!\n" ..
                    "> 环境:%s\n\n" ..
                    "> 协议:%s\n\n" ..
                    "> 路径:%s\n\n" ..
                    "> 耗时(s):%s\n\n"
        local text = string.format(text, env, protocol, name, cost_time)
        return true, text, title
    end
    return false
end

return root