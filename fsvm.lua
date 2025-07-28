#!/usr/bin/env lua
-- Nocurses, my beloved.
-- Note that nocurses works on Linux, Mac and Cygwin.
local nocurses = require("nocurses")

-- Le error.
function runtime_error(m)
	io.write("\27[?1049l")
	print("\27[91m" .. m .. "\27[0m")
	os.exit(1)
end

-- This takes the program and converts it to array full of numbers.
function convert(s)
	local t = {}
	local w = ""
	for i in string.gmatch(s, "(.)") do
		if i == "\n" or i == " " and w ~= "" and tonumber(w, 16) then
			table.insert(t, tonumber(w, 16))
			w = ""
		else
			w = w .. i
		end
	end
	return t
end

-- Reading program.
argv = {...}
debug_mode = false
-- Alternative terminal buffer, because why not.
io.write("\27[?1049h")
if #argv < 1 then
	runtime_error("No program given.")
end

-- It's not very useful, believe me.
if argv[2] ~= nil then
	if argv[2] == "--debug" then
		debug_mode = true
	end
end

if not string.match(argv[1], ".+%.hex") then
	compileError("Error! The input file is not a program.")
end
-- Actually reading the program.
pf = io.open(argv[1], "r")
if pf == nil then
	runtime_error("Error! Program doesn't exist.")
end
prg = pf.read(pf, "*all")
pf.close(pf)

rom = convert(prg)

-- Is this a waste of space? Probably.
for i = 1, 0x100000 - #rom, 1 do
	table.insert(rom, 0)
end

-- Yes, memory is it's own separate object. I could include rom in it but it's separate.
mem = {
	ram = {},
	term = "",
	-- This function is self explanatory.
	write = function(addr, d)
		if addr >= 0 and addr <= 0x7fff then
			mem.ram[addr + 1] = d
		elseif addr == 0x8000 then
			-- This is probably one of the worst implementations of terminal.
			if d == 8 then
				mem.term = string.sub(mem.term, 1, -2)
				nocurses.clrscr()
			else
				mem.term = mem.term .. utf8.char(d)
				nocurses.gotoxy(1, 1)
			end
			print(mem.term)
		elseif addr == 0x8001 then
			mem.term = ""
			nocurses.clrscr()
		end
	end,
	-- Same as above.
	read = function(addr)
		local d = 0
		local temp = ""
		if addr >= 0 and addr <= 0x7fff then
			d = mem.ram[addr + 1]
		elseif addr == 0x8002 then
			-- This is the main reason for nocurses being used.
			temp = nocurses.getkey(0.1)
			-- There is getch in no curses, but it requires fucking with it to achieve what I want.
			-- Something will probably break anyways.
			if temp ~= false and temp ~= nil then
				-- haha, fucking up Windows and MacOS users up go brrrr.
				if temp == "Enter" then
					d = 10
				elseif temp == "Tab" then
					d = 9
				elseif temp == "Backspace" then
					d = 8
				elseif temp == "Escape" then
					d = 27
				elseif temp == "Space" then
					d = 32
				elseif temp == "Delete" then
					d = 127
				else
					d = utf8.codepoint(temp)
				end
			else
				d = 0
			end
		end
		return d
	end
}

-- Could I done it in mem object? Yes.
-- Will I do it? idk.
for i = 1, 0x8000, 1 do
	table.insert(mem.ram, 0)
end

