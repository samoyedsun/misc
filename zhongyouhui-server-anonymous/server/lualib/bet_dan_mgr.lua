local shake_dice_conf = require "server.config.shake_dice_conf"
local common_conf = require "server.config.common_conf"

local chip = {}
function chip:new(chip_type)
    local o = {
        chip_type = chip_type,
        amount = 0
    }
    setmetatable(o, {__index = self})
    return o
end

function chip:incr_amount()
    self.amount = self.amount + 1
end

function chip:get_amount()
    return self.amount
end

function chip:reset()
    self.amount = 0
end

function chip:get_chip_type()
    return self.chip_type
end

function chip:totable()
    return {
        chip_type = self:get_chip_type(),
        amount = self:get_amount()
    }
end

local slot = {}
function slot:new(slot)
    local chip_obj_list = {}
    table.insert(chip_obj_list, chip:new(shake_dice_conf.CHIP_TYPE_ONE))
    table.insert(chip_obj_list, chip:new(shake_dice_conf.CHIP_TYPE_TWO))
    table.insert(chip_obj_list, chip:new(shake_dice_conf.CHIP_TYPE_THREE))
    table.insert(chip_obj_list, chip:new(shake_dice_conf.CHIP_TYPE_FOUR))
    table.insert(chip_obj_list, chip:new(shake_dice_conf.CHIP_TYPE_FIVE))
    local o = {
        slot = slot,
        chip_obj_list = chip_obj_list
    }
    setmetatable(o, {__index = self})
    return o
end

function slot:get_slot()
    return self.slot
end

function slot:get_chip_obj_list()
    return self.chip_obj_list
end

function slot:get_chip_list()
    local chip_obj_list = self:get_chip_obj_list()
    local chip_list = {}
    for k, chip_obj in ipairs(chip_obj_list) do
        table.insert(chip_list, chip_obj:totable())
    end
    return chip_list
end

function slot:get_chip_obj(chip_type)
    local chip_obj_list = self:get_chip_obj_list()
    for k, chip_obj in ipairs(chip_obj_list) do
        if chip_obj:get_chip_type() == chip_type then
            return chip_obj
        end
    end
end

