
-- --------------------------------------------------CheckAntiBot version 2
function match_operator(str)
    if string.find(str, "+") then
        return "+"
    elseif string.find(str, "加") then
        return "加"
    end
    return nil
end
function simple_calculate(left, right, op)
    if op == "加" then op = "+" end
    local cn_num = {["一"]=1, ["二"]=2, ["三"]=3, ["四"]=4, ["五"]=5,
                   ["六"]=6, ["七"]=7, ["八"]=8, ["九"]=9, ["十"]=10,}

    -- print(left .. " | " .. right)
    -- print("left")
    -- for i=1,10 do print(string.byte(left,i));end
    -- print("right")
    -- for i=1,10 do print(string.byte(right,i));end
    local n1 = tonumber(left) or cn_num[left]
    local n2 = tonumber(right) or cn_num[right]
    -- print(n1 .. " | " .. n2)

    if not n1 or not n2 then print("not n1 or not n2") return nil end

    if op == "+" then return n1 + n2
    elseif op == "-" then return n1 - n2
    elseif op == "*" then return n1 * n2
    elseif op == "/" then return n1 / n2
    end

    return nil
end

function CheckAntiBotGossipOption()
    local gossip_txt0,gossip_type0,gossip_txt1,gossip_type1,gossip_txt2,gossip_type2,gossip_txt3,gossip_type3,gossip_txt4,gossip_type4=GetGossipOptions()
    -- print(gossip_txt0)
    local txt = string.match(gossip_txt0,"“.*C[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F](.*)”");
    -- print(txt)
    txt = string.gsub(txt,"%s+","")
    -- print(txt)
    -- print("txt")
    -- for i=1,20 do print(string.byte(txt,i));end
    local op = match_operator(txt)
    -- print(op)
    local left  = string.match(txt,"(.*)" .. op )
    -- print(left)
    local right = string.match(txt,op .. "(.*)")
    -- print(right)
    local result = simple_calculate(left, right, op)
    -- print(result)
    local num1, num2, num3, num4 = gossip_txt1,gossip_txt2,gossip_txt3,gossip_txt4

    -- 剔除多余干扰项目
    local equal_nums = { tonumber(num1), tonumber(num2), tonumber(num3), tonumber(num4)}
    local equal_cnt = 0
    for i, num in ipairs(equal_nums) do
        if tonumber(num) == result then
            equal_cnt = equal_cnt + 1
        end
    end
    if equal_cnt ~= 1 then
        print("等于" .. result .. "的数不止1个，等下一次验证")
        return
    end

    if result==tonumber(num1) then
        print('click 1 ' .. num1 .. " " .. result)
        SelectGossipOption(2)
        return
    end
    if result==tonumber(num2) then
        print('click 2 ' .. num2 .. " " .. result)
        SelectGossipOption(3)
        return
    end
    if result==tonumber(num3) then
        print('click 3 ' .. num3 .. " " .. result)
        SelectGossipOption(4)
        return
    end
    if result==tonumber(num4) then
        print('click 4 ' .. num4 .. " " .. result)
        SelectGossipOption(5)
        return
    end
end

function CheckAntiBot(antiBotBuff)
    -- "AntiMagicShell"
    AntibotBuff = antiBotBuff
    local f = 0
    for i=1,16 do
        buff = UnitBuff("player", i)
        if strfind(buff, AntibotBuff) then
            print("found  ---  " .. buff)
            f = 1
            break
        end
    end
    if f == 0 then
        return
    elseif f == 1 then
        CheckAntiBotGossipOption()
    end
end
-- --------------------------------------------------CheckAntiBot version 2


-- --------------------------------------------------CheckAntiBot version 1

-- local num1 = ""
-- local num2 = ""
-- local num3 = ""
-- local num4 = ""

-- function CheckAntiBotGossipOption()
--     local gossip_txt0,gossip_type0,gossip_txt1,gossip_type1,gossip_txt2,gossip_type2,gossip_txt3,gossip_type3,gossip_txt4,gossip_type4=GetGossipOptions()
--     pre_num1,pre_num2,pre_num3,pre_num4 = num1, num2, num3, num4
--     num1, num2, num3, num4 = gossip_txt1,gossip_txt2,gossip_txt3,gossip_txt4
--     if pre_num1 == "" then
--         return
--     else
--         if num1 == pre_num1 then
--             print('click 1 ' .. num1 .. " " .. pre_num1)
--             SelectGossipOption(2)
--             return
--         end
--         if num2 == pre_num2 then
--             print('click 2 ' .. num2 .. " " .. pre_num2)
--             SelectGossipOption(3)
--             return
--         end
--         if num3 == pre_num3 then
--             print('click 3 ' .. num3 .. " " .. pre_num3)
--             SelectGossipOption(4)
--             return
--         end
--         if num4 == pre_num4 then
--             print('click 4 ' .. num4 .. " " .. pre_num4)
--             SelectGossipOption(5)
--             return
--         end
--     end
-- end

-- function CheckAntiBot(antiBotBuff)
--     -- "AntiMagicShell"
--     AntibotBuff = antiBotBuff
--     f = 0
--     for i=1,16 do
--         buff = UnitBuff("player", i);
--         if strfind(buff, AntibotBuff) then
--             print("found  ---  " .. buff)
--             f = 1
--             break
--         end
--     end
--     if f == 0 then
--         num1 = ""
--         num2 = ""
--         num3 = ""
--         num4 = ""
--         return
--     elseif f == 1 then
--         CheckAntiBotGossipOption()
--     end
-- end
-- --------------------------------------------------CheckAntiBot version 1