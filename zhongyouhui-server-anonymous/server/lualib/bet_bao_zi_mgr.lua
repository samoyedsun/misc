local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"

local slot = {}
function slot:new(slot)
    local o = {
        slot = slot,
        amount = 0
    }
    setmetatable(o, {__index = self})
    return o
end

function slot:get_slot()
    return self.slot
end

function slot:get_amount()
    return self.amount
end

function slot:add_amount(amount)
    self.amount = self.amount + amount
end

function slot:reset()
    self.amount = 0
end

function slot:totable()
    return {
        slot = self:get_slot(),
        amount = self:get_amount()
    }
end

local root = {}

function root:init()
    self.uid_to_slot_obj_list = {}
end

function root:alloc(uid, bet_slot_list)
    local slot_obj_list = {}
    for k, v in ipairs(bet_slot_list) do
        table.insert(slot_obj_list, slot:new(v))
    end
    self.uid_to_slot_obj_list[uid] = slot_obj_list
end

function root:get_slot_obj_list(uid)
    return self.uid_to_slot_obj_list[uid]
end

function root:get_slot_obj(uid, slot)
    local slot_obj_list = self:get_slot_obj_list(uid)
    for k, slot_obj in ipairs(slot_obj_list) do
        local tmp_slot = slot_obj:get_slot()
        if tmp_slot == slot then
            return slot_obj
        end
    end
end

function root:update(uid, slot, amount)
    local slot_obj = self:get_slot_obj(uid, slot) 
    slot_obj:add_amount(amount)
end

function root:reset(uid)
    local slot_obj_list = self:get_slot_obj_list(uid)
    for k, slot_obj in ipairs(slot_obj_list) do
        slot_obj:reset()
    end
end

function root:release(uid)
    self.uid_to_slot_obj_list[uid] = nil
end

function root:empty(uid)
    local slot_obj_list = self:get_slot_obj_list(uid)
    for k, slot_obj in ipairs(slot_obj_list) do
        local amount = slot_obj:get_amount()
        if amount > 0 then
            return false
        end
    end
    return true
end

function root:totable()
    local bet_info_list = {}
    for uid, slot_obj_list in pairs(self.uid_to_slot_obj_list) do
        local slot_info_list = {}
        for k, slot_obj in ipairs(slot_obj_list) do
            table.insert(slot_info_list , slot_obj:totable())
        end
        table.insert(bet_info_list, {
            uid = uid,
            slot_info_list = slot_info_list
        })
    end
    return bet_info_list
end

function root:get_bet_slot_detail_list(uid)
    local slot_obj_list = self:get_slot_obj_list(uid)
    local results = {}
    for k, slot_obj in ipairs(slot_obj_list) do
        local slot = slot_obj:get_slot()
        local amount = slot_obj:get_amount()
        if amount > 0 then
            table.insert(results, {
                slot_list = {slot},
                amount = amount
            })
        end
    end
    return results
end

function root:get_bet_slot_chip_amount(uid, slot)
    local bet_slot_chip_amount = 0
    --将单个人改为所有人.
    --local slot_obj_list = self:get_slot_obj_list(uid)
    for uid, slot_obj_list in pairs(self.uid_to_slot_obj_list) do
        for k, slot_obj in ipairs(slot_obj_list) do
            local tmp_slot = slot_obj:get_slot()
            if tmp_slot == slot then
                local amount = slot_obj:get_amount()
                bet_slot_chip_amount = bet_slot_chip_amount + amount
            end
        end
    end
    return bet_slot_chip_amount
end

function root:round_settlement(uid, open_bet_slot_list, game_type)
    local banker_win_amount = 0
    local self_win_amount = 0
    local return_self_amount = 0
    local give_banker_amount = 0
    
    local slot_obj_list = self:get_slot_obj_list(uid)
    for k, slot_obj in ipairs(slot_obj_list) do
        local amount = slot_obj:get_amount()
        local slot = slot_obj:get_slot()
        if amount > 0 and game_type == common_conf.GAME_TYPE_YU_XIA_XIE then
            if open_bet_slot_list[1] == slot and
                open_bet_slot_list[2] == slot then
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_BAO_ZI_25
                local win_amount = amount * win_multiple
                banker_win_amount = banker_win_amount - win_amount
                self_win_amount = self_win_amount + win_amount
                return_self_amount = return_self_amount + amount
            else
                banker_win_amount = banker_win_amount + amount
                give_banker_amount = give_banker_amount + amount
            end
        end
        if amount > 0 and game_type == common_conf.GAME_TYPE_TONG_QIAN_JI then
            if open_bet_slot_list[1] == slot and
                open_bet_slot_list[2] == slot and
                open_bet_slot_list[3] == slot then
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_BAO_ZI_150
                local win_amount = amount * win_multiple
                banker_win_amount = banker_win_amount - win_amount
                self_win_amount = self_win_amount + win_amount
                return_self_amount = return_self_amount + amount
            else
                banker_win_amount = banker_win_amount + amount
                give_banker_amount = give_banker_amount + amount
            end
        end
    end

    return {
        banker_win_amount = banker_win_amount,
        self_win_amount = self_win_amount,
        return_self_amount = return_self_amount,
        give_banker_amount = give_banker_amount
    }
end

return root
