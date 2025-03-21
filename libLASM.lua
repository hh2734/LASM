local lasm = {}

local unpack = unpack or table.unpack

local ops = {
    "mov",
    "jmp",
    "clr",
    "add",
    "sub",
    "mul",
    "div",
    "chk",
    "ret",
    "nxt",
    "run",
    "end",
    "err",
    "exe",
    "arg",
    "acl",
    "set",
    "get",
    "msg",
    "prf",
    "lxc"
}

local _FILE = ""

local _STOP

local _ARG = 0

local function split(line)
    line = line:gsub("#.*", ""):gsub(";", "")

    local parts = {}
    for part in line:gmatch("%S+") do
        table.insert(parts, part)
    end

    local op = parts[1]
    local val1 = parts[2]
    local val2 = parts[3]

    return op, val1, val2
end

local function read(file)
    local data = {}
    for line in io.lines(file) do
        data:insert(table.pack(split(line)))
    end
    return data
end

local function addr(num)
    if tostring(num):find("0x") then return true else return false end
end

local function comp(val)
    if addr(val) then return "_G['".._FILE.."/"..val.."']" else return val end
end

local function newline(i)
    return "::".._FILE.."_"..i..":: "
end

local function gen(...)
    local text = ""
    local _ = {...}
    local _2 = {}
    for k, v in pairs(_) do
        _2[k] = comp(v)
    end
    for k, v in pairs(_2) do
        text = text .. v .. " "
    end
    return (text:gsub("%( ", "("):gsub(" %)", ")").."\n"):gsub(" \n", "\n")
end

local function transcomp(x, arg1, arg2, i, xtext)
    local text = ""

    if x == ops[1] then
        text = text..gen(arg2, "=", arg1) -- mov 1 0x00000001 / _G['0x00000001'] = 1
    elseif x == ops[2] then
        text = text..gen("goto", _FILE.."_"..arg1)
    elseif x == ops[3] then
        text = text..gen(arg1, "=", "nil")
    elseif x == ops[4] then
        text = text..gen(arg2, "=", arg1, "+", arg2)
    elseif x == ops[5] then
        text = text..gen(arg2, "=", arg2, "-", arg1)
    elseif x == ops[6] then
        text = text..gen(arg2, "=", arg2, "*", arg1)
    elseif x == ops[7] then
        text = text..gen(arg2, "=", arg2, "//", arg1)
    elseif x == ops[8] then
        text = text..gen("if", arg1, "==", arg2, "then goto ".._FILE.."_"..i+1, "else goto ".._FILE.."_"..i+2, "end")
    elseif x == ops[9] then
        text = text..gen("os.exit(", arg1, ")")
    elseif x == ops[11] then
        _FILE = "_"..tonumber(arg1)
        text = text..gen("_FILE", "=", tonumber(arg1))
    elseif x == ops[12] then
        text = text..gen("_END", "=", tonumber(arg1))
    elseif x == ops[13] then
        text = text..gen("error(", arg1, arg2, ")")
    elseif x == ops[15] then
        if arg1 then
            _ARG = _ARG + 1
            text = text..gen("table.insert(", "_ARGS", ",", arg1)
        elseif arg2 then
            _ARG = _ARG + 2
            text = text..gen("table.insert(", "_ARGS", ",", arg1)
            text = text..gen("table.insert(", "_ARGS", ",", arg2)
        end
    elseif x == ops[16] then
        _ARG = 0
        text = text..gen("_ARGS={}")
    elseif x == ops[19] then
        text = text..gen("print(", arg1, ")")
    elseif x == ops[20] then
        text = text..gen("print(", "'_FILE='", "..", "_FILE", ")")
    elseif x == ops[21] then
        text = text..gen("pcall(", "_G['_"..arg1.."'],", (arg2 or "nil"), ")")
    end

    return xtext..newline(i)..text
end

