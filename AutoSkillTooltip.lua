local idLabel = "Spell ID: "
if GetLocale and GetLocale() == "zhCN" then
    idLabel = "技能ID: "
end

AutoSkillTooltipStatus = {spellCalls = 0, actionCalls = 0, linkCalls = 0}
local status = AutoSkillTooltipStatus

local spellByNameRank = {}
local uniqueSpellByName = {}
local mapReady = false

local function BuildSpellMap()
    if mapReady or not (GetSpellRec or GetSpellRecField or SpellInfo) then
        return
    end
    mapReady = true

    local ranges = {{1, 30000}, {40000, 55000}}
    for _, range in ipairs(ranges) do
        for id = range[1], range[2] do
            local name, rank
            if GetSpellRec then
                local ok, record = pcall(GetSpellRec, id)
                if ok and type(record) == "table" then
                    name, rank = record.name, record.rank
                end
            elseif GetSpellRecField then
                local ok, value = pcall(GetSpellRecField, id, "name")
                if ok and value then
                    name = value
                    local rankOK, rankValue = pcall(GetSpellRecField, id, "rank")
                    if rankOK then rank = rankValue end
                end
            else
                local ok, spellName, spellRank = pcall(SpellInfo, id)
                if ok then name, rank = spellName, spellRank end
            end

            if type(name) == "string" and name ~= "" then
                spellByNameRank[name .. "\001" .. (rank or "")] = id
                if uniqueSpellByName[name] == nil then
                    uniqueSpellByName[name] = id
                else
                    uniqueSpellByName[name] = false
                end
            end
        end
    end
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    if not GetSpellSlotTypeIdForName then
        BuildSpellMap()
    end
    this:UnregisterEvent("PLAYER_LOGIN")
end)

local function LookupSpellID(name, rank)
    if not name then return nil end
    if GetSpellSlotTypeIdForName then
        local fullName = name
        if rank and rank ~= "" then
            fullName = name .. "(" .. rank .. ")"
        end
        local ok, _, _, id = pcall(GetSpellSlotTypeIdForName, fullName)
        if ok and tonumber(id) and tonumber(id) > 0 then
            return id
        end
    end
    if AutoSkillIDs then
        local key = name .. "\001" .. (rank or "")
        local offlineID = AutoSkillIDs[key]
        if offlineID == false then return nil end
        if not offlineID and (not rank or rank == "") then
            offlineID = AutoSkillIDs[name .. "\001"]
        end
        if offlineID then return offlineID end
    end
    BuildSpellMap()
    local id = spellByNameRank[name .. "\001" .. (rank or "")]
        or spellByNameRank[name .. "\001"]
    if id then return id end
    return uniqueSpellByName[name] or nil
end

local function TooltipSpellID(tooltip)
    local name = getglobal(tooltip:GetName() .. "TextLeft1")
    local rank = getglobal(tooltip:GetName() .. "TextRight1")
    status.lastName = name and name:GetText()
    status.lastRank = rank and rank:GetText()
    status.lastID = LookupSpellID(status.lastName, status.lastRank)
    return status.lastID
end

local function AddSpellID(tooltip, spellID)
    spellID = tonumber(spellID)
    if not spellID or spellID <= 0 then
        return
    end

    local line = idLabel .. spellID
    local name = tooltip:GetName()
    if name then
        for i = 1, tooltip:NumLines() do
            local text = getglobal(name .. "TextLeft" .. i)
            if text and text:GetText() == line then
                return
            end
        end
    end

    tooltip:AddLine(line, 0.6, 0.8, 1)
    tooltip:Show()
end

local originalSetSpell = GameTooltip.SetSpell
function GameTooltip:SetSpell(index, bookType)
    status.spellCalls = status.spellCalls + 1
    originalSetSpell(self, index, bookType)
    local name, rank, spellID = GetSpellName(index, bookType)
    if not spellID and GetSpellLink then
        local link, linkID = GetSpellLink(index, bookType)
        spellID = linkID or (link and (string.match(link, "spell:(%d+)") or string.match(link, "enchant:(%d+)")))
    end
    status.lastName, status.lastRank = name, rank
    status.lastID = spellID or LookupSpellID(name, rank)
    AddSpellID(self, status.lastID)
end

local originalSetAction = GameTooltip.SetAction
function GameTooltip:SetAction(slot)
    status.actionCalls = status.actionCalls + 1
    originalSetAction(self, slot)
    local _, actionType, actionID = GetActionText(slot)
    if actionType == "SPELL" then
        status.lastID = actionID or TooltipSpellID(self)
        AddSpellID(self, status.lastID)
    elseif actionType ~= "ITEM" then
        AddSpellID(self, TooltipSpellID(self))
    end
end

local originalSetHyperlink = GameTooltip.SetHyperlink
function GameTooltip:SetHyperlink(link)
    status.linkCalls = status.linkCalls + 1
    originalSetHyperlink(self, link)
    if type(link) == "string" then
        AddSpellID(self, string.match(link, "spell:(%d+)") or string.match(link, "enchant:(%d+)"))
    end
end

SLASH_AUTOSKILLTOOLTIP1 = "/skillid"
SlashCmdList["AUTOSKILLTOOLTIP"] = function()
    DEFAULT_CHAT_FRAME:AddMessage("SkillID: loaded, spell=" .. status.spellCalls ..
        " action=" .. status.actionCalls .. " link=" .. status.linkCalls)
    DEFAULT_CHAT_FRAME:AddMessage("SkillID: name=" .. tostring(status.lastName) ..
        " rank=" .. tostring(status.lastRank) .. " id=" .. tostring(status.lastID))
    DEFAULT_CHAT_FRAME:AddMessage("SkillID API: rec=" .. type(GetSpellRec) ..
        " field=" .. type(GetSpellRecField) .. " lookup=" .. type(GetSpellSlotTypeIdForName) ..
        " info=" .. type(SpellInfo) .. " offline=" .. (AutoSkillIDs and "loaded" or "missing"))
end
