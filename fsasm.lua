#!/usr/bin/env lua
-- Warning, this assembler is shit. Like, unironically it sucks.
-- Fuction that splits program into lines, and lines into words. This probably explains itself.
function line_split(s, c)
	local t = {{}}
	local p = 1
	local w = ""
	for i in string.gmatch(s, "(.)") do
		-- MacOs and Windows users are not going to have a fun time figuing out why assembler doesn't properly work.
		if i == "\n" then
			table.insert(t[p], w)
			table.insert(t, {})
			w = ""
			p = p + 1
		elseif i == c and w ~= "" then
			table.insert(t[p], w)
			w = ""
		else
			w = w .. i
		end
	end
	if w ~= "" then
		table.insert(t[p], w)
	end
	return t
end

-- There is error command in lua, but I want more control over it.
function diserror(m)
	print("\27[91m" .. m .. "\27[0m")
	os.exit()
end

-- Is it good? No.
-- Is it better than the previous thing? Yes.
argv = {...}
pit = 1
prg_file = ""
sav_file = ""
if #argv == 0 or argv[1] == "--help" then
	diserror("Usage:\n./fsasm.lua [params]\n--help - this message.\n--version - display version.\n-i - input file.\n-o - output file.")
end

while pit <= #argv do
	if argv[pit] == "--version" then
		diserror("FurStack Assembled version 1\nWorks with FurStack v0.1 and FurStack v0.2")
	elseif argv[pit] == "-i" then
		if prg_file == "" then
			if argv[pit + 1] ~= nil and argv[pit + 1] ~= "-o" then
				prg_file = argv[pit + 1]
				pit = pit + 1
			else
				diserror("Error! Input file not given.")
			end
		else
			diserror("Error! There can be only one file given to assemble.")
		end
	elseif argv[pit] == "-o" then
		if sav_file == "" then
			if argv[pit + 1] ~= nil and argv[pit + 1] ~= "-i" then
				sav_file = argv[pit + 1]
				pit = pit + 1
			else
				diserror("Error! Output file not given.")
			end
		else
			diserror("Error! Output file is already given.")
		end
	else
		diserror("Error! Unknown parameter.")
	end
	pit = pit + 1
end

if prg_file == "" then
	diserror("Error! No file given.")
elseif sav_file == "" then
	sav_file = string.gsub(prg_file, "%.s", "%.hex")
end

if not string.match(prg_file, ".+%.s") then
	compileError("Error! The input file is not a assembly program.")
end

-- All the tables with opcodes, functions and registers. You can probably tell what is what by names of tables.
opcodes = {
	["noop"] = 0,
	["add"] = 1,
	["sub"] = 1,
	["mul"] = 1,
	["mulu"] = 1,
	["div"] = 1,
	["divu"] = 1,
	["mod"] = 1,
	["fmul"] = 1,
	["fdiv"] = 1,
	["and"] = 1,
	["or"] = 1,
	["xor"] = 1,
	["nor"] = 1,
	["sll"] = 1,
	["srl"] = 1,
	["sra"] = 1,
	["push"] = 2,
	["drop"] = 3,
	["pur"] = 4,
	["por"] = 5,
	["sw"] = 6,
	["lw"] = 7,
	["dup"] = 8,
	["over"] = 9,
	["eq"] = 10,
	["ne"] = 10,
	["gt"] = 10,
	["ge"] = 10,
	["lt"] = 10,
	["le"] = 10,
	["gtu"] = 10,
	["ltu"] = 10,
	["j"] = 11,
	["jc"] = 12,
	["cal"] = 13,
	["ret"] = 14,
	["exit"] = 15
}
alufn = {
	["add"] = 0,
	["sub"] = 1,
	["mul"] = 2,
	["mulu"] = 3,
	["div"] = 4,
	["divu"] = 5,
	["mod"] = 6,
	["fmul"] = 7,
	["fdiv"] = 8,
	["and"] = 9,
	["or"] = 10,
	["xor"] = 11,
	["nor"] = 12,
	["sll"] = 13,
	["srl"] = 14,
	["sra"] = 15
}
cmpfn = {
	["eq"] = 0,
	["ne"] = 1,
	["gt"] = 2,
	["ge"] = 3,
	["lt"] = 4,
	["le"] = 5,
	["gtu"] = 6,
	["ltu"] = 7
}
regs = {
	["reg0"] = 0,
	["reg1"] = 1,
	["reg2"] = 2,
	["reg3"] = 3,
	["reg4"] = 4,
	["reg5"] = 5,
	["reg6"] = 6,
	["reg7"] = 7,
	["Reg8"] = 8,
	["reg9"] = 9,
	["reg10"] = 10,
	["reg11"] = 11,
	["reg12"] = 12,
	["reg13"] = 13,
	["reg14"] = 14,
	["reg15"] = 15
}

-- Getting the file.
pf = io.open(prg_file, "r")
if pf == nil then
	diserror("Error! File doesn't exists.")
end
prg = pf.read(pf, "*all")
pf.close(pf)

lns = line_split(prg, " ")

labels = {}
defs = {}
instr = {}
addr = 0

