-- Sort live inventory, waiting for each swap to be acknowledged.
local driver = CreateFrame("Frame")
local groups, groupIndex, position, elapsed, waiting, pending, report
local interval = 0.3
local function Message(text)
    if report then report(text) end
    DEFAULT_CHAT_FRAME:AddMessage("|cff33aaffAutoHealer:|r " .. text)
end
function AutoItemSorter_Stop(silent)
    groups, pending = nil, nil
    driver:Hide()
    if not silent then Message("排序已停止。") end
end
local function Read(pos)
    local link = GetContainerItemLink(pos.bag, pos.slot)
    local _, count, locked = GetContainerItemInfo(pos.bag, pos.slot)
    local _, _, name = string.find(link or "", "%[(.-)%]")
    return {link = link, count = count, locked = locked, name = name}
end
local function Before(a, b)
    if not a.name then return false end
    return not b.name or a.name < b.name
end
local function Same(a, b)
    return a.link == b.link and a.count == b.count
end
local function AddBag(list, bag)
    for slot = 1, GetContainerNumSlots(bag) do
        table.insert(list, {bag = bag, slot = slot})
    end
end
local function Begin(newGroups, callback, delay)
    if UnitAffectingCombat("player") or CursorHasItem() then
        report = callback
        Message("请先脱离战斗，并放下鼠标上的物品。")
        return
    end
    AutoSeller_Stop(true)
    report = callback
    groups, groupIndex, position = newGroups, 1, 1
    elapsed, waiting, pending = 0, 0, nil
    interval = delay or 0.3
    Message("正在排序；点击停止可中止。")
    driver:Show()
end
function AutoItemSorter_StartBags(selected, callback)
    local lists = {}
    for bag = 0, 4 do
        if selected[bag] and GetContainerNumSlots(bag) > 0 then
            local list = {}
            AddBag(list, bag)
            table.insert(lists, list)
        end
    end
    if table.getn(lists) == 0 then
        report = callback
        Message("请先勾选至少一个已装备的背包。")
        return
    end
    Begin(lists, callback)
end
-- Preserve the existing macro's combined range behavior.
function SortItemsEfficient(frame_rate, bag_start, bag_end)
    bag_start, bag_end = bag_start or 0, bag_end or 0
    if bag_start < 0 or bag_end > 4 or bag_start > bag_end then return end
    local list = {}
    for bag = bag_start, bag_end do AddBag(list, bag) end
    Begin({list}, nil, math.max(0.3, (frame_rate or 12) / 60))
end
local function WaitOrStop()
    waiting = waiting + 1
    if waiting >= 10 then
        AutoItemSorter_Stop(true)
        Message("物品锁定或移动未完成，排序已停止，请稍后重试。")
    end
end
local function Tick()
    if UnitAffectingCombat("player") or CursorHasItem() then
        AutoItemSorter_Stop(true)
        Message("进入战斗或鼠标持有物品，排序已停止。")
        return
    end
    if pending then
        local src, dst = Read(pending.src), Read(pending.dst)
        if src.locked or dst.locked then WaitOrStop(); return end
        if not Same(src, pending.afterSrc) or not Same(dst, pending.afterDst) then
            WaitOrStop(); return
        end
        pending, waiting = nil, 0
    end
    local list = groups[groupIndex]
    if not list then
        AutoItemSorter_Stop(true)
        Message("背包排序完成。")
        return
    end
    if position > table.getn(list) then
        groupIndex, position = groupIndex + 1, 1
        return
    end
    local target = list[position]
    local current = Read(target)
    local best, bestItem = position, current
    for i = position, table.getn(list) do
        local item = Read(list[i])
        if item.locked then WaitOrStop(); return end
        if Before(item, bestItem) then best, bestItem = i, item end
    end
    if best == position then
        waiting, position = 0, position + 1
        return
    end
    local source = list[best]
    PickupContainerItem(source.bag, source.slot)
    if not CursorHasItem() then WaitOrStop(); return end
    PickupContainerItem(target.bag, target.slot)
    -- Return the displaced item to the source when swapping occupied slots.
    if CursorHasItem() then PickupContainerItem(source.bag, source.slot) end
    if CursorHasItem() then
        ClearCursor()
        AutoItemSorter_Stop(true)
        Message("无法交换物品，排序已停止。")
        return
    end
    waiting = 0
    pending = {src = source, dst = target, afterSrc = current, afterDst = bestItem}
end
 driver:SetScript("OnUpdate", function()
    if not groups then return end
    elapsed = elapsed + arg1
    if elapsed < interval then return end
    elapsed = 0
    Tick()
end)
driver:Hide()
