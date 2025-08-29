#!/usr/bin/env lua
require("common")

-- Splits the source code.
function tokenize(s, f)
	local tab = {}
	local lin = {1}
	local strMod = false
	local escCod = false
	local isMac = false
	local word = ""
	local ln = 1
	-- All supported escape sequences.
	local codes = {
		["0"] = "\0",
		b = "\b",
		t = "\t",
		n = "\n",
		r = "\r",
		e = "\27",
		["\\"] = "\\",
		["\""] = "\"",
		["'"] = "\'"
	}
	for i in string.gmatch(s, "(.)") do
		-- Is it string?
		if strMod then
			if escCod then
				if codes[i] then
					word = word .. codes[i]
					escCod = false
				else
					disError("Invalid escape sequence in line " .. ln .. " inside " .. f)
				end
			elseif i == "\\" then
				escCod = true
			else
				if i == "\"" then
					word = word .. "\""
					strMod = false
				elseif i == "\n" or i == "\r" then
					disError("Unclosed string in line " .. ln .. " inside " .. f)
				else
					word = word .. i
				end
			end
		-- Everything else.
		else
			if string.match(i, "%s") then
				checkInsert(tab, word)
				if i == "\n" or i == "\r" then
					isMac = i == "\r"
					table.insert(lin, #tab)
					ln = ln + 1
				end
				word = ""
			elseif i == "\"" then
				word = "\""
				strMod = true
			else
				word = word .. i
			end
		end
	end
	checkInsert(tab, word)
	return tab, lin, isMac
end

-- After the tokenize function our source code no longer has line. It's now a list of words.
function getLn(v, l)
	local lin = 0
	for i = 1, #l do
		if v >= l[i] then
			lin = l[i]
		else
			break
		end
	end
	return lin
end

-- Is it inside the table.
function isIn(t, v)
	local found = false
	for i = 1, #t do
		if t[i] == v then
			found = true
		end
	end
	return found
end

-- Combine two tables.
function concatTab(t1, t2)
	for i = 1, #t2 do
		table.insert(t1, t2[i])
	end
end

-- Very shitty error check.
function errorCheck(t, l, f)
	local tab = {}
	local fns = {}
	local vars = {}
	local ifStack = {}
	local whileStack = {}
	local repeatStack = {}
	local forStack = {}
	-- All supported words.
	local words = {"include", "fn", "endfn", "rem", "endrem", "let", "const", "array", "set", "fetch", "true", "false", "if", "else", "then", "while", "do",
	"endwhile", "repeat", "until", "loop", "for", "bye", "put", "cls", "getin", "utime", "rand",
	"+", "-", "*", "u*", "fmul", "/", "u/", "fdiv", "%", "&", "|", "~", "!", "<<", ">>", ">>>", "=", "~=", ">", "<", ">=", "<=", "u>", "u<", "u>=", "u<=",
	"dup", "over", "tuck", "swap", "rot", "crot", "drop", "nip", ">i", "i@", "i>"}
	local iter = 1
	local temp1 = ""
	local temp2 = ""
	local temp3 = ""
	local temp4 = {}
	local temp5 = {}
	local temp6 = {}
	local temp7 = {}
	local temp8 = {}
	local com = false
	local inFn = false
	while iter <= #t do
		-- Is it comment?
		if com then
			if t[iter] == "endrem" then
				com = false
			end
		-- Is it a word.
		elseif isIn(words, t[iter]) then
			if t[iter] == "include" then
				iter = iter + 1
				temp1 = string.gsub(f, "[%w_]+%.fu", t[iter])
				if not isIn(files, temp1) then
					temp2 = io.open(temp1, "r")
					if temp2 == nil then
						disError("File described in line " .. getLn(iter, l) .. " inside " .. f .. " doesn't exists.")
					end
					temp3 = temp2.read(temp2, "*all")
					io.close(temp2)
					temp4, temp5 = tokenize(temp3, temp1)
					temp6, temp7, temp8 = errorCheck(temp4, temp5, temp1)
					concatTab(tab, temp6)
					concatTab(vars, temp7)
					concatTab(fns, temp8)
				end
			elseif t[iter] == "fn" then
				table.insert(tab, t[iter])
				iter = iter + 1
				if isIn(fns, t[iter]) then
					disError("Function " .. t[iter] .. " is being defined again in line " .. getLn(iter, l) .. " inside " .. f)
				elseif inFn then
					disError("Trying to define function inside function in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(fns, t[iter])
					table.insert(tab, t[iter])
					inFn = true
				end
			elseif t[iter] == "endfn" then
				if not inFn then
					disError("endfn word appeared before fn word in line " .. getLn(iter, l) .. " inside " .. f)
				else
					inFn = false
					table.insert(tab, t[iter])
				end
			elseif t[iter] == "rem" then
				com = true
			elseif t[iter] == "let" then
				table.insert(tab, t[iter])
				iter = iter + 1
				if isIn(vars, t[iter]) then
					disError("Trying to declare variable again in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(vars, t[iter])
					table.insert(tab, t[iter])
				end
			elseif t[iter] == "const" then
				table.insert(tab, t[iter])
				iter = iter + 1
				if isIn(vars, t[iter]) then
					disError("Trying to declare constant again in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(vars, t[iter])
					table.insert(tab, t[iter])
					iter = iter + 1
					if (tonumber(t[iter]) and string.match(t[iter], "-?(0[bodx])?%x+") and isValNum(tonumber(t[iter]), -0x800000, 0xffffff)) or
					(tonumber(t[iter]) and string.match(t[iter], "-?(0[bodx])?%x*%.%x+") and isValNum(tonumber(t[iter]), -0x800.000, 0xfff.fff)) or
					string.match(t[iter], "\".\"") or t[iter] == "true" or t[iter] == "false" then
						table.insert(tab, t[iter])
					else
						disError("Invalid value for constant in line " .. getLn(iter, l) .. " inside " .. f)
					end
				end
			elseif t[iter] == "array" then
				table.insert(tab, t[iter])
				iter = iter + 1
				if isIn(vars, t[iter]) then
					disError("Trying to declare array again in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(vars, t[iter])
					table.insert(tab, t[iter])
					iter = iter + 1
					if tonumber(t[iter]) and isValNum(tonumber(t[iter]), 0x1, 0x7fffff) then
						table.insert(tab, t[iter])
					else
						disError("Invalid ammount of cells for array in line " .. getLn(iter, l) .. " inside " .. f)
					end
				end
			elseif t[iter] == "if" then
				table.insert(tab, t[iter])
				table.insert(ifStack, iter)
			elseif t[iter] == "else" then
				if #ifStack == 0 then
					disError("else word before if word in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(tab, t[iter])
				end
			elseif t[iter] == "then" then
				if #ifStack == 0 then
					disError("then word before if word in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(tab, t[iter])
					table.remove(ifStack)
				end
			elseif t[iter] == "while" then
				table.insert(tab, t[iter])
				table.insert(whileStack, {iter, 0})
			elseif t[iter] == "do" then
				if #whileStack == 0 then
					disError("do word before while word in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(tab, t[iter])
					whileStack[#whileStack][2] = iter
				end
			elseif t[iter] == "endwhile" then
				if #whileStack == 0 then
					disError("endwhile word before while word in line " .. getLn(iter, l) .. " inside " .. f)
				elseif whileStack[#whileStack][2] == 0 then
					disError("endwhile word before do word in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(tab, t[iter])
					table.remove(whileStack)
				end
			elseif t[iter] == "repeat" then
				table.insert(tab, t[iter])
				table.insert(repeatStack, iter)
			elseif t[iter] == "until" then
				if #repeatStack == 0 then
					disError("until word before repeat word in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(tab, t[iter])
					table.remove(repeatStack)
				end
			elseif t[iter] == "loop" then
				table.insert(tab, t[iter])
				table.insert(forStack, iter)
			elseif t[iter] == "for" then
				if #forStack == 0 then
					disError("for word before loop word in line " .. getLn(iter, l) .. " inside " .. f)
				else
					table.insert(tab, t[iter])
					table.remove(forStack)
				end
			else
				table.insert(tab, t[iter])
			end
		-- Is it a number, string, variable name or function name?
		else
			if not (tonumber(t[iter]) and math.type(tonumber(t[iter])) == "integer" and isValNum(tonumber(t[iter]), -0x800000, 0xffffff)) and
			not (tonumber(t[iter]) and math.type(tonumber(t[iter])) == "float" and isValNum(tonumber(t[iter]), -0x800.000, 0x7ff.fff)) and
			not isIn(fns, t[iter]) and not isIn(vars, t[iter]) and not string.match(t[iter], "\".*\"") then
				disError("Invalid word in line " .. getLn(iter, l) .. " inside " .. f)
			else
				table.insert(tab, t[iter])
			end
		end
		iter = iter + 1
	end
	-- You forgot something.
	if #ifStack > 0 then
		disError("There is one unclosed if statement inside " .. f)
	elseif #whileStack > 0 then
		disError("There is one unclosed while loop inside " .. f)
	elseif #repeatStack > 0 then
		disError("There is one unclosed repeat until loop inside " .. f)
	elseif #forStack > 0 then
		disError("There is one unclosed for loop inside " .. f)
	end
	return tab, vars, fns
end

-- The function that compiles the program you given.
function compile(c, t, s, m)
	local sf = io.open(s, "w")
	local nl = ""
	local iter = 1
	local temp1 = ""
	local temp2 = {}
	local temp3 = ""
	local temp4 = 0
	local varAddr = 0
	local vars = {}
	local fns = {}
	local ifCount = 0
	local ifStack = {}
	local whileCount = 0
	local whileStack = {}
	local repeatCount = 0
	local repeatStack = {}
	local forCount = 0
	local forStack = {}
	-- Windows users are not going to have a good time figuring out why it doesn't work.
	if m then
		nl = "\r"
	else
		nl = "\n"
	end
	-- Yes, I plan to add option to compile to something else than assembly for fsvm.
	-- A stuff that will be included in every compiled FurStack program.
	if t == "fsvm" then
		sf.write(sf, "cal main" .. nl)
		sf.write(sf, "exit" .. nl)
		sf.write(sf, nl)
	end
	-- All the words to be compiled.
	while iter <= #c do
		-- FurStack virtual machine.
		if t == "fsvm" then
			if string.match(c[iter], "\".+\"") then
				temp1 = string.sub(c[iter], 2, -2)
				for _, i in utf8.codes(temp1) do
					table.insert(temp2, i)
				end
				while #temp2 > 0 do
					sf.write(sf, "\tpush " .. temp2[#temp2] .. nl)
					table.remove(temp2)
				end
			elseif tonumber(c[iter]) then
				sf.write(sf, "\tpush " .. c[iter] .. nl)
			elseif c[iter] == "fn" then
				iter = iter + 1
				table.insert(fns, c[iter])
				sf.write(sf, "deflab " .. c[iter] .. nl)
			elseif c[iter] == "endfn" then
				sf.write(sf, "\tret" .. nl)
				sf.write(sf, nl)
			elseif isIn(fns, c[iter]) then
				sf.write(sf, "\tcal " .. c[iter] .. nl)
			elseif c[iter] == "let" then
				iter = iter + 1
				sf.write(sf, "def " .. c[iter] .. " " .. varAddr .. nl)
				varAddr = varAddr + 1
				table.insert(vars, c[iter])
			elseif c[iter] == "const" then
				iter = iter + 1
				table.insert(vars, c[iter])
				temp1 = c[iter]
				iter = iter + 1
				if tonumber(c[iter]) then
					temp4 = tonumber(c[iter])
				elseif string.match(c[iter], "\".\"") then
					temp3 = string.sub(c[iter], 2, -2)
					temp4 = utf8.codepoint(temp3)
				elseif c[iter] == "true" then
					temp4 = -1
				elseif c[iter] == "false" then
					temp4 = 0
				end
				sf.write(sf, "def " .. temp1 .. " " .. temp4 .. nl)
			elseif c[iter] == "array" then
				iter = iter + 1
				sf.write(sf, "def " .. c[iter] .. " " .. varAddr .. nl)
				table.insert(vars, c[iter])
				iter = iter + 1
				varAddr = varAddr + tonumber(c[iter])
			elseif isIn(vars, c[iter]) then
				sf.write(sf, "\tpush " .. c[iter] .. nl)
			elseif c[iter] == "set" then
				sf.write(sf, "\tsw" .. nl)
			elseif c[iter] == "fetch" then
				sf.write(sf, "\tlw" .. nl)
			elseif c[iter] == "true" then
				sf.write(sf, "\tpush -1" .. nl)
			elseif c[iter] == "false" then
				sf.write(sf, "\tpush 0" .. nl)
			elseif c[iter] == "if" then
				sf.write(sf, "\tjc if" .. ifCount .. nl)
				sf.write(sf, "\tj else" .. ifCount .. nl)
				sf.write(sf, nl)
				sf.write(sf, "deflab if" .. ifCount .. nl)
				table.insert(ifStack, {ifCount, false})
				ifCount = ifCount + 1
			elseif c[iter] == "else" then
				sf.write(sf, "\tj then" .. ifStack[#ifStack][1] .. nl)
				sf.write(sf, nl)
				sf.write(sf, "deflab else" .. ifStack[#ifStack][1] .. nl)
				ifStack[#ifStack][2] = true
			elseif c[iter] == "then" then
				sf.write(sf, nl)
				if ifStack[#ifStack][2] then
					sf.write(sf, "deflab then" .. ifStack[#ifStack][1] .. nl)
				else
					sf.write(sf, "deflab else" .. ifStack[#ifStack][1] .. nl)
				end
				table.remove(ifStack)
			elseif c[iter] == "while" then
				sf.write(sf, nl)
				sf.write(sf, "deflab while" .. whileCount .. nl)
				table.insert(whileStack, whileCount)
				whileCount = whileCount + 1
			elseif c[iter] == "do" then
				sf.write(sf, "\tjc do" .. whileStack[#whileStack] .. nl)
				sf.write(sf, "\tj endwhile" .. whileStack[#whileStack] .. nl)
				sf.write(sf, nl)
				sf.write(sf, "deflab do" .. whileStack[#whileStack] .. nl)
			elseif c[iter] == "endwhile" then
				sf.write(sf, "\tj while" .. whileStack[#whileStack] .. nl)
				sf.write(sf, nl)
				sf.write(sf, "deflab endwhile" .. whileStack[#whileStack] .. nl)
				table.remove(whileStack)
			elseif c[iter] == "repeat" then
				sf.write(sf, nl)
				sf.write(sf, "deflab repeat" .. repeatCount .. nl)
				table.insert(repeatStack, repeatCount)
				repeatCount = repeatCount + 1
			elseif c[iter] == "until" then
				sf.write(sf, "\tjc repeat" .. repeatStack[#repeatStack] .. nl)
				table.remove(repeatStack)
			elseif c[iter] == "loop" then
				sf.write(sf, "\tover" .. nl)
				sf.write(sf, "\tadd" .. nl)
				sf.write(sf, "\titp" .. nl)
				sf.write(sf, "\titp" .. nl)
				sf.write(sf, nl)
				sf.write(sf, "deflab loop" .. forCount .. nl)
				sf.write(sf, "\tjt for" .. forCount .. nl)
				table.insert(forStack, forCount)
				forCount = forCount + 1
			elseif c[iter] == "for" then
				sf.write(sf, "\titd" .. nl)
				sf.write(sf, "\tpush 1" .. nl)
				sf.write(sf, "\tadd" .. nl)
				sf.write(sf, "\titp" .. nl)
				sf.write(sf, "\tj loop" .. forStack[#forStack] .. nl)
				sf.write(sf, nl)
				sf.write(sf, "deflab for" .. forStack[#forStack] .. nl)
				table.remove(forStack)
			elseif c[iter] == "bye" then
				sf.write(sf, "\texit" .. nl)
			elseif c[iter] == "put" then
				sf.write(sf, "\tpush 0x800000" .. nl)
				sf.write(sf, "\tswap" .. nl)
				sf.write(sf, "\tsw" .. nl)
			elseif c[iter] == "cls" then
				sf.write(sf, "\tpush 0x800001" .. nl)
				sf.write(sf, "\tpush 0" .. nl)
				sf.write(sf, "\tsw" .. nl)
			elseif c[iter] == "getin" then
				sf.write(sf, "\tpush 0x800002" .. nl)
				sf.write(sf, "\tlw" .. nl)
			elseif c[iter] == "utime" then
				sf.write(sf, "\tpush 0x800003" .. nl)
				sf.write(sf, "\tlw" .. nl)
			elseif c[iter] == "rand" then
				sf.write(sf, "\tpush 0x800004" .. nl)
				sf.write(sf, "\tlw" .. nl)
			elseif c[iter] == "+" then
				sf.write(sf, "\tadd" .. nl)
			elseif c[iter] == "-" then
				sf.write(sf, "\tsub" .. nl)
			elseif c[iter] == "*" then
				sf.write(sf, "\tmul" .. nl)
			elseif c[iter] == "u*" then
				sf.write(sf, "\tumul" .. nl)
			elseif c[iter] == "fmul" then
				sf.write(sf, "\tfmul" .. nl)
			elseif c[iter] == "/" then
				sf.write(sf, "\tdiv" .. nl)
			elseif c[iter] == "u/" then
				sf.write(sf, "\tudiv" .. nl)
			elseif c[iter] == "fdiv" then
				sf.write(sf, "\tfdiv" .. nl)
			elseif c[iter] == "%" then
				sf.write(sf, "\tmod" .. nl)
			elseif c[iter] == "&" then
				sf.write(sf, "\tand" .. nl)
			elseif c[iter] == "|" then
				sf.write(sf, "\tot" .. nl)
			elseif c[iter] == "~" then
				sf.write(sf, "\txor" .. nl)
			elseif c[iter] == "!" then
				sf.write(sf, "\tdup" .. nl)
				sf.write(sf, "\tnor" .. nl)
			elseif c[iter] == "<<" then
				sf.write(sf, "\tsll" .. nl)
			elseif c[iter] == ">>" then
				sf.write(sf, "\tsra" .. nl)
			elseif c[iter] == ">>>" then
				sf.write(sf, "\tsrl" .. nl)
			elseif c[iter] == "=" then
				sf.write(sf, "\teq" .. nl)
			elseif c[iter] == "~=" then
				sf.write(sf, "\tne" .. nl)
			elseif c[iter] == ">" then
				sf.write(sf, "\tgt" .. nl)
			elseif c[iter] == ">=" then
				sf.write(sf, "\tge" .. nl)
			elseif c[iter] == "<" then
				sf.write(sf, "\tlt" .. nl)
			elseif c[iter] == "<=" then
				sf.write(sf, "\tle" .. nl)
			elseif c[iter] == ">" then
				sf.write(sf, "\tugt" .. nl)
			elseif c[iter] == ">=" then
				sf.write(sf, "\tuge" .. nl)
			elseif c[iter] == "<" then
				sf.write(sf, "\tult" .. nl)
			elseif c[iter] == "<=" then
				sf.write(sf, "\tule" .. nl)
			elseif c[iter] == "dup" then
				sf.write(sf, "\tdup" .. nl)
			elseif c[iter] == "over" then
				sf.write(sf, "\tover" .. nl)
			elseif c[iter] == "tuck" then
				sf.write(sf, "\ttuck" .. nl)
			elseif c[iter] == "drop" then
				sf.write(sf, "\tdrop" .. nl)
			elseif c[iter] == "nip" then
				sf.write(sf, "\tnip" .. nl)
			elseif c[iter] == "swap" then
				sf.write(sf, "\tswap" .. nl)
			elseif c[iter] == "rot" then
				sf.write(sf, "\trot" .. nl)
			elseif c[iter] == "crot" then
				sf.write(sf, "\tcrot" .. nl)
			elseif c[iter] == ">i" then
				sf.write(sf, "\titp" .. nl)
			elseif c[iter] == "i@" then
				sf.write(sf, "\titc" .. nl)
			elseif c[iter] == "i>" then
				sf.write(sf, "\titd" .. nl)
			end
		end
		iter = iter + 1
	end
	io.close(sf)
end

-- Some random variables.
argv = {...}
pit = 1
prgFile = ""
savFile = ""
temp0 = ""
files = {}

-- This code was taken from fsm.lua
while pit <= #argv do
	if argv[pit] == "--version" then
		print("FurStack version 0.3.1")
		os.exit()
	elseif argv[pit] == "--help" then
		print("FurStack Compiler usage:\n./fsc.lua [options]")
		print("Options:\n--version - display version.\n--help - display this message.\n-i - input file.\n-o - output file.")
		os.exit()
	elseif argv[pit] == "-i" then
		if prgFile ~= "" then
			disError("You already defined input file.")
		elseif argv[pit + 1] ~= nil and string.match(argv[pit + 1], "[/%w_%.]*[%w_]+%.fu") then
			prgFile = argv[pit + 1]
			pit = pit + 1
		else
			disError("Invalid parameter given.")
		end
	elseif argv[pit] == "-o" then
		if savFile ~= "" then
			disError("You already defined output file.")
		elseif argv[pit + 1] ~= nil and string.match(argv[pit + 1], "[/%w_%.]*[%w_]+%.s") then
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
	temp0 = string.sub(prgFile, 1, -3)
	savFile = temp0 .. "s"
end

table.insert(files, prgFile)

-- Opening file.
prg = io.open(prgFile, "r")
if prg == nil then
	disError("File doesn't exists.")
end
code = prg.read(prg, "*all")
io.close(prg)

-- Compiling this mess.
splited, lns, mac = tokenize(code, prgFile)

toComp, func, var = errorCheck(splited, lns, prgFile)

compile(toComp, "fsvm", savFile, mac)
