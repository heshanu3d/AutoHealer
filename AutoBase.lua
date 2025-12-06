
-- 获取第bag背包 的 第slot位置 的物品名
function GetInventoryItemName(bag, slot)
    local itemLink = GetContainerItemLink(bag, slot)
    if itemLink then
        return string.match(itemLink,".*%[(.*)%]")
    end

    -- print("没找到" .. bag .. "背包里的第" .. slot .. "个物品的名字")
    return ""
end

-- 获取第bag背包 的 第slot位置 的物品id
function GetInventoryItemID(bag, slot)
    local itemLink = GetContainerItemLink(bag, slot)
    if itemLink then
        local id = tonumber(string.match(itemLink,"item:(%d*):"))
        if id then
            return id
        end
        return -1
    end

    return -1
end

function UseInventoryItem(itemName)
    for bag = 0, 4 do
        for slog = 1, 28 do
            if GetInventoryItemName(bag, slog) == itemName then
                UseContainerItem(bag, slog)
            end
        end
    end
end

-- 交换第 src_a 背包里第 src_b 个物品 和 第 dst_bag 背包里第 dst_slot 个物品
function SwapItem(src_bag, src_slot, dst_bag, dst_slot)
    PickupContainerItem(src_bag, src_slot)
    PickupContainerItem(dst_bag, dst_slot)
end

-- 检查 tar 目标身上是否有buff
function HasBuff(tar, buff)
    local f = 0
    for i=1,16 do
        b = UnitBuff(tar, i)
        if b and strfind(b, buff) then
            f = 1
            break
        end
    end
    return f
end

-- 根据指定action编号技能是否能打到切换目标
-- ActionBar编号
-- 主动作条 1-12
-- 上方1动作条：61-72
-- 上方2动作条：49-60
-- 右上1动作条：37-48
-- 右上2动作条：25-36
function TabByAction(action_id)
    local a=IsActionInRange(action_id)
    if a~=1 then
        TargetNearestEnemy()
    end
end

function printAll(...)
	if arg.n == 0 then
		return
	elseif arg.n == 1 then
		print(tostring(arg[1]))
	else
        local result = ""
		for i = 1, arg.n do
            if arg[i] == nil then
                break
            end
            if i > 1 then
                result = result .. ", "
            end
            result = result .. tostring(arg[i])
		end
        print(result)
	end
end
mprint=printAll

-- Hook StaticPopup相关函数
local popupsSwitch = false
function HookStaticPopups()
    popupsSwitch = true
    -- Hook StaticPopup_Show 函数
    hooksecurefunc("StaticPopup_Show", function()
        -- self:CheckAndCancelDialog(dialog, ...)
        -- if StaticPopup1EditBox then
        --     print("StaticPopup1EditBox")
        -- end
        -- if StaticPopup1Button2 then
        --     print("StaticPopup1Button2")
        -- end
        -- local button1Text = StaticPopup1Button1:GetText()
        -- local button2Text = StaticPopup1Button2:GetText()
        -- local popupsText = StaticPopup1Text:GetText()
        -- local dialogsText = StaticPopupDialogs['LOOT_BIND']:GetText()
        -- print(button1Text)
        -- print(button2Text)
        -- print(popupsText)
        -- print(dialogsText)

        -- if popupsSwitch and StaticPopup1EditBox and StaticPopup1Button2 then
        --     StaticPopup1Button2:Click()
        -- end
        StaticPopup1Button2:Click()
    end)

    -- -- Hook StaticPopup_OnShow 函数
    -- for i = 1, 4 do
    --     local frame = _G["StaticPopup"..i]
    --     if frame then
    --         frame:HookScript("OnShow", function()
    --             -- AutoClickCancel:OnDialogShown(self)
    --             -- StaticPopup1Button2:Click()
    --         end)
    --     end
    -- end
end

function HookStaticPopupsSwitch()
    popupsSwitch = not popupsSwitch
end
