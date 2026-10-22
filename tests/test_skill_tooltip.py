"""Exercise the 1.12 tooltip hooks with Lua 5.1 mocks, not an in-game test."""
from pathlib import Path

from lupa.lua51 import LuaRuntime


lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
GameTooltip = {name = "GameTooltip", lines = {}}
SlashCmdList = {}
messages = {}
DEFAULT_CHAT_FRAME = {AddMessage = function(self, message) table.insert(messages, message) end}
function getglobal(name) return _G[name] end
function GetLocale() return "zhCN" end
function CreateFrame()
    return {
        RegisterEvent = function(self, event) self.event = event end,
        SetScript = function(self, script, handler) self.handler = handler end,
        UnregisterEvent = function(self, event) self.event = nil end,
    }
end
function GameTooltip:GetName() return self.name end
function GameTooltip:NumLines() return #self.lines end
function GameTooltip:ClearLines()
    self.lines = {}
    GameTooltipTextRight1 = nil
end
function GameTooltip:AddLine(text)
    table.insert(self.lines, text)
    _G[self.name .. "TextLeft" .. #self.lines] = {GetText = function() return text end}
end
function GameTooltip:Show() self.shown = true end

local records = {
    [635] = {name = "Spell 1", rank = "Rank 1"},
    [777] = {name = "Spell 5"},
    [2061] = {name = "Action Spell", rank = "Rank 1"},
}
recordReads = 0
function GetSpellRec(id)
    recordReads = recordReads + 1
    return records[id]
end
function GetSpellSlotTypeIdForName(name)
    if name == "Spell 4(Rank 1)" then return 4, "spell", 12345 end
    return 0, "unknown", 0
end
function GetSpellName(index, bookType)
    if index == 6 then return "邪恶攻击", "等级 1" end
    return "Spell " .. index, "Rank 1"
end
function GetSpellLink(index, bookType)
    if index == 2 then return "|Hspell:48120|h[Spell]|h" end
end
function GameTooltip:SetSpell(index, bookType)
    self:ClearLines()
    self:AddLine("Spell " .. index)
end

local actions = {
    [8] = {nil, "SPELL", 2054},
    [9] = {nil, "SPELL", 635},
    [10] = {"Macro", "MACRO", 42},
    [11] = {nil, "ITEM", 6948},
    [12] = {nil, "SPELL"},
    [13] = {},
    [14] = {nil, "SPELL"},
    [15] = {"Macro", "MACRO", 45},
}
function GetActionText(slot)
    local action = actions[slot] or {}
    return action[1], action[2], action[3]
end
function GameTooltip:SetAction(slot)
    if slot == 9 then
        self:SetSpell(1, "spell")
    else
        self:ClearLines()
        if slot == 12 or slot == 13 or slot == 14 or slot == 15 then
            self:AddLine((slot == 14 or slot == 15) and "邪恶攻击" or "Action Spell")
            GameTooltipTextRight1 = {GetText = function()
                return (slot == 14 or slot == 15) and "等级 1" or "Rank 1"
            end}
        else
            self:AddLine("Action")
        end
    end
end
function GameTooltip:SetHyperlink(link)
    self:ClearLines()
    self:AddLine("Link")
end
''')
addon = Path(__file__).resolve().parents[1]
lua.execute((addon / "AutoSkillIDs.lua").read_text(encoding="utf-8"))
lua.execute((addon / "AutoSkillTooltip.lua").read_text(encoding="utf-8"))
lua.execute(r'''
local t = GameTooltip
t:SetSpell(4, "spell")
assert(#t.lines == 2 and t.lines[2] == "技能ID: 12345" and recordReads == 0)
assert(AutoSkillIDs["邪恶攻击\001等级 1"] == 1752)
t:SetSpell(6, "spell")
assert(#t.lines == 2 and t.lines[2] == "技能ID: 1752" and recordReads == 0)
t:SetSpell(99, "spell")
assert(#t.lines == 1)
t:SetSpell(1, "spell")
assert(#t.lines == 2 and t.lines[2] == "技能ID: 635")
assert(recordReads > 0)
t:SetSpell(2, "spell")
assert(#t.lines == 2 and t.lines[2] == "技能ID: 48120")
t:SetSpell(3, "spell")
assert(#t.lines == 1)
t:SetSpell(5, "spell")
assert(#t.lines == 2 and t.lines[2] == "技能ID: 777")
t:SetAction(8)
assert(#t.lines == 2 and t.lines[2] == "技能ID: 2054")
t:SetAction(9)
assert(#t.lines == 2 and t.lines[2] == "技能ID: 635")
t:SetAction(10)
assert(#t.lines == 1)
t:SetAction(11)
assert(#t.lines == 1)
t:SetAction(12)
assert(#t.lines == 2 and t.lines[2] == "技能ID: 2061")
t:SetAction(13)
assert(#t.lines == 2 and t.lines[2] == "技能ID: 2061")
t:SetAction(14)
assert(#t.lines == 2 and t.lines[2] == "技能ID: 1752")
t:SetAction(15)
assert(#t.lines == 2 and t.lines[2] == "技能ID: 1752")
GetSpellRec, GetSpellRecField, GetSpellSlotTypeIdForName, SpellInfo = nil, nil, nil, nil
t:SetAction(14)
assert(#t.lines == 2 and t.lines[2] == "技能ID: 1752")
t:SetHyperlink("spell:116:0")
assert(#t.lines == 2 and t.lines[2] == "技能ID: 116")
t:SetHyperlink("enchant:635")
assert(#t.lines == 2 and t.lines[2] == "技能ID: 635")
t:SetHyperlink("item:6948:0")
assert(#t.lines == 1)
SlashCmdList.AUTOSKILLTOOLTIP()
assert(AutoSkillTooltipStatus.spellCalls > 0 and AutoSkillTooltipStatus.actionCalls > 0)
assert(messages[1] and string.find(messages[1], "SkillID: loaded"))
assert(string.find(messages[3], "offline=loaded"))
''')
print("PASS: spellbook, offline IDs, action/macro skills, nested hooks, non-spell exclusions")
