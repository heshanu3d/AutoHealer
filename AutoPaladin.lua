-- 圣骑士简易攻击：按优先级补齐自身缺少的增益。
-- 使用宏：/script QsAttackEZ()
-- 动作栏37号位置放置用于判断攻击距离的技能。
-- UnitBuff 从1开始；GetPlayerBuff 的筛选序号从0开始。
local function QsBuffNeedsRefresh(unitBuffIndex)
    local buffIndex = GetPlayerBuff(unitBuffIndex - 1, "HELPFUL")
    if not buffIndex or buffIndex < 0 then return true end
    local timeLeft = GetPlayerBuffTimeLeft(buffIndex)
    return timeLeft ~= nil and timeLeft < 5
end

function QsAttackEZ()
    local castSpell = CastSpellByName
    local hasHolyAura = false
    local hasBlessingOfKings = false
    local hasSealOfCommand = false
    local hasHolyStrike = false
    local hasCrusaderStrike = false

    for i = 1, 40 do
        local buff = UnitBuff("player", i)
        if not buff then
            break
        end
        if strfind(buff, "Spell_Holy_MindVision") then
            hasHolyAura = true
        elseif strfind(buff, "Spell_Magic_MageArmor") then
            hasBlessingOfKings = true
        elseif strfind(buff, "Ability_Warrior_InnerRage") then
            hasSealOfCommand = not QsBuffNeedsRefresh(i)
        elseif strfind(buff, "Spell_Holy_HolyNova") then
            hasHolyStrike = not QsBuffNeedsRefresh(i)
        elseif strfind(buff, "Spell_Holy_CrusaderStrike") then
            hasCrusaderStrike = not QsBuffNeedsRefresh(i)
        end
    end

    TabByAction(37)
    if not hasHolyAura then
        castSpell("圣洁光环")
    elseif not hasBlessingOfKings then
        castSpell("王者祝福")
    elseif not hasSealOfCommand then
        castSpell("命令圣印")
    elseif not hasHolyStrike then
        castSpell("神圣打击")
    elseif not hasCrusaderStrike then
        castSpell("十字军打击")
    else
        castSpell("十字军打击")
    end
end
