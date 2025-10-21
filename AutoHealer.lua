-- local addonName, addonTable = ...
local healThreshold = 0.7  -- 默认70%血量阈值
-- local healThreshold = 0.99  -- 默认70%血量阈值
local healingSpellName = nil
local g_enable = 1

local classSpells = {
    ["PALADIN"] = {name = "圣光术", id = 635},
    ["PRIEST"] = {name = "治疗术", id = 2054},
    ["DRUID"] = {name = "治疗之触", id = 5185},
    ["SHAMAN"] = {name = "治疗波", id = 331}
}

local classBuffs = {
    ["PALADIN"] = {ad="力量祝福", ap="智慧祝福"},
    -- ["PRIEST"] = {ad = ""},
    -- ["DRUID"] = {ad = ""},
    -- ["SHAMAN"] = {ad = ""}
}

-- /run function print(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end;
-- /run for i=1,4 do local A=UnitBuff("player",i);if A then print(i.."="..A) end end
local classRegexs = {
    ["PALADIN"] = {ad="FistOfJustice$", ap="SealOfWisdom$"},
}

local classType = {
    ["PALADIN"]="ap",
    ["ROGUE"]="ad",
    ["PRIEST"]="ap",
    ["WARRIOR"]="ad",
}
local _, playerClass = UnitClass("player")
local buffs = classBuffs[playerClass]
local regexs = classRegexs[playerClass]
local enabled = true

function print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- 初始化函数
-- local f = CreateFrame("Frame")
local f = CreateFrame("Frame", "EnableAutoHealer", UIParent)

local function Healer_OnLoad()
    f:RegisterEvent("PLAYER_LOGIN")
    f:RegisterEvent("UNIT_HEALTH")
    f:RegisterEvent("UNIT_MAXHEALTH")
    f:RegisterEvent("SPELLS_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")

    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")

    SLASH_MCAUTOHEAL1 = "/autohealer"
    SlashCmdList["MCAUTOHEAL"] = Healer_Command

    DEFAULT_CHAT_FRAME:AddMessage("多职业自动治疗插件已加载。输入/autohealer help获取帮助。")
end

-- 命令处理函数
local function Healer_Command(msg)
    if msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("多职业自动治疗命令:")
        DEFAULT_CHAT_FRAME:AddMessage("/autohealer on - 启用自动治疗")
        DEFAULT_CHAT_FRAME:AddMessage("/autohealer off - 禁用自动治疗")
        DEFAULT_CHAT_FRAME:AddMessage("/autohealer threshold [0-100] - 设置血量百分比阈值")
    elseif msg == "on" then
        enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("自动治疗已启用")
    elseif msg == "off" then
        enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("自动治疗已禁用")
    elseif string.find(msg, "threshold") then
        local newThreshold = tonumber(string.match(msg, "threshold (%d+)"))
        if newThreshold and newThreshold > 0 and newThreshold <= 100 then
            healThreshold = newThreshold / 100
            DEFAULT_CHAT_FRAME:AddMessage("血量阈值设置为 "..newThreshold.."%")
        else
            DEFAULT_CHAT_FRAME:AddMessage("无效的阈值，请输入1-100之间的数字")
        end
    end
end

local function SetHealingSpell()
    local _, class = UnitClass("player")
    if classSpells[class] then
        healingSpellName = classSpells[class].name
        DEFAULT_CHAT_FRAME:AddMessage("检测到职业: "..class..", 使用治疗法术: "..healingSpellName..", 血量阈值设置为 "..100*healThreshold.."%")
    else
        healingSpellName = nil
        DEFAULT_CHAT_FRAME:AddMessage("警告: 当前职业不支持自动治疗!")
    end
end

-- 检查并治疗函数
local function CheckAndHeal(unit)
    DEFAULT_CHAT_FRAME:AddMessage("CheckAndHeal")
    -- if not enabled or not healingSpellName then return end

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    print(unit.."'s hp rate: "..tostring(math.floor(health/maxHealth*100)).."%")

    if maxHealth > 0 and health/maxHealth < healThreshold then
        TargetUnit(unit)
        CastSpellByName(healingSpellName)
        -- CastSpellByName("圣光术")
        print("CastSpellByName("..healingSpellName..")")
    end
end

local function CheckBuff(unit)
    if not (string.find(unit, "^party") or string.find(unit, "^player")) then
        if string.find(unit, "^target") then
            if not UnitIsFriend("player", "target") then
                return
            end
        else
            return
        end
    end

    if not UnitExists(unit) then
        return
    end

    local _, class = UnitClass(unit)
    local type = classType[class]
    local buff = buffs[type]
    local regex = regexs[type]

    local flag = 0
    for i=1, 15 do
        local A=UnitBuff(unit, i)
        if not A then
            break
        end

        if string.match(A, regex) then
            flag = 1
        end
    end

    if flag ~= 1 then
        print("CheckBuff cast buff " .. buff ..  " to "..unit)
        TargetUnit(unit)
        CastSpellByName(buff)
    end
end


-- /run local sname, srank = GetSpellName(0, BOOKTYPE_SPELL);print(sname..","..srank)

-- 创建框架并设置处理器
-- f:SetScript("OnEvent", Healer_OnEvent)
f:SetScript("OnEvent", function()
    if g_enable ~= 1 then return end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- print("AutoHealer.OnEvent - "..event)
        SetHealingSpell()
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        -- print("AutoHealer.OnEvent - "..event..", arg1 - "..arg1)
        if arg1 and (string.find(arg1, "^party") or string.find(arg1, "^partypet") or string.find(arg1, "^player") or string.find(arg1, "^target")) then
            CheckAndHeal(arg1)
        end
    elseif event == "SPELLS_CHANGED" then
        SetHealingSpell()
    elseif event == "UNIT_AURA" then
        CheckBuff(arg1)
    -- elseif event == "PLAYER_TARGET_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
    --     CheckBuff(arg1)
    end
end)

Healer_OnLoad()

-- ----------------------------------------------------------- g_enable -----------------------------------------------------------
f:SetWidth(50)
f:SetHeight(50)
f:SetPoint("CENTER", -450, 200)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)

-- 设置背景
f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

-- 创建状态文本
local text = f:CreateFontString("nil", "ARTWORK", "GameFontNormal")
text:SetPoint("TOP", 0, -8)

-- 更新文本显示
function UpdateText()
    if g_enable == 1 then
        print("g_enable: On")
        text:SetText("On")
    else
        print("g_enable: Off")
        text:SetText("Off")
    end
end
-- 切换函数
local function ToggleEnable()
    g_enable = 1 - g_enable -- 在0和1之间切换
    UpdateText()
end

-- 创建按钮
local button = CreateFrame("button", "MyToggleButton", f, "UIPanelButtonTemplate")
button:SetWidth(40)
button:SetHeight(24)
button:SetPoint("BOTTOM", 0, 5)


-- 设置按钮纹理
button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
-- 设置按钮点击事件
button:SetScript("OnClick", ToggleEnable)





print("AutoHealer loaded...")
UpdateText()
SetHealingSpell()