function lasm.lua(inp, lx, mode)
    local text = ""
    if lx and mode == "static" then
        text = lx.."\n"
    elseif lx and mode == "dynamic" then
        text = "dofile('"..lx.."')\n"
    end
    local i = 1
    for line in string.gmatch(inp, "([^\n]*)\n?") do
        local op, v1, v2 = split(line)
        local otext = text
        text = transcomp(op, v1, v2, i, text)
        if otext == text then
            i = i + 0
        else
            i = i + 1
        end
        if op == ops[12] then
            i = 1
        end
    end
    --print(text)
    return text
end

local function define(op, v1, v2)
    local str = ""
    local opcode
    local _1, _2 = 0, 0
    for k, v in pairs(ops) do
        if v == op then
            opcode = k
        end
    end
    if addr(v1) then
        _1 = 1
    end
    if addr(v2) then
        _2 = 1
    end
    return opcode, _1, _2
end

local function hex(num, size)
    local str
    if tostring(num):find("0x") then
        str = num:gsub("0x", "")
    else
        str = string.format("%x", num)
    end
    local b
    repeat
        if #str ~= size then
            str = 0 .. str
        else
            b = true
        end
    until b
    return str
end

local function bin(hex)
    local str = ""
    for i = 1, #hex, 2 do
        local bstr = hex:sub(i, i+1)
        local byte = tonumber(bstr, 16)
        str = str .. string.char(byte)
    end
    return str
end

function unbin(bstr)
    local hex = ""
    for i = 1, #bstr do
        local byte = bstr:byte(i)
        local hexb = string.format("%02x", byte)
        hex = hex .. hexb
    end
    return hex
end

local function compile(op, v1, v2, _1, _2, x)
    v2 = v2 or 0
    if not op then return "" end
    if x then print(op, v1, v2, _1, _2) end
    local str = tostring(hex(op, 2).._1..hex(v1, 8).._2..hex(v2, 8))
    return str
end

function lasm.assemble(inp, out, x, y)
    local text = ""
    local i = 1
    for line in io.lines(inp) do
        local op, v1, v2 = split(line)
        if not op then
            text = text .. string.rep("0", 20)
        else
            local opcode, _1, _2 = define(op, v1, v2)
            local s = compile(opcode, v1, v2, _1, _2, x)
            text = text .. s
            if y then
                print(s)
            end
        end
    end
    local f = io.open(out, "w")
    f:write(bin(text))
    f:close()
end

function lasm.run(arg, mode, deb)
    local text
    if mode then
        local f = io.open(arg)
        text = f:read("*a")
        f:close()
    else
        text = arg
    end
    text = unbin(text)
    local str
    local k = -20
    local k2 = 0
    local textx = ""
    repeat
        k, k2 = k + 20, k2 + 20
        str = text:sub(k+1, k2)
        local opcode = tonumber(str:sub(1, 2), 16)
        local _1 = str:sub(3, 3)
        local v1 = str:sub(4, 11)
        local _2 = str:sub(12, 12)
        local v2 = str:sub(13, 20)
        local op
        if deb then print(opcode, _1, v1, _2, v2) end
        for k, v in pairs(ops) do
            if k == opcode then
                op = v
            end
        end
        if _1 == "1" then
            v1 = "0x"..v1
        else
            v1 = tonumber(v1, 16)
        end
        if _2 == "1" then
            v2 = "0x"..v2
        else
            v2 = tonumber(v2, 16)
        end
        if opcode ~= 0 then
            if (_1 == "1" and _2 == "0") or (_1 == "0" and _2 == "0") then
                textx = textx .. op.." "..v1.."\n"
            elseif (_1 == "0" and _2 == "1") or (_1 == "1" and _2 == "1") then
                textx = textx .. op.." "..v1.." "..v2.."\n"
            end
        else
            textx = textx .. "\n"
        end
        if k2 >= #text then x = true end
    until x
    local code = ""
    local i = 1
    for line in string.gmatch(textx, "([^\n]*)\n?") do
        local op, v1, v2 = split(line)
        local otext = code
        code = transcomp(op, v1, v2, i, code)
        if otext == code then
            i = i + 0
        else
            i = i + 1
        end
    end
    pcall(load(code))
end

local function tolasm(lua_code)

end

return lasm