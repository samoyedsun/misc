local skynet = require "skynet"
local logger = log4.get_logger("server_lualib_seat_mgr")

local state = {}

function state:new()
    local o = {
        online = true,
        ready = false,
        banker = false
    }
    setmetatable(o, {__index = self})
    return o
end

function state:get_online()
    return self.online
end

function state:get_ready()
    return self.ready
end

function state:get_banker()
    return self.banker
end

function state:set_online(online)
    self.online = online
end

function state:set_ready(ready)
    self.ready = ready
end

function state:set_banker(banker)
    self.banker = banker
end

function state:totable()
    return {
        ready = self.ready,
        online = self.online,
        banker = self.banker
    }
end

local seat = {}

function seat:new(sid)
    local o = {
        sid = sid,
        uid = 0,
        score = 0
    }
    setmetatable(o, {__index = self})
    return o
end

function seat:use(uid)
    self.uid = uid
end

function seat:unused()
    self.uid = 0
end

function seat:in_use()
    if self.uid == 0 then
        return false
    end
    return true
end

function seat:get_uid()
    return self.uid
end

function seat:get_sid()
    return self.sid
end

function seat:get_score()
    return self.score
end

function seat:set_score(score)
    self.score = score
end

function seat:totable()
    return {
        sid = self.sid,
        uid = self.uid
    }
end

local root = {}

function root:init(user_limit)
    local seat_obj_list = {}
    local user_limit = user_limit + 1
    for i = 1, user_limit do
        table.insert(seat_obj_list, seat:new(i))
    end

    self.seat_obj_list = seat_obj_list
    function self:alloc_seat(uid)
        for k, seat_obj in ipairs(self.seat_obj_list) do
            if not seat_obj:in_use() then
                return seat_obj:use(uid)
            end
        end
    end
    function self:get_sid(uid)
        for k, seat_obj in ipairs(self.seat_obj_list) do
            if uid == seat_obj:get_uid() then
                return seat_obj:get_sid()
            end
        end
    end
    function self:get_score(uid)
        for k, seat_obj in ipairs(self.seat_obj_list) do
            if uid == seat_obj:get_uid() then
                return seat_obj:get_score()
            end
        end
    end
    function self:set_score(uid, score)
        for k, seat_obj in ipairs(self.seat_obj_list) do
            if uid == seat_obj:get_uid() then
                seat_obj:set_score(score)
            end
        end
    end
    function self:real_uid_list()
        local result = {}
        for k, seat_obj in ipairs(self.seat_obj_list) do
            if seat_obj:in_use() then
                table.insert(result, seat_obj:get_uid())
            end
        end
        return result
    end
    function self:release_seat(uid)
        for k, seat_obj in ipairs(self.seat_obj_list) do
            if uid == seat_obj:get_uid() then
                seat_obj:set_score(0)
                return seat_obj:unused()
            end
        end
    end
    function self:swap_seat_to_last(uid)
        local len = #self.seat_obj_list
        local seat_obj = self.seat_obj_list[len]
        if seat_obj:get_uid() == uid then
            return
        end
        if not seat_obj:in_use() then
            ---
            local score = self:get_score(uid)
            
            seat_obj:use(uid)
            self:release_seat(uid)
            
            self:set_score(uid, score)
            ---
        else
            local target_uid = seat_obj:get_uid()
            local target_score = self:get_score(target_uid)
            ---
            local score = self:get_score(uid)
            
            seat_obj:use(uid)
            self:release_seat(uid)
            
            self:set_score(uid, score)
            ---
            self:alloc_seat(target_uid)
            self:set_score(target_uid, target_score)
        end
    end

    self.uid_to_game_user = {}
    function self:set_game_user(uid, game_user)
        self.uid_to_game_user[uid] = game_user
    end
    function self:get_game_user(uid)
        return self.uid_to_game_user[uid]
    end
    function self:del_game_user(uid)
        self.uid_to_game_user[uid] = nil
    end

    self.uid_to_user_net = {}
    function self:set_user_net(uid, user_net)
        self.uid_to_user_net[uid] = user_net
    end
    function self:get_user_net(uid)
        return self.uid_to_user_net[uid]
    end
    function self:del_user_net(uid)
        self.uid_to_user_net[uid] = nil
    end

    self.uid_to_state_obj = {}
    function self:set_state(uid, state_obj)
        self.uid_to_state_obj[uid] = state_obj
    end
    function self:set_state_ready(uid, flag)
        local state_obj = self.uid_to_state_obj[uid]
        if not state_obj then
            logger.error("更新准备状态时为空!")
            return
        end
        return state_obj:set_ready()
    end
    function self:set_state_online(uid, flag)
        local state_obj = self.uid_to_state_obj[uid]
        if not state_obj then
            logger.error("更新在线状态时为空!")
            return
        end
        return state_obj:set_online(flag)
    end
    function self:set_state_banker(uid, flag)
        local state_obj = self.uid_to_state_obj[uid]
        if not state_obj then
            logger.error("更新庄状态时为空!")
            return
        end
        return state_obj:set_banker(flag)
    end
    function self:get_state_ready(uid)
        local state_obj = self.uid_to_state_obj[uid]
        if not state_obj then
            logger.error("获取准备状态时为空!")
            return
        end
        return state_obj:get_ready()
    end
    function self:get_state_online(uid)
        local state_obj = self.uid_to_state_obj[uid]
        if not state_obj then
            logger.error("获取在线状态时为空!")
            return
        end
        return state_obj:get_online()
    end
    function self:get_state_banker(uid)
        local state_obj = self.uid_to_state_obj[uid]
        if not state_obj then
            logger.error("获取庄状态时为空!")
            return
        end
        return state_obj:get_banker()
    end
    function self:get_state_ready_all(uid)
        local result = {}
        for tmp_uid, state_obj in pairs(self.uid_to_state_obj) do
            if tmp_uid ~= uid then
                table.insert(result, state_obj:get_ready())
            end
        end
        return result
    end
    function self:del_state(uid)
        self.uid_to_state_obj[uid] = nil
    end

    self.uid_to_cache_score = {}
    function self:set_cache_score(uid, cache_score)
        self.uid_to_cache_score[uid] = cache_score
    end
    function self:get_cache_score(uid)
        return self.uid_to_cache_score[uid]
    end
    
    self.total_join_uid_list = {}
    function self:append_total_join_uid_list(uid)
        if not table.member(self.total_join_uid_list, uid) then
            table.insert(self.total_join_uid_list, uid)
        end
    end
    function self:fetch_total_join_uid_list()
        return self.total_join_uid_list
    end
