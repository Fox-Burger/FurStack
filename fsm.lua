#!/usr/bin/env luajit
-- FurStack Assembler.
require("common")
local bit = require("bit")

-- Split string into table of lines. Lines are split into table of words.
function line_split(s, c)
	local tab = {{}}
	local line = 1
	local word = ""
	for i in string.gmatch(s, "(.)") do
		-- Windows users will for sure get fucked by it.
		if i == "\n" or i == "\r" then
			checkInsert(tab[line], word)
			table.insert(tab, {})
			word = ""
			line = line + 1
		elseif string.match(i, c) then
			checkInsert(tab[line], word)
			word = ""
		else
			word = word .. i
		end
	end
	checkInsert(tab[line], word)
	return tab
end

-- Checks for labels, definitions and lines with instructions.
function process(p)
	local labs = {}
	local defs = {}
	local toAsm = {}
	local addr = 0
	for i = 1, #p do
		-- Is it comment, definition, label or instructio?
		if #p[i] == 0 or p[i][1] == "rem" then
			goto continue
		elseif p[i][1] == "def" then
			if defs[p[i][2]] then
				disError("Definition defined again in line " .. i)
			elseif isFloat(p[i][3]) and isValNum(p[i][3], -0x800.000, 0x7ff.fff) then
				defs[p[i][2]] = math.floor(tonumber(p[i][3]) * 0x1000)
			elseif not isFloat(p[i][3]) and isValNum(p[i][3], -0x800000, 0xffffff) then
				defs[p[i][2]] = tonumber(p[i][3])
			else
				disError("Invalid value for definition in line " .. i)
			end
		elseif p[i][1] == "deflab" then
			if labs[p[i][2]] then
				disError("Defining label again in line " .. i)
			else
				labs[p[i][2]] = addr
			end
		elseif opcode[p[i][1]] then
			if opcode[p[i][1]] == 2 or opcode[p[i][1]] >= 10 and opcode[p[i][1]] <= 13 then
				addr = addr + 4
			else
				addr = addr + 1
			end
			table.insert(toAsm, i)
		else
			disError("Invalid opcode in line " .. i)
		end
		::continue::
	end
	if addr > 0xfffffff then
		disError("Program is to big for 256 MB")
	end
	return labs, defs, toAsm
end

-- The part that assembles this mess.
function assemble(c, lab, def, lin)
	local tab = {}
	local b = 0
	local operand = 0
	for i = 1, #lin do
		b = bit.lshift(opcode[c[lin[i]][1]], 4)
		if b == 0x10 or b == 0x30 or b == 0x90 then
			b = b + fn[c[lin[i]][1]]
		-- Some instructions take 4 bytes.
		elseif b == 0x20 then
			if def[c[lin[i]][2]] then
				operand = def[c[lin[i]][2]]
			elseif isFloat(c[lin[i]][2]) and isValNum(c[lin[i]][2], -0x800.000, 0x7ff.fff) then
				operand = math.floor(tonumber(c[lin[i]][2] * 0x1000))
			elseif not isFloat(c[lin[i]][2]) and isValNum(c[lin[i]][2], -0x800000, 0xffffff) then
				operand = tonumber(c[lin[i]][2])
			else
				disError("Invalid value in line " .. lin[i])
			end
			table.insert(tab, b)
			b = bit.rshift(bit.band(operand, 0xff0000), 16)
			table.insert(tab, b)
			b = bit.rshift(bit.band(operand, 0xff00), 8)
			table.insert(tab, b)
			b = bit.band(operand, 0xff)
		elseif b >= 0xa0 and b <= 0xd0 then
			if lab[c[lin[i]][2]] then
				operand = lab[c[lin[i]][2]]
			elseif not isFloat(c[lin[i]][2]) and isValNum(c[lin[i]][2], 0x0, 0xffffff) then
				operand = tonumber(c[lin[i]][2])
			else
				disError("Invalid address in line " .. lin[i])
			end
			table.insert(tab, b)
			b = bit.rshift(bit.band(operand, 0xff0000), 16)
			table.insert(tab, b)
			b = bit.rshift(bit.band(operand, 0xff00), 8)
			table.insert(tab, b)
			b = bit.band(operand, 0xff)
		end
		table.insert(tab, b)
	end
	return tab
