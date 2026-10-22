-- 盗贼简易攻击：保留原宏的技能优先级。
-- 使用宏：/script DzAttackEZ()
-- 右侧动作栏1 最上方格需放置“还击”，用于判断其是否可用
-- 主动作条：1 - 12
-- 主动作条第2页：13 - 24
-- 右侧动作条1：25 - 36
-- 右侧动作条2：37 - 48
-- 右下角动作条：49 - 60
-- 左下角动作条：61 - 72
function DzAttackEZ()
    local comboPoints = GetComboPoints()
    local castSpell = CastSpellByName
    local hasSliceDice = false

    for i = 1, 40 do
        local buff = UnitBuff("player", i)
        if not buff then
            break
        end
        if strfind(buff, "SliceDice") then
            hasSliceDice = true
            break
        end
    end

    local spell_pos_huanji = 25
    local spell_pos_tuxi = 26

    -- 邪恶攻击放到37位置
    TabByAction(37)
    if comboPoints > 0 and not hasSliceDice then
        castSpell("切割")
    elseif comboPoints == 5 and hasSliceDice then
        castSpell("破甲")
        -- castSpell("剔骨")
        -- castSpell("切割")
    elseif IsUsableAction(spell_pos_tuxi) then
        -- 突袭放到26位置
        castSpell("突袭")
    elseif IsUsableAction(spell_pos_huanji) then
        -- 还击放到25位置
        local start, duration = GetActionCooldown(spell_pos_huanji)
        if duration == 0 then
            castSpell("还击")
        else
            castSpell("邪恶攻击")
        end
    else
        castSpell("邪恶攻击")
    end
end
