#!/usr/bin/env lua
-- Nocurses my beloved.
local nocurses = require("nocurses")

function runtimeError(m)
	io.write("\27[?1049l")
	print("\27[91m" .. m .. "\27[0m")
	os.exit(1)
end

function convert(s)
	local t = {}
	for i in string.gmatch(s, "(.)") do
		table.insert(t, string.byte(i))
	end
	return t
end

-- Because lua interprets one char as 1 byte, this can cause some problems.
function lastCharSize(s)
	local l = 0
	for p, _ in utf8.codes(s) do
		l = p
	end
	return #s - l + 1
end

function toSigned(n)
	if n >= 0x800000 then
		return n - 0x1000000
	else
		return n
	end
end

-- Memory object.
mem = {
	ram = {},
	term = "",
	-- Init function.
	init = function()
		for i = 1, 0x800000 do
			mem.ram[#mem.ram + 1] = 0
		end
	end,
	-- Read and write functions.
	write = function(addr, val)
		if addr < 0x800000 then
			mem.ram[addr + 1] = val
		elseif addr == 0x800000 then
			if val == 8 then
				mem.term = string.sub(mem.term, 1, -1 - lastCharSize(mem.term))
				nocurses.clrscr()
			else
				mem.term = mem.term .. utf8.char(val)
				nocurses.gotoxy(1, 1)
			end
			print(mem.term)
		elseif addr == 0x800001 then
			mem.term = ""
			nocurses.clrscr()
		end
	end,
	read = function(addr)
		local d = 0
		local temp = ""
		-- VM keyboard uses 10(line feed) as new line character. Keep that in mind when using on Mac or Windows.
		local conv = {
			Up = 0x1b5b41,
			Down = 0x1b5b42,
			Left = 0x1b5b43,
			Right = 0x1b5b44,
			End = 0x1b5b46,
			Home = 0x1b5b48,
			F1 = 0x1b4f50,
			F2 = 0x1b4f51,
			F3 = 0x1b4f52,
			F4 = 0x1b4f53,
			Enter = 0xa,
			Tab = 0x9,
			Backspace = 0x8
		}
		if addr < 0x800000 then
			d = mem.ram[addr + 1]
		elseif addr == 0x800002 then
			temp = nocurses.getkey(0.05)
			if conv[temp] then
				d = conv[temp]
			elseif temp ~= nil then
				d = utf8.codepoint(temp)
			else
				d = 0
			end
		elseif addr == 0x800003 then
			d = os.time()
		elseif addr == 0x800004 then
			d = math.random(0, 0xffffff)
		end
		return d
	end
}

-- The cpu itself.
cpu = {
	running = true,
	stack = {},
	retStack = {},
	iterStack = {},
	pc = 0,
	-- Push and pop functions.
	push = function(o, s, v, l)
		table.insert(s, v)
		if #s > l then
			runtimeError("Stack overflow.\nPC: " .. cpu.pc .. "\nInstruction: " .. string.format("%x", o))
		end
	end,
	pop = function(o, s)
		local temp = 0
		if #s == 0 then
			runtimeError("Stack underflow.\nPC: " .. cpu.pc .. "\nInstruction: " .. string.format("%x", o))
		end
		temp = s[#s]
		table.remove(s)
		return temp
	end,
	-- The part where the magic happens.
	cycle = function(p, m)
		local instr = 0
		local fn = 0
		local imm = 0
		local addr = 0
		local a = 0
		local b = 0
		local c = 0
		if p[cpu.pc + 1] == nil then
			runtimeError("Program counter out of range.")
		else
			instr = p[cpu.pc + 1] >> 4
			fn = p[cpu.pc + 1] & 0xf
			if instr == 2 or instr >= 10 and instr <= 13 then
				if p[cpu.pc + 2] == nil or p[cpu.pc + 3] == nil or p[cpu.pc + 4] == nil then
					runtimeError("Missing parameter.\nPC: " .. cpu.pc .. "\nInstruction: " .. string.format("%x", p[cpu.pc + 1]))
				else
					addr = (fn << 24) + (p[cpu.pc + 2] << 16) + (p[cpu.pc + 3] << 8) + p[cpu.pc + 4]
					imm = addr & 0xffffff
				end
			end
			-- Noop.
			if instr == 0 then
				goto noop
			-- Arithmetic and logic operation.
			elseif instr == 1 then
				b = cpu.pop(p[cpu.pc + 1], cpu.stack)
				a = cpu.pop(p[cpu.pc + 1], cpu.stack)
				if fn == 0 then
					a = (toSigned(a) + toSigned(b)) & 0xffffff
				elseif fn == 1 then
					a = (toSigned(a) - toSigned(b)) & 0xffffff
				elseif fn == 2 then
					a = (toSigned(a) * toSigned(b)) & 0xffffff
				elseif fn == 3 then
					a = (a * b) & 0xffffff
				elseif fn == 4 then
					a = ((toSigned(a) * toSigned(b)) >> 12) & 0xffffff
				elseif fn == 5 then
					a = (toSigned(a) // toSigned(b)) & 0xffffff
				elseif fn == 6 then
					a = (a // b) & 0xffffff
				elseif fn == 7 then
					a = ((toSigned(a) << 12) // toSigned(b)) & 0xffffff
				elseif fn == 8 then
					a = toSigned(a) % toSigned(b)
				elseif fn == 9 then
					a = a & b
				elseif fn == 10 then
					a = a | b
				elseif fn == 11 then
					a = a ~ b
				elseif fn == 12 then
					a = ~(a | b)
				elseif fn == 13 then
					a = (a << b) & 0xffffff
				elseif fn == 14 then
					a = a >> b
				elseif fn == 15 then
					a = (toSigned(a) >> b) & 0xffffff
				end
				cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
			-- Push.
			elseif instr == 2 then
				cpu.push(p[cpu.pc + 1], cpu.stack, imm, 0x40000)
				cpu.pc = cpu.pc + 3
			-- Stack operations.
			elseif instr == 3 then
				if fn == 0 then
					cpu.pop(p[cpu.pc + 1], cpu.stack)
				elseif fn == 1 then
					a = cpu.pop(p[cpu.pc + 1], cpu.stack)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
				elseif fn == 2 then
					a = cpu.pop(p[cpu.pc + 1], cpu.stack)
					b = cpu.pop(p[cpu.pc + 1], cpu.stack)
					cpu.push(p[cpu.pc + 1], cpu.stack, b, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, b, 0x40000)
				elseif fn == 3 then
					a = cpu.pop(p[cpu.pc + 1], cpu.stack)
					b = cpu.pop(p[cpu.pc + 1], cpu.stack)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, b, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
				elseif fn == 4 then
					a = cpu.pop(p[cpu.pc + 1], cpu.stack)
					cpu.pop(p[cpu.pc + 1], cpu.stack)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
				elseif fn == 5 then
					a = cpu.pop(p[cpu.pc + 1], cpu.stack)
					b = cpu.pop(p[cpu.pc + 1], cpu.stack)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, b, 0x40000)
				elseif fn == 6 then
					a = cpu.pop(p[cpu.pc + 1], cpu.stack)
					b = cpu.pop(p[cpu.pc + 1], cpu.stack)
					c = cpu.pop(p[cpu.pc + 1], cpu.stack)
					cpu.push(p[cpu.pc + 1], cpu.stack, b, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, c, 0x40000)
				elseif fn == 7 then
					a = cpu.pop(p[cpu.pc + 1], cpu.stack)
					b = cpu.pop(p[cpu.pc + 1], cpu.stack)
					c = cpu.pop(p[cpu.pc + 1], cpu.stack)
					cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, c, 0x40000)
					cpu.push(p[cpu.pc + 1], cpu.stack, b, 0x40000)
				end
			-- Store.
			elseif instr == 4 then
				a = cpu.pop(p[cpu.pc + 1], cpu.stack)
				b = cpu.pop(p[cpu.pc + 1], cpu.stack)
				m.write(b, a)
			-- Load.
			elseif instr == 5 then
				a = cpu.pop(p[cpu.pc + 1], cpu.stack)
				a = m.read(a)
				cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
			-- Push to iteration stack.
			elseif instr == 6 then
				a = cpu.pop(p[cpu.pc + 1], cpu.stack)
				cpu.push(p[cpu.pc + 1], cpu.iterStack, a, 0x100)
			-- Copy from iteration stack.
			elseif instr == 7 then
				a = cpu.pop(p[cpu.pc + 1], cpu.iterStack)
				cpu.push(p[cpu.pc + 1], cpu.iterStack, a, 0x100)
				cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
			-- Drop from iteration stack.
			elseif instr == 8 then
				a = cpu.pop(p[cpu.pc + 1], cpu.iterStack)
				cpu.push(p[cpu.pc + 1], cpu.stack, a, 0x40000)
			-- Comparison.
			elseif instr == 9 then
				b = cpu.pop(p[cpu.pc + 1], cpu.stack)
				a = cpu.pop(p[cpu.pc + 1], cpu.stack)
				if fn == 0 then
					c = a == b
				elseif fn == 1 then
					c = a ~= b
				elseif fn == 2 then
					c = toSigned(a) > toSigned(b)
				elseif fn == 3 then
					c = toSigned(a) < toSigned(b)
				elseif fn == 4 then
					c = toSigned(a) >= toSigned(b)
				elseif fn == 5 then
					c = toSigned(a) <= toSigned(b)
				elseif fn == 6 then
					c = a > b
				elseif fn == 7 then
					c = a < b
				elseif fn == 8 then
					c = a >= b
				elseif fn == 9 then
					c = a <= b
				end
				if c then
					cpu.push(p[cpu.pc + 1], cpu.stack, 0xffffff, 0x40000)
				else
					cpu.push(p[cpu.pc + 1], cpu.stack, 0, 0x40000)
				end
			-- Jump.
			elseif instr == 10 then
				cpu.pc = addr - 1
			-- Conditional jump.
			elseif instr == 11 then
				a = cpu.pop(p[cpu.pc + 1], cpu.stack)
				if a ~= 0 then
					cpu.pc = addr - 1
				else
					cpu.pc = cpu.pc + 3
				end
			-- Iterator jump.
			elseif instr == 12 then
				a = cpu.pop(p[cpu.pc + 1], cpu.iterStack)
				b = cpu.pop(p[cpu.pc + 1], cpu.iterStack)
				if a == b then
					cpu.pc = addr - 1
				else
					cpu.push(p[cpu.pc + 1], cpu.iterStack, b, 0x100)
					cpu.push(p[cpu.pc + 1], cpu.iterStack, a, 0x100)
					cpu.pc = cpu.pc + 3
				end
			-- Call.
			elseif instr == 13 then
				cpu.pc = cpu.pc + 3
				cpu.push(p[cpu.pc + 1], cpu.retStack, cpu.pc, 0x40000)
				cpu.pc = addr - 1
			-- Return.
			elseif instr == 14 then
				cpu.pc = cpu.pop(p[cpu.pc + 1], cpu.retStack)
			-- End this mess.
			elseif instr == 15 then
				cpu.running = false
			end
			::noop::
			cpu.pc = (cpu.pc + 1) & 0xfffffff
		end
	end
}

-- Reading an argument.
argv = {...}
if argv[1] == "--version" then
	print("FurStack Virtual Machine version 2\nCompatible with FurStack 0.3")
	os.exit()
elseif argv[1] == "--help" then
	print("FurStack Virtual Machine usage:\n./fsvm.lua [option] program")
	print("Options:\n--version - show version.\n--help - display this message.")
	os.exit()
end

-- Switching to alternative terminal buffer.
io.write("\27[?1049h")
if #argv == 0 then
	runtimeError("No program given.")
elseif not string.match(argv[1], "[/%w_%.]*[%w_]+%.hex") then
	runtimeError("Invalid program file.")
end

-- Reading program.
prg = io.open(argv[1], "r")
if prg == nil then
	runtimeError("File doesn't exists.")
end
code = prg.read(prg, "*all")
io.close(prg)

-- Executing it.
rom = convert(code)
mem.init()
while cpu.running do
	cpu.cycle(rom, mem)
end

-- End of program.
print("Press key to exit:")
nocurses.getkey()
io.write("\27[?1049l")
