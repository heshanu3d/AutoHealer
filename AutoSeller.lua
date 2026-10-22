-- Vanilla-compatible seller controls. No sale starts merely by opening a merchant.
local merchantOpen = false
local queue, queueIndex, elapsed = nil, 1, 0
local pending, pendingTicks = nil, 0
local buyRequest = nil
local window, nameBox, statusText
local checks = {}
local loadingForm = false
local legacyNames = nil
local confirmUntil = 0
local function Message(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33aaffAutoSeller:|r " .. text)
end
local function Settings()
    AutoHealerDB = AutoHealerDB or {}
    AutoHealerDB.seller = AutoHealerDB.seller or {}
    local db = AutoHealerDB.seller
    if type(db.bags) ~= "table" then db.bags = {} end
    if type(db.names) ~= "string" then db.names = "" end
    return db
end
local function Status(text)
    if statusText then statusText:SetText(text) end
end
local function Names(text)
    local result = {}
    -- Each line (or comma/semicolon separated entry) is an exact item name.
    text = string.gsub(text or "", "，", ",")
    text = string.gsub(text, "；", ";")
    for entry in string.gfind(text, "[^\r\n,;]+") do
        entry = string.gsub(entry, "^%s*(.-)%s*$", "%1")
        if entry ~= "" then result[entry] = true end
    end
    return result
end
local function ItemName(link)
    local _, _, name = string.find(link or "", "%[(.-)%]")
    return name
end
local function SaveForm()
    local db = Settings()
    if nameBox then db.names = nameBox:GetText() or "" end
    confirmUntil = 0
    return db
end
function AutoSeller_Stop(silent)
    if AutoItemSorter_Stop then AutoItemSorter_Stop(true) end
    queue, pending, buyRequest = nil, nil, nil
    queueIndex, pendingTicks, elapsed = 1, 0, 0
    confirmUntil = 0
    Status("已停止")
    if not silent then Message("已停止售卖/购买/排序。") end
end
local function HasBags(db)
    for bag = 0, 4 do if db.bags[bag] then return true end end
    return false
end
local function StartSale(mode, firstBag, lastBag, filter, firstSlot, lastSlot)
    local db = Settings()
    if not merchantOpen then Message("请先打开商人的交易窗口。"); return end
    if not HasBags(db) then Message("请先在设置中勾选要售卖的背包。"); return end
    filter = filter or Names(db.names)
    if mode == "names" and not next(filter) then
        Message("请先填写要售卖的物品全名，每行一个。"); return
    end
    AutoSeller_Stop(true)
    queue = {}
    for bag = 0, 4 do
        if db.bags[bag] and (not firstBag or (bag >= firstBag and bag <= lastBag)) then
            for slot = 1, GetContainerNumSlots(bag) do
                if (not firstSlot or (slot >= firstSlot and slot <= lastSlot)) then
                    local link = GetContainerItemLink(bag, slot)
                    local name = ItemName(link)
                    if link and (mode == "bags" or filter[name]) then
                        local _, count = GetContainerItemInfo(bag, slot)
                        table.insert(queue, {bag = bag, slot = slot, link = link, count = count})
                    end
                end
            end
        end
    end
    if table.getn(queue) == 0 then
        queue = nil
        Status("没有符合条件的物品")
        Message("勾选背包中没有符合条件的物品。")
        return
    end
    Status("售卖中（每 0.3 秒最多一组）")
    Message("开始售卖，共 " .. table.getn(queue) .. " 组候选物品；关闭商人或点击停止可中止。")
end
local function FinishEntry()
    queueIndex = queueIndex + 1
    pending, pendingTicks = nil, 0
end
local function TickSale()
    if not queue or not merchantOpen then return end
    local item = queue[queueIndex]
    if not item then
        queue = nil
        Status("处理完成（无法售卖的物品会跳过）")
        Message("本次售卖处理完成。")
        return
    end
    local db = Settings()
    local link = GetContainerItemLink(item.bag, item.slot)
    local _, count, locked = GetContainerItemInfo(item.bag, item.slot)
    -- Do not sell a different item or changed stack that moved into this slot.
    if not db.bags[item.bag] or link ~= item.link or count ~= item.count then
        FinishEntry(); return
    end
    if pending then
        pendingTicks = pendingTicks + 1
        if pendingTicks >= 5 then
            Message("跳过未能售出的物品：" .. (ItemName(link) or link))
            FinishEntry()
        end
        return
    end
    if locked then
        pendingTicks = pendingTicks + 1
        if pendingTicks >= 5 then FinishEntry() end
        return
    end
    -- Send once, then wait for inventory acknowledgement. Never loop on unsellable items.
    pending, pendingTicks = true, 0
    UseContainerItem(item.bag, item.slot)
end
-- Existing macro entry points are retained; all selling honors the selected bags.
function FSI(bag, slot_start, slot_end)
    if type(bag) ~= "number" or type(slot_start) ~= "number" or type(slot_end) ~= "number" then return end
    StartSale("bags", bag, bag, nil, slot_start, slot_end)
end
function FSIBN(bag_start, bag_end, itemNames)
    if type(bag_start) ~= "number" or type(bag_end) ~= "number" or type(itemNames) ~= "table" then return end
    local filter = {}
    for _, name in ipairs(itemNames) do filter[name] = true end
    legacyNames = { first = bag_start, last = bag_end, filter = filter }
    if merchantOpen then StartSale("names", bag_start, bag_end, filter) end
end
function FSIBN_Anything(bag_start, bag_end)
    if type(bag_start) ~= "number" or type(bag_end) ~= "number" then return end
    StartSale("bags", bag_start, bag_end)
end
function AutoFastSell_ByNames() TickSale() end
function AutoFastSell_AnyThing() TickSale() end
-- Preserve the existing buying macro, with a real time interval and actual bag sizes.
function FastBuy(bag_start, bag_end, buy_slot)
    if not merchantOpen then return end
    if type(bag_start) ~= "number" or type(bag_end) ~= "number" or type(buy_slot) ~= "number" then return end
    AutoSeller_Stop(true)
    buyRequest = { first = math.max(0, bag_start), last = math.min(4, bag_end), slot = buy_slot }
end
function AutoFastBuy()
    if not merchantOpen or not buyRequest then return end
    for bag = buyRequest.first, buyRequest.last do
        for slot = 1, GetContainerNumSlots(bag) do
            if not GetContainerItemLink(bag, slot) then
                BuyMerchantItem(buyRequest.slot)
                return
            end
        end
    end
    buyRequest = nil
end
local function Label(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end
local function Button(parent, text, x, y, width, action)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width); button:SetHeight(26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", action)
    return button
end
local function CreateWindow()
    if window then return end
    window = CreateFrame("Frame", "AutoHealerSellerWindow", UIParent)
    window:SetWidth(470); window:SetHeight(510)
    window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true); window:EnableMouse(true)
    if window.SetClampedToScreen then window:SetClampedToScreen(true) end
    window:RegisterForDrag("RightButton")
    window:SetScript("OnDragStart", function() this:StartMoving() end)
    window:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    window:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=32, edgeSize=24, insets={left=6,right=6,top=6,bottom=6}})
    window:SetBackdropColor(0, 0, 0, 1)
    Label(window, "AutoHealer - 自动助手设置", 22, -22)
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() window:Hide() end)
    Label(window, "选择售卖/排序背包（背包1 = 自带行囊；2~5 = 装备背包）", 22, -58)
    for bag = 0, 4 do
        local check = CreateFrame("CheckButton", "AutoSellerBag" .. bag, window, "UICheckButtonTemplate")
        check:SetWidth(26); check:SetHeight(26)
        check:SetPoint("TOPLEFT", window, "TOPLEFT", 22 + bag * 86, -82)
        check.bag = bag
        getglobal("AutoSellerBag" .. bag .. "Text"):SetText("背包" .. (bag + 1))
        check:SetScript("OnClick", function()
            AutoSeller_Stop(true)
            Settings().bags[this.bag] = this:GetChecked() and true or false
            Status("背包选择已保存")
        end)
        checks[bag] = check
    end
    Label(window, "按名称售卖：每行一个物品全名（精确匹配）", 22, -122)
    Button(window, "编辑名单", 354, -116, 92, function()
        nameBox:SetFocus()
        Status("正在编辑物品名称：每行一个全名，回车换行，Esc结束。")
    end)
    Label(window, "也支持逗号或分号分隔；仅在勾选的背包中查找。", 22, -144)
    local border = CreateFrame("Frame", nil, window)
    border:SetPoint("TOPLEFT", window, "TOPLEFT", 22, -172)
    border:SetWidth(424); border:SetHeight(170)
    border:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    border:SetBackdropColor(0,0,0,0.8)
    local scroll = CreateFrame("ScrollFrame", "AutoSellerNamesScroll", border, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", border, "TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -30, 8)
    nameBox = CreateFrame("EditBox", "AutoSellerNamesEdit", scroll)
    nameBox:SetWidth(378); nameBox:SetHeight(154)
    nameBox:SetMultiLine(true); nameBox:SetAutoFocus(false)
    nameBox:SetFontObject(GameFontHighlightSmall)
    nameBox:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    nameBox:EnableMouse(true)
    nameBox:EnableKeyboard(true)
    nameBox:SetTextInsets(4, 4, 4, 4)
    local function FocusNames()
        nameBox:SetFocus()
        Status("正在编辑物品名称：每行一个全名，回车换行，Esc结束。")
    end
    -- Explicitly focus the edit box, including clicks in the blank viewport.
    nameBox:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then FocusNames() end
    end)
    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then FocusNames() end
    end)
    border:EnableMouse(true)
    border:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then FocusNames() end
    end)
    nameBox:SetScript("OnEnterPressed", function() this:Insert("\n") end)
    nameBox:SetMaxLetters(12000)
    nameBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        Status("物品名单已保存")
    end)
    nameBox:SetScript("OnTextChanged", function()
        Settings().names = this:GetText() or ""
        confirmUntil = 0
        if queue and not loadingForm then AutoSeller_Stop(true); Status("名单已修改，售卖已停止") end
        scroll:UpdateScrollChildRect()
    end)
    nameBox:SetScript("OnCursorChanged", function(x, y, width, height)
        -- Vanilla passes cursor coordinates as script arguments.
        y = y or arg2
        height = height or arg4
        if not y or not height then return end
        local offset = scroll:GetVerticalScroll()
        local top = -y
        if top < offset then scroll:SetVerticalScroll(top)
        elseif top + height > offset + scroll:GetHeight() then
            scroll:SetVerticalScroll(top + height - scroll:GetHeight())
        end
    end)
    scroll:SetScrollChild(nameBox)
    Button(window, "按背包售卖", 22, -356, 132, function()
        if not merchantOpen then Message("请先打开商人的交易窗口。"); return end
        if not HasBags(Settings()) then Message("请先勾选背包。"); return end
        if confirmUntil == 0 or GetTime() > confirmUntil then
            confirmUntil = GetTime() + 5
            Status("警告：出售勾选背包中所有可售物品！5秒内再点确认。")
            return
        end
        SaveForm()
        StartSale("bags")
    end)
    Button(window, "按名称售卖", 164, -356, 132, function()
        SaveForm(); StartSale("names")
    end)
    Button(window, "停止", 306, -356, 66, function() AutoSeller_Stop() end)
    Button(window, "保存", 380, -356, 66, function()
        SaveForm(); nameBox:ClearFocus(); Message("设置已保存。")
    end)
    Button(window, "按背包排序", 22, -394, 132, function()
        SaveForm()
        AutoItemSorter_StartBags(Settings().bags, Status)
    end)
    Label(window, "各包内按名称排序，空格放末尾。", 164, -401)
    statusText = Label(window, "请选择背包；售卖需要先打开商人。", 22, -445)
    statusText:SetWidth(426); statusText:SetJustifyH("LEFT")
    Label(window, "设置自动保存 | 右键拖动窗口 | /autoseller 打开", 22, -481)
    window:SetScript("OnHide", function() nameBox:ClearFocus(); confirmUntil = 0 end)
    table.insert(UISpecialFrames, "AutoHealerSellerWindow")
    window:Hide()