-- Haha, mess go brrr.
-- This figures out what is comment, definition, label or instruction.
for i = 1, #lns, 1 do
	-- Comment.
	if lns[i][1] == "" or lns[i][1] == "rem" or lns[i][1] == nil then
		-- Haha, goto go brrrrrrrr.
		goto continue
	-- Definition.
	elseif lns[i][1] == "def" then
		if defs[lns[i][2]] then
			diserror("Error! Constant override in line " .. i)
		elseif not tonumber(lns[i][3]) then
			diserror("Error! Invalid number in line " .. i)
		elseif math.type(tonumber(lns[i][3])) == "float" then
			if tonumber(lns[i][3]) > 127.996 or tonumber(lns[i][3]) < -128 then
				diserror("Error! Invalid float in line " .. i)
			else
				defs[lns[i][2]] = math.floor(tonumber(lns[i][3]) * 256) & 0xffff
			end
		elseif tonumber(lns[i][3]) > 0xffff and tonumber(lns[i][3]) < -0x8000 then
			diserror("Error! Invalid number in line " .. i)
		else
			defs[lns[i][2]] = tonumber(lns[i][3]) & 0xffff
		end
	-- Label.
	elseif lns[i][1] == "deflab" then
		if labels[lns[i][2]] then
			diserror("Error! Label override in line " .. i)
		else
			labels[lns[i][2]] = addr
		end
	-- Instruction.
	elseif opcodes[lns[i][1]] then
		if lns[i][1] == "push" or lns[i][1] == "j" or lns[i][1] == "jc" or lns[i][1] == "cal" then
			addr = addr + 3
		else
			addr = addr + 1
		end
		table.insert(instr, i)
	else
		diserror("Error! Invalid opcode in line " .. i)
	end
	::continue::
end

-- VM has 20-bit program counter which can access 1MB of program memory.
if addr > 0xfffff then
	diserror("Error! Program is too big for 1MB of program memory.")
end

assembled = {}
prg_byte = 0

-- Even more mess.
-- This actually assembles the assembly code.
for i = 1, #instr, 1 do
	-- Some of the instructions are assembled by just one line of code. Yes, they that short.
	prg_byte = (opcodes[lns[instr[i]][1]]) << 4
	-- Arithmetic and logic instruction.
	if prg_byte == 0x10 then
		prg_byte = prg_byte + alufn[lns[instr[i]][1]]
	-- Push instruction. And yes, instruction lenght is not constant.
	elseif prg_byte == 0x20 then
		table.insert(assembled, prg_byte)
		-- Integer, float or definition?
		if defs[lns[instr[i]][2]] then
			prg_byte = (defs[lns[instr[i]][2]]) >> 8
			table.insert(assembled, prg_byte)
			prg_byte = defs[lns[instr[i]][2]] & 0xff
		elseif not tonumber(lns[instr[i]][2]) then
			diserror("Error! Invalid number in line " .. instr[i])
		elseif math.type(tonumber(lns[instr[i]][2])) == "float" then
			if tonumber(lns[instr[i]][2]) > 127.996 or tonumber(lns[instr[i]][2]) < -128 then
				diserror("Error! Invalid float in line " .. instr[i])
			else
				prg_byte = math.floor(tonumber(lns[instr[i]][2])) & 0xff
				table.insert(assembled, prg_byte)
				prg_byte = (math.floor(tonumber(lns[instr[i]][2]) * 256)) & 0xff
			end
		elseif tonumber(lns[instr[i]][2]) > 0xffff and tonumber(lns[instr[i]][2]) < -0x8000 then
			diserror("Error! Invalid number in line " .. instr[i])
		else
			prg_byte = (tonumber(lns[instr[i]][2]) >> 8) & 0xff
			table.insert(assembled, prg_byte)
			prg_byte = tonumber(lns[instr[i]][2]) & 0xff
		end
	-- The instructions for manipulating the registers.
	elseif prg_byte == 0x40 or prg_byte == 0x50 then
		if regs[lns[instr[i]][2]] then
			prg_byte = prg_byte + regs[lns[instr[i]][2]]
		else
			diserror("Error! Invalid register in line " .. instr[i])
		end
	-- Comparing instruction.
	elseif prg_byte == 0xa0 then
		prg_byte = prg_byte + cmpfn[lns[instr[i]][1]]
	-- Jumping instructions. jump, conditional jump and call.
	elseif prg_byte == 0xb0 or prg_byte == 0xc0 or prg_byte == 0xd0 then
		if labels[lns[instr[i]][2]] then
			prg_byte = prg_byte + (labels[lns[instr[i]][2]] >> 16)
			table.insert(assembled, prg_byte)
			prg_byte = ((labels[lns[instr[i]][2]]) >> 8) & 0xff
			table.insert(assembled, prg_byte)
			prg_byte = labels[lns[instr[i]][2]] & 0xff
		elseif not tonumber(lns[instr[i]][2]) then
			diserror("Error! Invalid address in line " .. instr[i])
		elseif math.type(tonumber(lns[instr[i]][2])) == "float" then
			diserror("Error! Float given as address in line " .. instr[i])
		elseif tonumber(lns[instr[i]][2]) > 0xfffff and tonumber(lns[instr[i]][2]) < 0x0 then
			diserror("Error! Invalid address in line " .. instr[i])
		else
			prg_byte = prg_byte + (tonumber(lns[instr[i]][2]) >> 16)
			table.insert(assembled, prg_byte)
			prg_byte = (tonumber(lns[instr[i]][2]) >> 8) & 0xff
			table.insert(assembled, prg_byte)
			prg_byte = tonumber(lns[instr[i]][2]) & 0xff
		end
	end
	table.insert(assembled, prg_byte)
end

-- This is the part where this abomination of assembly code is stored.
-- If you wonder why it's stored like this, just know that I wanted to use it with circuit simulator.
-- I might change it later.
sf = io.open(sav_file, "w")
sf.write(sf, "v2.0 raw\n")
for i = 1, #assembled, 1 do
	sf.write(sf, string.format("%x", assembled[i]) .. "\n")
end
sf.close(sf)
print("File assembled! Program memory taken is " .. #assembled .. "B")
