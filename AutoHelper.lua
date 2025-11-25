-- #showtooltip 邪恶攻击
-- /startattack
-- /script p,c,b,i,f=GetComboPoints(),CastSpellByName;for i=1,16 do b=UnitBuff("player",i);if b and strfind(b,"SliceDice") then f=1;break;end;end;if p>1 and not f then c("切割");elseif p==5 and f then c("切割");else c("邪恶攻击");end;
-- function RogueMainAttackSpell(spell)
--     local p,b,i,f=GetComboPoints();
--     local g = 0
--     for i=1,16 do
--         b = UnitBuff("player",i)
--         if b and strfind(b, "SliceDice") then
--             f = 1
--         end
--         if b and strfind(b, "PunishingBlow") then
--             g = 1
--         end
--     end
--     if g == 0 then
--         CastSpellByName("剑刃乱舞");
--     end
--     if p>1 and not f then
--         CastSpellByName("切割")
--     elseif p==5 and f then
--         CastSpellByName("切割")
--     else
--         CastSpellByName(spell)
--     end
-- end

-- function RogueMainAttackSpell_AntiCaptcha(spell)
--     local p,b,i,f=GetComboPoints();
--     local g = 0
--     local need_captcha = false
--     for i=1,16 do
--         b = UnitBuff("player",i)
--         if b and strfind(b, "SliceDice") then
--             f = 1
--         end
--         if b and strfind(b, "PunishingBlow") then
--             g = 1
--         end
--         if b and strfind(b, "AntiMagicShell") then
--             need_captcha = true
--         end
--     end
--     if need_captcha then
--         CheckAntiBotGossipOption()
--     end
--     if g == 0 then
--         CastSpellByName("剑刃乱舞");
--     end
--     if p>1 and not f then
--         CastSpellByName("切割")
--     elseif p==5 and f then
--         CastSpellByName("切割")
--     else
--         CastSpellByName(spell)
--     end
-- end

function GetRogueBuffs()
    local buffs = {
        needCaptcha = false,
        hasSliceDice = false,       -- 切割
        hasPunishingBlow = false,   -- 剑刃乱舞
        hasBuffHHDC = false,        -- 豪华大餐
    }

    for i = 1, 16 do
        local buffName = UnitBuff("player", i)
        if buffName then
            if strfind(buffName, "SliceDice") then
                buffs.hasSliceDice = true
            end
            if strfind(buffName, "PunishingBlow") then
                buffs.hasPunishingBlow = true
            end
            if strfind(buffName, "AntiMagicShell") then
                buffs.needCaptcha = true
            end
            if strfind(buffName, "3080") then
                buffs.hasBuffHHDC = true
            end
        end
    end

    return buffs
end

function RogueMainAttackSpell(spell)
    local comboPoints = GetComboPoints()
    local buffs = GetRogueBuffs()

    if not buffs.hasPunishingBlow then
        CastSpellByName("剑刃乱舞")
    end
    if not buffs.hasBuffHHDC then
        UseInventoryItem("豪华大餐")
    end

    if comboPoints > 1 and not buffs.hasSliceDice then
        CastSpellByName("切割")
    elseif comboPoints == 5 and buffs.hasSliceDice then
        CastSpellByName("切割")
    else
        CastSpellByName(spell)
    end
end

function RogueMainAttackSpell_AntiCaptcha(spell)
    local comboPoints = GetComboPoints()
    local buffs = GetRogueBuffs()

    if buffs.needCaptcha then
        CheckAntiBotGossipOption()
    end
    if not buffs.hasPunishingBlow then
        CastSpellByName("剑刃乱舞")
    end
    if not buffs.hasBuffHHDC then
        UseInventoryItem("豪华大餐")
    end

    if comboPoints > 1 and not buffs.hasSliceDice then
        CastSpellByName("切割")
    elseif comboPoints == 5 and buffs.hasSliceDice then
        CastSpellByName("切割")
    else
        CastSpellByName(spell)
    end
end

function HunterMainAttackSpell(spell)
end

function GetPaladinBuffs()
    local buffs = {
        needCaptcha = false,
        hasSealOfJustice = false,   -- 正义圣印
        hasBlessingOfKings = false, -- 王者祝福
        hasBuffHHDC = false,        -- 豪华大餐
    }

    for i = 1, 16 do
        local buffName = UnitBuff("player", i)
        if buffName then
            if strfind(buffName, "AntiMagicShell") then
                buffs.needCaptcha = true
            end
            if strfind(buffName, "ThunderBolt") then
                buffs.hasSealOfJustice = true
            end
            if strfind(buffName, "MageArmor") then
                buffs.hasBlessingOfKings = true
            end
            if strfind(buffName, "3080") then
                buffs.hasBuffHHDC = true
            end
        end
    end

    return buffs
end

-- TODO 参考 用 GetSpellCooldownByName 实现
-- PalidinMainAttackSpell("奉献", 10, "圣光惩戒")
function PalidinMainAttackSpell(aoe_spell, aoe_action_id, single_spell)
    local buffs = GetPaladinBuffs()

    if buffs.needCaptcha then
        CheckAntiBotGossipOption()
    end
    if not buffs.hasBlessingOfKings then
        CastSpellByName("王者祝福")
    end
    if not buffs.hasSealOfJustice then
        CastSpellByName("正义圣印")
    end
    if not buffs.hasBuffHHDC then
        UseInventoryItem("豪华大餐")
    end

    local a, b = GetActionCooldown(aoe_action_id)
    if UnitAffectingCombat("player") then
        if b > 2 then
            CastSpellByName(single_spell)
        else
            CastSpellByName(aoe_spell)
        end
    else
        CastSpellByName(single_spell)
    end
end