-- The cpu. :3
cpu = {
	running = true,
	-- The first stack is the actual stack on which you do shit.
	-- The second one is for return addresses stored in cal instruction(opcode 13)
	stack = {},
	ret_stack = {},
	-- The only reason I added those is lack of instruction to implement swap and rotate.
	regs = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
	pc = 0,
	-- Push and pop functions. I could just use table.insert and table.remove, but I wanted some error detection.
	push = function(s, v)
		table.insert(s, v)
		if #s > 4096 then
			runtime_error("Error! Stack overflow. PC: " .. cpu.pc)
		end
	end,
	pop = function(s)
		local v = 0
		if #s == 0 then
			runtime_error("Error! Stack underflow. PC: " .. cpu.pc)
		else
			local v = s[#s]
			table.remove(s)
			return v
		end
	end,
	-- The single clock cycle.
	cycle = function(p, m)
		local instr = 0
		local op = 0
		local f = 0
		local imm = 0
		local jaddr = 0
		local a = 0
		local b = 0
		local r = 0
		
		-- Fetch and decode.
		instr = p[cpu.pc + 1]
		op = instr >> 4
		f = instr & 0xf
		-- Most instruction take one byte of memory, but these take more.
		if op == 2 or op == 11 or op == 12 or op == 13 then
			instr = instr << 8
			instr = instr + p[cpu.pc + 2]
			instr = instr << 8
			instr = instr + p[cpu.pc + 3]
			imm = instr & 0xffff
			jaddr = instr & 0xfffff
		end

		-- Execute.
		-- Do absolute nothing.
		if op == 0 then
			-- People will probably look at me like at some war criminal for using goto.
			goto noop
		-- Math instruction.
		elseif op == 1 then
			b = cpu.pop(cpu.stack)
			a = cpu.pop(cpu.stack)
			-- Numbers on stack are stored in unsigned form and it needs to be converted for some instructions.
			if f < 9 and f ~= 3 and f ~= 5 then
				if a >> 15 == 1 then
					a = a - 0x10000
				end
				if b >> 15 == 1 then
					b = b - 0x10000
				end
			end
			if f == 0 then
				r = (a + b) & 0xffff
			elseif f == 1 then
				r = (a - b) & 0xffff
			elseif f == 2 or f == 3 then
				r = (a * b) & 0xffff
			elseif f == 4 or f == 5 then
				r = (a // b) & 0xffff
			elseif f == 6 then
				r = a % b
			-- Two fixed point math instructions. Only multiplication and division.
			-- The format of fixed point numbers is 00000000.00000000
			elseif f == 7 then
				r = ((a * b) >> 8) & 0xffff
			elseif f == 8 then
				r = ((a << 8) // b) & 0xffff
			-- Note that you need lua 5.3 for this to work.
			elseif f == 9 then
				r = a & b
			elseif f == 10 then
				r = a | b
			elseif f == 11 then
				r = a ~ b
			elseif f == 12 then
				r = ~(a | b) & 0xffff
			elseif f == 13 then
				r = (a << b) & 0xffff
			elseif f == 14 then
				r = a >> b
			elseif f == 15 then
				if a >> 15 == 1 then
					a = a - 0x10000
				end
				r = (a >> b) & 0xffff
			end
			cpu.push(cpu.stack, r)
		-- Push.
		elseif op == 2 then
			cpu.push(cpu.stack, imm)
			cpu.pc = cpu.pc + 2
		-- Pop.
		elseif op == 3 then
			-- That value is send to Brazil, aka is getting discarded.
			cpu.pop(cpu.stack)
		-- Push from register.
		elseif op == 4 then
			cpu.push(cpu.stack, cpu.regs[f + 1])
		-- Pop to register.
		elseif op == 5 then
			cpu.regs[f + 1] = cpu.pop(cpu.stack)
		-- Store.
		elseif op == 6 then
			b = cpu.pop(cpu.stack)
			a = cpu.pop(cpu.stack)
			m.write(a, b)
		-- Load.
		elseif op == 7 then
			a = cpu.pop(cpu.stack)
			r = m.read(a)
			cpu.push(cpu.stack, r)
		-- Duplicate top stack value.
		elseif op == 8 then
			a = cpu.stack[#cpu.stack]
			cpu.push(cpu.stack, a)
		-- Same as above, but with the value below.
		elseif op == 9  then
			a = cpu.stack[#cpu.stack - 1]
			cpu.push(cpu.stack, a)
		-- Comparison instruction.
		elseif op == 10 then
			b = cpu.pop(cpu.stack)
			a = cpu.pop(cpu.stack)
			-- Same as in math instruction.
			if f < 6 then
				if a >> 15 == 1 then
					a = a - 0x10000
				end
				if b >> 15 == 1 then
					b = b - 0x10000
				end
			end
			if f == 0 then
				r = a == b
			elseif f == 1 then
				r = a ~= b
			elseif f == 2 or f == 6 then
				r = a > b
			elseif f == 3 then
				r = a >= b
			elseif f == 4 or f == 7 then
				r = a < b
			elseif f == 5 then
				r = a <= b
			end
			if r then
				-- This could be anything.
				cpu.push(cpu.stack, 0xffff)
			else
				cpu.push(cpu.stack, 0)
			end
		-- Jump.
		elseif op == 11 then
			cpu.pc = jaddr - 1
		-- Conditiona jump.
		elseif op == 12 then
			a = cpu.pop(cpu.stack)
			if a ~= 0 then
				cpu.pc = jaddr - 1
			else
				cpu.pc = cpu.pc + 2
			end
		-- Call.
		elseif op == 13 then
			cpu.push(cpu.ret_stack, cpu.pc + 3)
			cpu.pc = jaddr - 1
		-- Return.
		elseif op == 14 then
			cpu.pc = cpu.pop(cpu.ret_stack)
			cpu.pc = cpu.pc - 1
		-- Exit.
		elseif op == 15 then
			cpu.running = false
		end
		::noop::
		-- Increment PC by 1 and make sure it can fit in 20 bits.
		cpu.pc = (cpu.pc + 1) & 0xfffff
	end
}

-- The main loop.
while cpu.running do
	cpu.cycle(rom, mem)
end

-- I did that only to see results.
print("Press key to exit:")
nocurses.getkey()
io.write("\27[?1049l")

-- This prints first 4096 ram addresses. Not very useful.
if debug_mode then
	for i = 1, 0x100, 1 do
		io.write(string.format("%x", (i - 1) << 4))
		for j = 1, 0x10, 1 do
			io.write("\t" .. string.format("%x", mem.ram[((i - 1) << 4) + j]))
		end
		io.write("\n")
	end
end