end
function AutoSeller_ToggleWindow()
    CreateWindow()
    if window:IsShown() then window:Hide(); return end
    local db = Settings()
    for bag = 0, 4 do checks[bag]:SetChecked(db.bags[bag] and true or false) end
    loadingForm = true
    nameBox:SetText(db.names)
    loadingForm = false
    window:Show()
end
SLASH_AUTOHEALERSELLER1 = "/autoseller"
SLASH_AUTOHEALERSELLER2 = "/ahsell"
SlashCmdList["AUTOHEALERSELLER"] = function() AutoSeller_ToggleWindow() end
local driver = CreateFrame("Frame")
driver:RegisterEvent("VARIABLES_LOADED")
driver:RegisterEvent("MERCHANT_SHOW")
driver:RegisterEvent("MERCHANT_CLOSED")
driver:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        Settings()
    elseif event == "MERCHANT_SHOW" then
        merchantOpen = true
        elapsed = 0
        Status("商人已打开，请选择售卖方式。")
        if legacyNames then
            local request = legacyNames
            legacyNames = nil
            StartSale("names", request.first, request.last, request.filter)
        end
    elseif event == "MERCHANT_CLOSED" then
        merchantOpen = false
        AutoSeller_Stop(true)
        Status("商人已关闭，售卖已停止。")
    end
end)
driver:SetScript("OnUpdate", function()
    if not merchantOpen or (not queue and not buyRequest) then return end
    elapsed = elapsed + arg1
    if elapsed < 0.3 then return end
    elapsed = 0
    if queue then TickSale() elseif buyRequest then AutoFastBuy() end
end)
