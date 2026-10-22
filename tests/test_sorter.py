"""Inventory simulation; does not replace an in-game check."""
from test_seller import lua, p
lua.execute(r'''
cursor, combat, moves = nil, false, 0
sizes = {[0]=5,[1]=2,[2]=7,[3]=0,[4]=3}
function GetContainerNumSlots(bag) return sizes[bag] end
function CursorHasItem() return cursor ~= nil end
function UnitAffectingCombat() return combat end
function PickupContainerItem(bag,slot)
    assert(slot >= 1 and slot <= sizes[bag], 'invalid slot')
    local key=bag..':'..slot
    cursor, inventory[key] = inventory[key], cursor
    moves=moves+1
end
function ClearCursor() assert(not cursor, 'unexpected item left on cursor') end
''')
lua.execute((p/'AutoItemSorter.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
assert(AutoHealerSellerButton:GetText()=='自动助手设置')
dispatch('MERCHANT_CLOSED')
reset()
put(0,1,'Z'); put(0,3,'A'); put(0,5,'B')
put(1,1,'Unselected'); put(2,2,'D'); put(2,7,'C')
click('按背包排序'); tick(100)
assert(GetContainerItemLink(0,1)=='item:1:[A]')
assert(GetContainerItemLink(0,2)=='item:1:[B]')
assert(GetContainerItemLink(0,3)=='item:1:[Z]')
assert(not GetContainerItemLink(0,4) and not GetContainerItemLink(0,5))
assert(GetContainerItemLink(2,1)=='item:1:[C]' and GetContainerItemLink(2,2)=='item:1:[D]')
assert(GetContainerItemLink(1,1)=='item:1:[Unselected]')
assert(not cursor and #sales==0)
reset(); click('按背包排序'); tick(100) -- empty bags
reset(); put(0,1,'Z'); put(0,2,'A',nil,true)
local previous=moves
click('按背包排序'); tick(100); assert(moves==previous, 'locked items stop safely')
reset(); put(0,1,'Z'); put(0,2,'A')
click('按背包排序'); click('停止'); tick(100); assert(moves==previous)
combat=true; click('按背包排序'); tick(100); assert(moves==previous); combat=false
click('按背包排序'); combat=true; tick(100); assert(moves==previous); combat=false
click('按背包排序'); AutoSellerBag0:SetChecked(false); fire(AutoSellerBag0,'OnClick')
tick(100); assert(moves==previous)
reset(); put(0,1,'Z'); put(0,2,'A'); put(0,3,'A')
click('按背包排序'); tick(100)
assert(GetContainerItemLink(0,1)=='item:1:[A]' and GetContainerItemLink(0,2)=='item:1:[A]')
assert(GetContainerItemLink(0,3)=='item:1:[Z]' and not cursor)
reset(); put(0,1,'Z'); put(1,1,'A')
SortItemsEfficient(12,0,1); tick(100)
assert(GetContainerItemLink(0,1)=='item:1:[A]' and GetContainerItemLink(0,2)=='item:1:[Z]')
reset(); AutoHealerDB.seller.bags={}; click('按背包排序'); tick(10)
AutoHealerDB.seller.bags={[3]=true}; click('按背包排序'); tick(10)
-- Starting sorting cancels a sale before inventory starts moving.
reset(); dispatch('MERCHANT_SHOW'); put(0,1,'Z'); put(0,2,'A')
click('按名称售卖'); click('按背包排序'); tick(100); assert(#sales==0)
-- Starting a sale cancels sorting.
reset(); put(0,1,'Z'); put(0,2,'A'); previous=moves
click('按背包排序'); click('按名称售卖'); tick(100); assert(moves==previous)
''')
print('PASS: sorting UI, actual bag sizes, separate selected bags, empty slots/bags, duplicates, cursor cleanup, locks, combat, stop, changed selection, legacy range, sale/sort exclusion.')