function slot:totable()
    return {
        slot = self:get_slot(),
        chip_list = self:get_chip_list()
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

function root:update(uid, slot, chip_type)
    local slot_obj = self:get_slot_obj(uid, slot)
    local chip_obj = slot_obj:get_chip_obj(chip_type)
    chip_obj:incr_amount()
end

function root:reset(uid)
    local slot_obj_list = self:get_slot_obj_list(uid)
    for k, slot_obj in ipairs(slot_obj_list) do
        local chip_obj_list = slot_obj:get_chip_obj_list()
        for k, chip_obj in ipairs(chip_obj_list) do
            local amount = chip_obj:get_amount()
            if amount > 0 then
                chip_obj:reset()
            end
        end
    end
end

function root:release(uid)
    self.uid_to_slot_obj_list[uid] = nil
end

function root:get_bet_total_amount(uid)
    local total_amount = 0
    local slot_obj_list = self:get_slot_obj_list(uid)
    for k, slot_obj in ipairs(slot_obj_list) do
        local chip_obj_list = slot_obj:get_chip_obj_list()
        for k, chip_obj in ipairs(chip_obj_list) do
            local amount = chip_obj:get_amount()
            local real_amount = amount * chip_obj:get_chip_type()
            total_amount = total_amount + real_amount
        end
    end
    return total_amount
end

function root:empty(uid)
    local slot_obj_list = self:get_slot_obj_list(uid)
    for k, slot_obj in ipairs(slot_obj_list) do
        local chip_obj_list = slot_obj:get_chip_obj_list()
        for k, chip_obj in ipairs(chip_obj_list) do
            local amount = chip_obj:get_amount()
            if amount > 0 then
                return false
            end
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

function root:calc_bet_slot_info(uid)
    local append_bet_slot_chip_total_list = function(bet_slot_chip_total_list, chip_info)
        for k, bet_slot_chip_total in ipairs(bet_slot_chip_total_list) do
            if bet_slot_chip_total.chip_type == chip_info.chip_type then
                bet_slot_chip_total.amount = bet_slot_chip_total.amount + chip_info.amount
                return true
            end
        end
        table.insert(bet_slot_chip_total_list, chip_info)
    end

    local results = {}
    for tmp_uid, slot_obj_list in pairs(self.uid_to_slot_obj_list) do
        for k, slot_obj in ipairs(slot_obj_list) do
            local slot = slot_obj:get_slot()
            local info = results[slot] or {}
            local bet_slot_chip_amount = info.bet_slot_chip_amount or 0
            local bet_slot_chip_total_amount = info.bet_slot_chip_total_amount or 0
            local bet_slot_chip_total_list = info.bet_slot_chip_total_list or {}
            local chip_obj_list = slot_obj:get_chip_obj_list()
            for k, chip_obj in ipairs(chip_obj_list) do
                local amount = chip_obj:get_amount()
                local amount = amount * chip_obj:get_chip_type()
                if tmp_uid == uid then
                    bet_slot_chip_amount = bet_slot_chip_amount + amount
                end
                bet_slot_chip_total_amount = bet_slot_chip_total_amount + amount
                append_bet_slot_chip_total_list(bet_slot_chip_total_list, chip_obj:totable())
            end
            info.bet_slot_chip_amount = bet_slot_chip_amount
            info.bet_slot_chip_total_amount = bet_slot_chip_total_amount
            info.bet_slot_chip_total_list = bet_slot_chip_total_list
            results[slot] = info
        end
    end

    return results
end

function root:get_bet_slot_detail_list(uid)
    local bet_slot_info_list = self:calc_bet_slot_info(uid)
    local results = {}
    for slot, info in pairs(bet_slot_info_list) do
        local amount = info.bet_slot_chip_amount
        if amount > 0 then
            table.insert(results, {
                slot_list = {slot},
                amount = amount
            })
        end
    end
    return results
end

function root:get_bet_slot_info_list(uid)
    local bet_slot_info_list = self:calc_bet_slot_info(uid)
    local results = {}
    for slot, info in pairs(bet_slot_info_list) do
        table.insert(results, {
            bet_slot = slot,
            bet_slot_chip_amount = info.bet_slot_chip_amount,
            bet_slot_chip_total_amount = info.bet_slot_chip_total_amount,
            bet_slot_chip_total_list = info.bet_slot_chip_total_list
        })
    end
    return results
end

function root:get_bet_slot_chip_total_amount(slot)
    local bet_slot_chip_total_amount = 0
    for k, slot_obj_list in pairs(self.uid_to_slot_obj_list) do
        for k, slot_obj in ipairs(slot_obj_list) do
            if slot_obj:get_slot() == slot then
                local chip_obj_list = slot_obj:get_chip_obj_list()
                for k, chip_obj in ipairs(chip_obj_list) do
                    local amount = chip_obj:get_amount()
                    local amount = amount * chip_obj:get_chip_type()
                    bet_slot_chip_total_amount = bet_slot_chip_total_amount + amount
                end
            end
        end
    end
    return bet_slot_chip_total_amount
end

function root:round_settlement(uid, open_bet_slot_list, game_type)
    local banker_win_amount = 0
    local self_win_amount = 0
    local return_self_amount = 0
    local give_banker_amount = 0

    local slot_obj_list = self:get_slot_obj_list(uid)
    for k, slot_obj in ipairs(slot_obj_list) do
        local slot = slot_obj:get_slot()
        local chip_obj_list = slot_obj:get_chip_obj_list()
        local amount = 0
        for k, chip_obj in ipairs(chip_obj_list) do
            local tmp_amount = chip_obj:get_amount()
            local tmp_amount = tmp_amount * chip_obj:get_chip_type()
            if tmp_amount > 0 then
                amount = amount + tmp_amount
            end
        end
        if amount > 0 and game_type == common_conf.GAME_TYPE_YU_XIA_XIE then
            if open_bet_slot_list[1] == slot and
                open_bet_slot_list[2] == slot then
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_DAN_OPEN_FOUR
                local win_amount = amount * win_multiple
                banker_win_amount = banker_win_amount - win_amount
                self_win_amount = self_win_amount + win_amount
                return_self_amount = return_self_amount + amount
            elseif open_bet_slot_list[1] == slot or
                open_bet_slot_list[2] == slot then
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_DAN_OPEN_TWO
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
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_DAN_OPEN_THREE
                local win_amount = amount * win_multiple
                banker_win_amount = banker_win_amount - win_amount
                self_win_amount = self_win_amount + win_amount
                return_self_amount = return_self_amount + amount
            elseif (open_bet_slot_list[1] == slot and open_bet_slot_list[2] == slot) or
                (open_bet_slot_list[1] == slot and open_bet_slot_list[3] == slot) or
                (open_bet_slot_list[2] == slot and open_bet_slot_list[3] == slot) then
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_DAN_OPEN_TWO
                local win_amount = amount * win_multiple
                banker_win_amount = banker_win_amount - win_amount
                self_win_amount = self_win_amount + win_amount
                return_self_amount = return_self_amount + amount
            elseif open_bet_slot_list[1] == slot or
                open_bet_slot_list[2] == slot or
                open_bet_slot_list[3] == slot then
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_DAN_OPEN_ONE
                local win_amount = amount * win_multiple
                banker_win_amount = banker_win_amount - win_amount
                self_win_amount = self_win_amount + win_amount
                return_self_amount = return_self_amount + amount
            else
                banker_win_amount = banker_win_amount + amount
                give_banker_amount = give_banker_amount + amount
            end
        end
        if amount > 0 and game_type == common_conf.GAME_TYPE_SHI_ER_SHENG_XIAO then
            if (open_bet_slot_list[1] == slot and open_bet_slot_list[2] == slot) or
                (open_bet_slot_list[3] == slot and open_bet_slot_list[4] == slot) then
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_DAN_OPEN_THREE
                local win_amount = amount * win_multiple
                banker_win_amount = banker_win_amount - win_amount
                self_win_amount = self_win_amount + win_amount
                return_self_amount = return_self_amount + amount
            elseif (open_bet_slot_list[1] == slot or open_bet_slot_list[2] == slot) or
                (open_bet_slot_list[3] == slot or open_bet_slot_list[4] == slot) then
                local win_multiple = shake_dice_conf.WIN_MULTIPLE_DAN_OPEN_TWO
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