end

argv = {...}
pit = 1
prgFile = ""
savFile = ""
temp0 = ""

-- Opcodes and functions.
opcode = {
	noop = 0,
	add = 1,
	sub = 1,
	mul = 1, 
	umul = 1,
	fmul = 1,
	div = 1,
	udiv = 1,
	fdiv = 1,
	mod = 1,
	["and"] = 1,
	["or"] = 1,
	xor = 1,
	nor = 1,
	sll = 1,
	srl = 1,
	sra = 1,
	push = 2,
	drop = 3,
	dup = 3,
	over = 3,
	tuck = 3,
	nip = 3,
	swap = 3,
	rot = 3,
	crot = 3,
	sw = 4,
	lw = 5,
	itp = 6,
	itc = 7,
	itd = 8,
	eq = 9,
	ne = 9,
	gt = 9,
	lt = 9,
	ge = 9,
	le = 9,
	ugt = 9,
	ult = 9,
	uge = 9,
	ule = 9,
	j = 10,
	jc = 11,
	jt = 12,
	cal = 13,
	ret = 14,
	["exit"] = 15
}

fn = {
	add = 0,
	sub = 1,
	mul = 2,
	umul = 3,
	fmul = 4,
	div = 5,
	udiv = 6,
	fdiv = 7,
	mod = 8,
	["and"] = 9,
	["or"] = 10,
	xor = 11,
	nor = 12,
	sll = 13,
	srl = 14,
	sra = 15,
	drop = 0,
	dup = 1,
	over = 2,
	tuck = 3,
	nip = 4,
	swap = 5,
	rot = 6,
	crot = 7,
	eq = 0,
	ne = 1,
	gt = 2,
	lt = 3,
	ge = 4,
	le = 5,
	ugt = 6,
	ult = 7,
	uge = 8,
	ule = 9
}

-- Parse the arguments.
while pit <= #argv do
	if argv[pit] == "--version" then
		print("FurStack Assembler version 2\nCompatible with FurStack version 0.3")
		os.exit()
	elseif argv[pit] == "--help" then
		print("FurStack Assembler usage:\n./fsm.lua [options]")
		print("Options:\n--version - display version.\n--help - display this message.\n-i - input file.\n-o - output file.")
		os.exit()
	elseif argv[pit] == "-i" then
		if prgFile ~= "" then
			disError("You already defined input file.")
		elseif argv[pit + 1] ~= nil and string.match(argv[pit + 1], "[/%w_%.]*[%w_]+%.s") then
			prgFile = argv[pit + 1]
			pit = pit + 1
		else
			disError("Invalid parameter given.")
		end
	elseif argv[pit] == "-o" then
		if savFile ~= "" then
			disError("You already defined output file.")
		elseif argv[pit + 1] ~= nil and string.match(argv[pit + 1], "[/%w_%.]*[%w_]+%.hex") then
			savFile = argv[pit + 1]
			pit = pit + 1
		else
			disError("Invalid parameter given.")
		end
	else
		disError("Invalid option.")
	end
	pit = pit + 1
end

if prgFile == "" then
	disError("Input file not given.")
elseif savFile == "" then
	temp0 = string.sub(prgFile, 1, -2)
	savFile = temp0 .. "hex"
end

-- Opening file.
prg = io.open(prgFile, "r")
if prg == nil then
	disError("File doesn't exists.")
end
code = prg.read(prg, "*all")
io.close(prg)

-- The thing.
splited = line_split(code, "%s")
labels, definitions, toAssemble = process(splited)
assembled = assemble(splited, labels, definitions, toAssemble)

-- Saving the assembled file.
sav = io.open(savFile, "w")
for i = 1, #assembled, 1 do
	sav.write(sav, string.char(assembled[i]))
end
io.close(sav)

print("File successfully assembled.")
