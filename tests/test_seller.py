"""Run with Python and lupa.lua51. Mock tests, not an in-game UI test."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
p = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
frames, inventory, sales, messages = {}, {}, {}, {}
SlashCmdList, UISpecialFrames = {}, {}
UIParent, ChatFontNormal, GameFontHighlightSmall = {}, {}, {}
clock = 100
function GetTime() return clock end
function getglobal(name) return _G[name] end
function print() end
DEFAULT_CHAT_FRAME = {AddMessage = function(self, msg) table.insert(messages, msg) end}
local methods = {}
function methods:SetScript(key, value) self.scripts[key] = value end
function methods:RegisterEvent(key) self.events[key] = true end
function methods:SetText(text)
    self.text = text
    if self.scripts.OnTextChanged then fire(self, 'OnTextChanged') end
end
function methods:GetText() return self.text or '' end
function methods:EnableMouse(value) self.mouseEnabled = value end
function methods:EnableKeyboard(value) self.keyboardEnabled = value end
function methods:SetFocus() self.focused = true end
function methods:ClearFocus() self.focused = false end
function methods:Insert(text) self:SetText(self:GetText() .. text) end
function methods:SetFontObject(font) assert(font, 'Missing font object') end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false; if self.scripts.OnHide then fire(self,'OnHide') end end
function methods:IsShown() return self.shown end
function methods:GetLeft() return 123 end
function methods:GetBottom() return 456 end
function methods:GetHeight() return 154 end
function methods:GetVerticalScroll() return 0 end
function methods:RegisterForDrag(button) self.dragButton = button end
function methods:RegisterForClicks(button) self.clickButton = button end
function methods:StartMoving() self.moving = true end
function methods:StopMovingOrSizing() self.moving = false end
function methods:CreateFontString() return CreateFrame('FontString') end
function CreateFrame(kind, name, parent, template)
    local f = {name=name, parent=parent, scripts={}, events={}, shown=true}
    setmetatable(f,{__index=function(t,k) return methods[k] or function() end end})
    table.insert(frames,f)
    if name then _G[name]=f end
    if template == 'UICheckButtonTemplate' then _G[name..'Text']=CreateFrame('FontString') end
    return f
end
function fire(f, script, ...)
    this=f
    f.scripts[script](...)
end
function dispatch(name)
    event=name
    for _,f in ipairs(frames) do if f.events[name] then fire(f,'OnEvent') end end
end
function tick(n)
    for i=1,n do
        clock=clock+0.31
        arg1=0.31
        for _,f in ipairs(frames) do if f.scripts.OnUpdate then fire(f,'OnUpdate') end end
    end
end
function GetContainerNumSlots(bag) return 4 end
function GetContainerItemLink(bag, slot)
    local item=inventory[bag..':'..slot]
    return item and item.link
end
function GetContainerItemInfo(bag, slot)
    local item=inventory[bag..':'..slot]
    if item then return 'texture',item.count,item.locked end
end
function UseContainerItem(bag, slot)
    local key=bag..':'..slot
    table.insert(sales,key)
    if not inventory[key].unsellable then inventory[key]=nil end
end
function BuyMerchantItem() end
function put(bag,slot,name,unsellable,locked)
    inventory[bag..':'..slot]={link='item:1:['..name..']',count=1,unsellable=unsellable,locked=locked}
end
function reset()
    AutoSeller_Stop(true)
    inventory,sales={},{}
    AutoHealerDB.seller.bags={[0]=true,[2]=true}
end
function click(text)
    for _,f in ipairs(frames) do if f.text==text and f.scripts.OnClick then fire(f,'OnClick'); return end end
    error('Missing button: '..text)
end
function UnitClass() return 'Mage','MAGE' end
function GetSpellName() return nil end
''')
for name in ('AutoHealer.lua', 'AutoSeller.lua'):
    source=(p/name).read_text(encoding='utf-8-sig')
    # Compilation and execution with legacy global this/event/arg1 callback semantics.
    lua.execute(source)
lua.execute(r'''
dispatch('VARIABLES_LOADED')
assert(EnableAutoHealer.dragButton=='RightButton')
assert(MyToggleButton.dragButton=='RightButton')
assert(MyToggleButton.clickButton=='LeftButtonUp')
fire(MyToggleButton,'OnDragStart'); assert(EnableAutoHealer.moving)
fire(MyToggleButton,'OnDragStop'); assert(not EnableAutoHealer.moving)
assert(AutoHealerDB.togglePosition.x==123)
AutoSeller_ToggleWindow()
assert(AutoHealerSellerWindow:IsShown())
assert(AutoSellerNamesEdit.mouseEnabled and AutoSellerNamesEdit.keyboardEnabled)
click('编辑名单'); assert(AutoSellerNamesEdit.focused)
AutoSellerNamesEdit:SetText('测试物品甲')
fire(AutoSellerNamesEdit,'OnEnterPressed')
AutoSellerNamesEdit:Insert('测试物品乙')
assert(AutoHealerDB.seller.names == '测试物品甲\n测试物品乙','multiline names saved')
fire(AutoSellerNamesEdit,'OnEscapePressed'); assert(not AutoSellerNamesEdit.focused)
arg1='LeftButton'; fire(AutoSellerNamesScroll,'OnMouseDown')
assert(AutoSellerNamesEdit.focused,'blank viewport focuses editor')
fire(AutoSellerNamesEdit,'OnEscapePressed')
arg1='LeftButton'; fire(AutoSellerNamesEdit,'OnMouseDown')
assert(AutoSellerNamesEdit.focused,'editor click focuses editor')
AutoSeller_ToggleWindow(); AutoSeller_ToggleWindow()
assert(AutoSellerNamesEdit:GetText()=='测试物品甲\n测试物品乙','names survive reopening')
for bag=0,4 do assert(not AutoHealerDB.seller.bags[bag]) end
reset()
put(0,1,'Keep'); FSI(0,1,4); tick(10); assert(#sales==0,'must not sell without merchant')
dispatch('MERCHANT_SHOW')
reset()
put(0,1,'A'); put(1,1,'A'); put(2,1,'AB'); put(2,2,'A')
AutoSellerNamesEdit:SetText('A\nOther')
click('按名称售卖'); tick(25)
assert(#sales==2 and sales[1]=='0:1' and sales[2]=='2:2','exact match / selected bags')
assert(inventory['1:1'] and inventory['2:1'])
reset()
put(0,1,'A'); put(1,1,'B'); put(2,1,'C')
click('按背包售卖'); tick(4); assert(#sales==0,'confirmation required')
click('按背包售卖'); tick(25)
assert(#sales==2 and inventory['1:1'],'bag mode ignores names but honors bags')
reset(); put(0,1,'A'); put(0,2,'A')
click('按名称售卖'); tick(1); dispatch('MERCHANT_CLOSED'); tick(20)
assert(#sales==1,'close merchant stops queue')
dispatch('MERCHANT_SHOW'); tick(20); assert(#sales==1,'manual sale must not restart')
reset(); put(0,1,'A',true); put(0,2,'A')
click('按名称售卖'); tick(30)
assert(#sales==2 and inventory['0:1'] and not inventory['0:2'],'unsellable skip')
reset(); put(0,1,'A',nil,true); put(0,2,'A')
click('按名称售卖'); tick(30); assert(#sales==1 and sales[1]=='0:2','locked skip')
reset(); put(0,1,'A'); put(0,2,'A')
click('按名称售卖'); put(0,1,'Replacement'); tick(30)
assert(#sales==1 and inventory['0:1'],'replacement protected')
reset(); put(0,1,'A'); put(0,2,'A')
click('按名称售卖'); click('停止'); tick(30); assert(#sales==0,'stop button')
reset(); put(0,1,'A'); put(2,1,'Other')
AutoSellerNamesEdit:SetText(' A，Other；Third ')
click('按名称售卖'); tick(30); assert(#sales==2,'multiple names and Chinese separators')
reset(); put(0,1,'A'); put(2,1,'A')
click('按名称售卖')
AutoSellerBag0:SetChecked(false); fire(AutoSellerBag0,'OnClick'); tick(30)
assert(#sales==0 and not AutoHealerDB.seller.bags[0],'changing bags stops queue')
reset(); put(0,1,'A'); put(2,1,'A')
FSIBN(0,4,{'A'}); tick(30); assert(#sales==2,'legacy names macro')
reset(); put(0,1,'A'); put(2,1,'A')
FSIBN_Anything(0,0); tick(30); assert(#sales==1 and inventory['2:1'],'legacy range')
reset(); put(0,1,'A'); click('按名称售卖')
AutoSeller_ToggleWindow(); AutoSeller_ToggleWindow(); tick(30)
assert(#sales==1,'reopening settings preserves active queue')
''')
print('PASS: Lua 5.1 compile/load, legacy drag callbacks and saved position, UI creation, safe defaults, merchant guard, exact/multi-name filtering, bag selection, confirmation, stop/close, unsellable/locked/replaced items, legacy macro compatibility, reopen window.')
