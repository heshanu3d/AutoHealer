
-- --------------------------------------------------FastSellItem
local merchant_state = false
local AutoFastSell_bag_start = -1
local AutoFastSell_bag_end = -1
local AutoFastSell_itemNames = {}

-- 在sellTimer中调用，可以通过设置 sellTimer.frame_rate 的值大小 来改变售卖频率，每次只售卖一件物品，防止售卖太快掉线...
function AutoFastSell_ByNames()
    if AutoFastSell_bag_start == -1 or AutoFastSell_bag_end == -1 then
        return
    end

    for bag = AutoFastSell_bag_start, AutoFastSell_bag_end do
        for slot = 1, 28 do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local itemName = string.match(itemLink,".*%[(.*)%]")
                for i, specifiedItemName in ipairs(AutoFastSell_itemNames) do
                    if itemName == specifiedItemName then
                        -- print(itemName .. " in " .. bag .. " - " .. slot)
                        UseContainerItem(bag, slot)
                        return
                    end
                end
            end
        end
    end
end

-- FastSellItem
function FSI(bag, slot_start, slot_end)
    for i = slot_start, slot_end do
        UseContainerItem(bag, i)
    end
end

-- FastSellItemByName
function FSIBN(bag_start, bag_end, itemNames)
    AutoFastSell_bag_start = bag_start
    AutoFastSell_bag_end = bag_end
    AutoFastSell_itemNames = itemNames
end

-- 指定背包，售卖一切
local SellAnything_flag = false
local AutoFastSell_Anything_bag_start = -1
local AutoFastSell_Anything_bag_end = -1
function AutoFastSell_AnyThing()
    if AutoFastSell_Anything_bag_start == -1 or AutoFastSell_Anything_bag_end == -1 then
        return
    end
    for bag = AutoFastSell_Anything_bag_start, AutoFastSell_Anything_bag_end do
        for slot = 1, 28 do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                UseContainerItem(bag, slot)
                return
            end
        end
    end
    -- 卖完了，停止
    SellAnything_flag = false
end
function FSIBN_Anything(bag_start, bag_end)
    if not merchant_state then
        return
    end
    AutoFastSell_Anything_bag_start = bag_start
    AutoFastSell_Anything_bag_end = bag_end
    SellAnything_flag = true
end

local FastBuy_flag = false
local FastBuy_slot = -1
local AutoFastBuy_bag_start = -1
local AutoFastBuy_bag_end = -1
function AutoFastBuy()
    local slot_max = 16
    for bag = AutoFastBuy_bag_start, AutoFastBuy_bag_end do
        if bag > 0 then
            slot_max = 28
        end 
        for slot = 1, slot_max do
            local itemLink = GetContainerItemLink(bag, slot)
            if not itemLink then
                BuyMerchantItem(FastBuy_slot)
                return
            end
        end
    end
    -- 买完了，停止
    FastBuy_flag = false
end
function FastBuy(bag_start, bag_end, buy_slot)
    if not merchant_state then
        return
    end
    FastBuy_slot = buy_slot
    AutoFastBuy_bag_start = bag_start
    AutoFastBuy_bag_end = bag_end
    FastBuy_flag = true
end

local sellTimer = CreateFrame("Frame") -- 解决N服端快速卖垃圾掉线的问题
sellTimer:Hide()
sellTimer.interval = TOOLTIP_UPDATE_TIME
sellTimer.cnt = 0
sellTimer.frame_cnt = 0
sellTimer.frame_rate = 10 -- 相当于 一秒触发 60/10 次
sellTimer:SetScript("OnUpdate", function()
        this.sinceLast = (this.sinceLast or 0) + arg1
        if this.sinceLast > this.interval then
            this.cnt = (this.cnt or 0) + 1
            if this.cnt > this.frame_cnt * this.frame_rate then
                this.frame_cnt = this.frame_cnt + 1
                -- print(this.frame_cnt)
                AutoFastSell_ByNames()
                if SellAnything_flag then
                    AutoFastSell_AnyThing()
                end
                if FastBuy_flag then
                    AutoFastBuy()
                end
            end
        end
    end
)

local sellSwitcher = CreateFrame("Frame")
sellSwitcher:RegisterEvent("MERCHANT_SHOW")
sellSwitcher:RegisterEvent("MERCHANT_CLOSED")
sellSwitcher:SetScript("OnEvent", function()
        if event == "MERCHANT_SHOW" then
            sellTimer:Show()
            merchant_state = true
            -- print("MERCHANT_SHOW")
        elseif event == "MERCHANT_CLOSED" then
            sellTimer:Hide()
            merchant_state = false
            SellAnything_flag = false
            FastBuy_flag = false
            -- print("MERCHANT_CLOSED")
        end
    end
)
-----------------------------------------------------FastSellItem

-- function AutoFilterHighAttrEquipment(bag_end)
--     bag_end = bag_end or 3
--     for bag = 0, bag_end do
--         for slot = 1, 28 do
--             local itemLink = GetContainerItemLink(bag, slot)
--             if itemLink then
--                 UseContainerItem(bag, slot)
--                 return
--             end
--         end
--     end
-- end