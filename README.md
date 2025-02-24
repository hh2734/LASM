# LASM - LuaASM

## Syntax:
op v1 v2 # Comment

0xXXXXXXXX - Address
123 (up to 4294967295) - Number

v1 -> Address or number
v2 -> Address or nothing

## Commands:
mov (num/addr1) addr2 - "addr2 = num|addr1"
jmp num - "goto line[num]"
clr addr - "addr = nil"
add (num/addr1) addr2 - "addr2 = addr2 + num|addr1"
sub (num/addr1) addr2 - "addr2 = addr2 - num|addr1"
mul (num/addr1) addr2 - "addr2 = addr2 * num|addr1"
div (num/addr1) addr2 - "addr2 = addr2 // num|addr1"
chk (num/addr1) addr2 - "if num|addr1 == addr2 then goto lineX+1 else goto lineX+2"
ret (num/addr1) - "os.exit(num|addr1)"
nxt - **Soon**
run addr1 - "_FILE = addr1"
end addr1 - "_END = addr1"
err (num/addr1) - "error(num|addr)"
exe - **Soon**
arg - **Soon**
acl - **Soon**
set - **Soon**
get - **Soon**
msg (num/addr1) - "print(num|addr1)"
prf 0 - "print('_FILE = '.._FILE)"

## Usage:
lua lasmtool lua input.lasm output.lua - LASM -> Lua
lua lasmtool compile input.lasm output.lcc - LASM -> LASM (bin. mode)
lua lasmtool run file.lcc - Run LASM (bin. mode)
