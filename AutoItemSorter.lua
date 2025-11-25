local sortTimer = CreateFrame("Frame") -- 解决N服端快速卖垃圾掉线的问题
sortTimer:Hide()
sortTimer.interval = TOOLTIP_UPDATE_TIME
sortTimer.cnt = 0
sortTimer.frame_cnt = 0
sortTimer.frame_rate = 12 -- 相当于 一秒触发 60/12 次

local allItems = {}
local itemCount = 0
local nonEmptyItemCount = 0
local targetPositions = {}
local sort_cnt = 1
local U = GetInventoryItemName
local S = SwapItem

function ClearTable(t)
    for k, v in pairs(t) do
        t[k] = nil
    end
end

-- 函数U(a,b) 介绍 a表示第a个背包，b表示背包里的第几个物品
-- 现在有4个背包，第1个背包有16个物品，后3个背包有28个物品，总共16+28*3=100个物品
-- 使用函数U(0,1)~U(0,16)获取第1~16个物品的名字，
-- 使用函数U(1,1)~U(1,28)获取第17~44个物品的名字，
-- 使用函数U(2,1)~U(2,28)获取第45~72个物品的名字，
-- 使用函数U(3,1)~U(3,28)获取第73~100个物品的名字，
-- 使用函数S(src_a,src_b,dst_a,dst_b)交换第src_a背包里第src_b个物品 和 第dst_a背包里第dst_b个物品 的位置
-- 要求使用lua语言 以上提供的函数U和S ，对背包里的物品进行排序
function SortItemsEfficient(frame_rate)
    sortTimer.frame_rate = frame_rate or 12
    sort_cnt = 1

    -- 收集所有物品信息
    -- allItems = {}
    ClearTable(allItems)
    itemCount = 0
    nonEmptyItemCount = 0
    -- local allItems = {}
    -- local itemCount = 0
    
    -- 获取所有物品
    for i = 1, 16 do
        itemCount = itemCount + 1
        local itemName = U(0, i)
        allItems[itemCount] = {
            name = itemName,
            backpack = 0,
            position = i,
            isEmpty = (itemName == "")
        }
        if itemName ~= "" then
            nonEmptyItemCount = nonEmptyItemCount + 1
        end
    end
    
    for backpack = 1, 3 do
        for i = 1, 28 do
            itemCount = itemCount + 1
            local itemName = U(backpack, i)
            allItems[itemCount] = {
                name = itemName,
                backpack = backpack,
                position = i,
                isEmpty = (itemName == "")
            }
            if itemName ~= "" then
                nonEmptyItemCount = nonEmptyItemCount + 1
            end
        end
    end
    
    -- 按物品名称排序，空物品放在最后
    table.sort(allItems, function(a, b)
        if a.isEmpty and not b.isEmpty then
            return false  -- a是空的，b不是，把a放后面
        elseif not a.isEmpty and b.isEmpty then
            return true   -- a不是空的，b是空的，把a放前面
        elseif a.isEmpty and b.isEmpty then
            return false  -- 两个都是空的，保持相对顺序
        else
            return a.name < b.name  -- 两个都不是空的，按名称排序
        end
    end)
    
    -- 创建目标位置映射
    targetPositions = {}
    -- local targetPositions = {}
    local index = 1
    
    -- 第一个背包的目标位置
    for pos = 1, 16 do
        targetPositions[index] = {backpack = 0, position = pos}
        index = index + 1
    end
    
    -- 后三个背包的目标位置
    for backpack = 1, 3 do
        for pos = 1, 28 do
            targetPositions[index] = {backpack = backpack, position = pos}
            index = index + 1
        end
    end

    print("start sort")
    sortTimer:Show()

    -- 执行排序交换
    -- for i = 1, itemCount do
    --     local currentItem = allItems[i]
    --     local targetPos = targetPositions[i]

    --     -- 检查当前位置是否应该是空的
    --     if currentItem.isEmpty then
    --         -- 如果目标位置有物品，需要移动到空位置
    --         local currentTargetItem = U(targetPos.backpack, targetPos.position)
    --         if currentTargetItem ~= "" then
    --             -- 找到下一个空位置来交换
    --             for j = i + 1, itemCount do
    --                 if allItems[j].isEmpty then
    --                     S(targetPos.backpack, targetPos.position, allItems[j].backpack, allItems[j].position)
    --                     break
    --                 end
    --             end
    --         end
    --     else
    --         -- 如果物品不在目标位置，进行交换
    --         if currentItem.backpack ~= targetPos.backpack or currentItem.position ~= targetPos.position then
    --             -- 执行交换
    --             S(currentItem.backpack, currentItem.position, targetPos.backpack, targetPos.position)

    --             -- 更新其他物品的位置信息
    --             for j = i + 1, itemCount do
    --                 if allItems[j].backpack == targetPos.backpack and allItems[j].position == targetPos.position then
    --                     allItems[j].backpack = currentItem.backpack
    --                     allItems[j].position = currentItem.position
    --                     break
    --                 end
    --             end
    --         end
    --     end
    -- end
end

local function SortInTimer()
    local i = sort_cnt
    print("sort " .. i)

    local currentItem = allItems[i]
    local targetPos = targetPositions[i]
    
    -- 检查当前位置是否应该是空的
    if currentItem.isEmpty then
        -- 如果目标位置有物品，需要移动到空位置
        local currentTargetItem = U(targetPos.backpack, targetPos.position)
        if currentTargetItem ~= "" then
            -- 找到下一个空位置来交换
            for j = i + 1, itemCount do
                if allItems[j].isEmpty then
                    S(targetPos.backpack, targetPos.position, allItems[j].backpack, allItems[j].position)
                    break
                end
            end
        end
    else
        -- 如果物品不在目标位置，进行交换
        if currentItem.backpack ~= targetPos.backpack or currentItem.position ~= targetPos.position then
            -- 执行交换
            S(currentItem.backpack, currentItem.position, targetPos.backpack, targetPos.position)
            
            -- 更新其他物品的位置信息
            for j = i + 1, itemCount do
                if allItems[j].backpack == targetPos.backpack and allItems[j].position == targetPos.position then
                    allItems[j].backpack = currentItem.backpack
                    allItems[j].position = currentItem.position
                    break
                end
            end
        end
    end

    sort_cnt = sort_cnt + 1
    -- if sort_cnt > itemCount then
    if sort_cnt > nonEmptyItemCount then
        sortTimer:Hide()
    end
end

sortTimer:SetScript("OnUpdate", function()
        this.sinceLast = (this.sinceLast or 0) + arg1
        if this.sinceLast > this.interval then
            this.cnt = (this.cnt or 0) + 1
            if this.cnt > this.frame_cnt * this.frame_rate then
                this.frame_cnt = this.frame_cnt + 1
                SortInTimer()
            end
        end
    end
)
