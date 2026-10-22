-- 为"亡灵魔兽20260920版本准备"
-- /wlloot：直接点击配置的固定按钮；找不到时回退完整流程，找到后仅打印一次真实名称。
-- /wlloot full：执行 WLLootClick_Now() 完整查找流程；/wlloot debug：诊断。
-- 宏函数：WLLootClick_Direct() 为快捷入口；WLLootClick_Now() 保留原有行为。

-- BEGIN WLLootClick: immediate-loot helper (manual invocation only)
do
-- WoW 1.12: one click per request; OnUpdate only waits briefly for the button.
local label = "立即拾取"
local pending = false
local elapsed = 0
local tick = 0
-- 类似 static：只在快捷入口回退后报告真实按钮名；重新登录或重载界面后重置。
local actualButtonReported = false
local reportActualButton = false
local driver = CreateFrame("Frame")
driver:Hide()

local function Say(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff80ffff[WLLootClick]|r " .. message)
end

local function Clean(text)
    if type(text) ~= "string" then return "" end
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    return string.gsub(text, "%s", "")
end

local function FindButton()
    local found = nil
    local count = 0
    local frame = EnumerateFrames()
    while frame do
        if frame.IsObjectType and frame:IsObjectType("Button")
            and frame.GetText and Clean(frame:GetText()) == label
            and frame:IsVisible() then
            found = frame
            count = count + 1
        end
        frame = EnumerateFrames(frame)
    end
    return found, count
end

local function FindSQ()
    for key, handler in pairs(SlashCmdList) do
        if type(handler) == "function" then
            local index = 1
            local alias = getglobal("SLASH_" .. key .. index)
            while alias do
                if string.lower(alias) == "/sq" then return handler, key end
                index = index + 1
                alias = getglobal("SLASH_" .. key .. index)
            end
        end
    end
end

local function Stop()
    pending = false
    driver:Hide()
end

-- Returns true when this attempt is finished, including safe refusal.
local function TryClick()
    local button, count = FindButton()
    if count > 1 then
        Stop()
        Say("发现多个可见的立即拾取按钮，为避免误点已停止。请关闭其他窗口后重试。")
        return true
    end
    if not button then return false end
    -- 仅在唯一按钮确实找到后打印，支持 /sq 延迟创建按钮的情况。
    if reportActualButton and not actualButtonReported then
        local name = button:GetName()
        if name then
            Say("实际拾取按钮名称：" .. name)
            actualButtonReported = true
            reportActualButton = false
        end
    end
    if button.IsEnabled then
        local enabled = button:IsEnabled()
        if not enabled or enabled == 0 then return false end
    end
    Stop() -- Stop BEFORE invoking the callback: at most one click per request.
    local ok, err = pcall(function() button:Click() end)
    if not ok then Say("按钮点击失败：" .. tostring(err)) end
    return true
end

function WLLootClick_Debug()
    local handler, key = FindSQ()
    local button, count = FindButton()
    Say("/sq 处理函数：" .. tostring(key or "未找到") .. "；可见同名按钮：" .. count)
    if button then Say("按钮名称：" .. tostring(button:GetName() or "匿名按钮")) end
end

function WLLootClick_Now()
    if pending then return end
    if type(EnumerateFrames) ~= "function" then
        Say("客户端不支持 EnumerateFrames，无法查找按钮。")
        return
    end
    if TryClick() then return end
    local handler = FindSQ()
    if not handler then
        Say("未找到 /sq 的插件处理函数。请先手动输入 /sq，再执行 /wlloot。")
        return
    end
    pending = true
    elapsed = 0
    tick = 0
    local ok, err = pcall(handler, "")
    if not ok then
        Stop()
        Say("打开 /sq 失败：" .. tostring(err))
        return
    end
    if TryClick() then return end
    driver:Show()
end

driver:SetScript("OnUpdate", function(self, delta)
    if not pending then return end
    -- Vanilla passes elapsed through global arg1; newer clients pass delta.
    local dt = delta or arg1 or 0
    elapsed = elapsed + dt
    tick = tick + dt
    if tick >= 0.1 then
        tick = 0
        if TryClick() then return end
    end
    if elapsed >= 3 then
        Stop()
        Say("未找到可点击的立即拾取按钮。请打开 /sq 后输入 /wlloot debug，并反馈输出。")
    end
end)

-- 固定按钮名称：版本变更时只修改此处，不自动匹配其他编号。
local directButtonName = "TurtleQuickLootFrame8Loot"

function WLLootClick_Direct()
    local button = getglobal(directButtonName)
    if button then
        -- 取消尚未完成的查找，避免直接点击后又被 OnUpdate 重复点击。
        Stop()
        local ok, err = pcall(function() button:Click() end)
        if not ok then Say("按钮点击失败：" .. tostring(err)) end
    else
        -- 此时还不知道真实名称；交给完整流程找到后再报告，不能打印旧配置充数。
        if not actualButtonReported then reportActualButton = true end
        WLLootClick_Now()
    end
end

SLASH_WLLOOTCLICK1 = "/wlloot"
SlashCmdList["WLLOOTCLICK"] = function(message)
    local command = string.lower(message or "")
    command = string.gsub(command, "^%s*(.-)%s*$", "%1")
    if command == "debug" then
        WLLootClick_Debug()
    elseif command == "full" then
        WLLootClick_Now()
    else
        WLLootClick_Direct()
    end
end
end
-- END WLLootClick