end

function root:join_seat(uid, score, game_user, user_net)
    local cache_score = self:get_cache_score(uid)

    self:alloc_seat(uid)
    self:set_game_user(uid, game_user)
    self:set_user_net(uid, user_net)
    self:set_state(uid, state:new())

    self:set_score(uid, cache_score or score)
    self:append_total_join_uid_list(uid)
end

function root:leave_seat(uid, is_cache)
    local curr_score = self:get_score(uid)

    self:release_seat(uid)
    self:del_game_user(uid)
    self:del_user_net(uid)
    self:del_state(uid)

    if is_cache then
        self:set_cache_score(uid, curr_score)
    end
end

function root:in_room(uid)
    for k, seat_obj in ipairs(self.seat_obj_list) do
        if uid == seat_obj:get_uid() then
            return true
        end
    end
    return false
end

function root:full()
    for k, seat_obj in ipairs(self.seat_obj_list) do
        if not seat_obj:in_use() then
            return false
        end
    end
    return true
end

function root:seat_info(uid)
    local ready = (self:get_state_ready(uid) and {1} or {0})[1]
    local online = (self:get_state_online(uid) and {1} or {0})[1]
    local banker = (self:get_state_banker(uid) and {1} or {0})[1]
    
    local game_user = self:get_game_user(uid)
    local sid = self:get_sid(uid)
    local score = self:get_score(uid)
    return {
        game_user = game_user,
        sid = sid,
        ready = ready,
        online = online,
        banker = banker,
        score = score
    }
end

function root:seat_info_list()
    local result = {}
    local real_uid_list = self:real_uid_list()
    for k, uid in ipairs(real_uid_list) do
        table.insert(result, self:seat_info(uid))
    end
    return result
end

function root:is_all_ready(uid)
    local state_ready_list = self:get_state_ready_all(uid)
    for k, ready in ipairs(state_ready_list) do
        if ready == false then
            return false
        end
    end
    return true
end

function root:banker(uid)
    local banker = self:get_state_banker(uid)
    if not banker then
        return false
    end
    return true
end

function root:is_exist_banker()
    local real_uid_list = self:real_uid_list()
    for k, tmp_uid in ipairs(real_uid_list) do
        local ok = self:banker(tmp_uid)
        if ok then
           return true 
        end
    end
    return false
end

function root:get_banker_uid()
    local real_uid_list = self:real_uid_list()
    for k, uid in ipairs(real_uid_list) do
        local ok = self:banker(uid)
        if ok then
           return uid 
        end
    end
end

function root:real_uid_list_exclude_banker()
    local real_uid_list = self:real_uid_list()
    if #real_uid_list == 1 then
        return real_uid_list
    end
    if not self:is_exist_banker() then
        return real_uid_list
    end
    local result = {}
    for k, uid in ipairs(real_uid_list) do
        if not self:get_state_banker(uid) then
            table.insert(result, uid)
        end
    end
    return result
end

function root:random_select_banker()
    local real_uid_list_exclude_banker = self:real_uid_list_exclude_banker()
    local pos = math.random(1, #real_uid_list_exclude_banker)
    local uid = real_uid_list_exclude_banker[pos]
    self:update_banker(uid)
end

function root:update_banker(uid)
    local real_uid_list = self:real_uid_list()
    for k, tmp_uid in ipairs(real_uid_list) do
        local ok = self:banker(tmp_uid)
        if ok then
            self:set_state_banker(tmp_uid, false)
        end
    end
    self:set_state_banker(uid, true)
    
    self:swap_seat_to_last(uid)
end

function root:offline(uid)
    self:set_state_online(uid, false)
end

function root:online(uid)
    self:set_state_online(uid, true)
end

function root:ready(uid)
    self:set_state_ready(uid, true)
end

function root:user_amount()
    local real_uid_list = self:real_uid_list()
    return #real_uid_list
end

function root:push_message(uid, name, msg)
    local user_net = self:get_user_net(uid)
    if user_net then
        skynet.send(user_net.agent, "lua", "emit", user_net.fd, "s2c", name, msg)
    else
        logger.error("%s push_message not user_net, uid:%d", name, uid)
    end
end

function root:broadcast(name, msg, screen_uid)
    local real_uid_list = self:real_uid_list()
    for k, uid in ipairs(real_uid_list) do
        if screen_uid ~= uid then
            self:push_message(uid, name, msg)
        end
    end
end

return root