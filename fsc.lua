#!/usr/bin/env lua
-- This compiler is looooooooooooooooong.
-- It's also even bigger mess than the assembled.
function compileError(m)
	print("\27[91m" .. m .. "\27[0m")
	os.exit()
end

-- I once created something similar in school because I was bored.
-- It pushed an empty string so I added this.
function insertCheck(t, v)
	if v ~= "" then
		table.insert(t, v)
	end
end

-- Check if value is in table.
function contains(t, v)
	local isIn = false
	for i = 1, #t, 1 do
		if t[i] == v then
			isIn = true
		end
	end
	return isIn
end

-- This exists, because later there will be no lines.
function getLn(it, t)
	local l = 0
	for i = 1, #t, 1 do
		if t[i] > it then
			break
		else
			l = l + 1
		end
	end
	return l
end

-- The function that just splits program into words and does shitty error check.
function parse(p, f)
	local t = {}
	local ft = {}
	local lnNums = {1}
	local word = ""
	local strMod = false
	local escCh = false
	local keywords = {"include", "fn", "endfn", "rem", "endrem", "let", "const", "array", "set", "fetch", "true", "false", "if", "else", "then", "while", "do", "endwhile", "repeat", "until", "bye", "put",
	"cls", "getin"}
	local operators = {"+", "-", "*", "fmul", "/", "fdiv", "%", "&", "|", "~", "!", "<<", ">>", ">>>", "=", "~=", ">", ">=", "<", "<=", "dup", "over", "swap", "rot", "drop"}
	local dataTypes = {"int", "fixed", "char", "bool"}
	local tmp1 = ""
	local tmp2 = ""
	local tmp3 = ""
	local tmp4 = {}
	local com = false
	local fnStack = {}
	local ifStack = {}
	local loopStack = {}
	local ifCount = 0
	local loopCount = 0
	local ifs = {}
	local loops = {}
	local iter = 1

	-- The simple part of it.
	for i in string.gmatch(p, "(.)") do
		if strMod then
			-- I know there are more escape sequences, but that's all I will include.
			if escCh then
				if i == "\\" then
					word = word .. "\\"
				elseif i == "\"" then
					word = word .. "\""
				elseif i == "'" then
					word = word .. "'"
				elseif i == "t" then
					word = word .. "\t"
				elseif i == "n" then
					word = word .. "\n"
				else
					compileError("Error! Invalid escape sequence in line " .. #lnNums .. " inside " .. f)
				end
				escCh = false
			-- Check for \ symbol.
			elseif i == "\\" then
				escCh = true
			elseif i == "\"" then
				strMod = false
				word = word .. "\""
			elseif i == "\n" then
				compileError("Error! Unclosed string in line " .. #lnNums .. " inside " .. f)
			else
				word = word .. i
			end
		else
			-- If you wonder, yes you code can be shaped how you want.
			-- It can be shaped like donut or square or your mom.
			if string.match(i, "%s") then
				insertCheck(t, word)
				if i == "\n" then
					table.insert(lnNums, #t + 1)
				end
				word = ""
			-- The " characters are kept for later.
			elseif i == "\"" then
				strMod = true
				word = word .. "\""
			else
				word = word .. i
			end
		end
	end
	
	-- The error check part.
	while iter <= #t do
		-- Comment. I probably don't need to say anything.
		if com then
			if t[iter] == "endrem" then
				com = false
			end
			table.insert(ft, t[iter])
		-- Is it keyword, operator, variable, number, string or function?
		elseif contains(keywords, t[iter]) or contains(operators, t[iter]) or contains(vars, t[iter]) or tonumber(t[iter]) or string.match(t[iter], "\".*\"") or contains(fns, t[iter]) then
			if t[iter] == "include" then
				iter = iter + 1
				-- It needs to be a FurStack program.
				tmp1 = string.gsub(f, "%w+%.fu", t[iter])
				tmp1 = string.gsub(tmp1, "%w+/%.%.", "")
				if not contains(included, tmp1) then
					tmp2 = io.open(tmp1, "r")
					if tmp2 == nil then
						compileError("Error! File given after 'include' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f .. " doesn't exists.")
					end
					tmp3 = tmp2.read(tmp2, "*all")
					io.close(tmp2)
					-- This is the first time I use recursion. Not in some serious program but inside a shitty compiler.
					tmp4 = parse(tmp3, tmp1)
					for i = 1, #tmp4, 1 do
						table.insert(ft, tmp4[i])
					end
				end
			-- This was inspired by Basic.
			elseif t[iter] == "rem" then
				com = true
				table.insert(ft, t[iter])
			-- I have no idea how dumb someone needs to be to do it.
			elseif t[iter] == "endrem" then
				compileError("Error! 'endrem' keyword is before 'rem' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f)
			-- Function. It doesn't take any parameters, because they are expected to be on the stack.
			elseif t[iter] == "fn" then
				if contains(fns, t[iter + 1]) then
					compileError("Error! Function " .. t[iter + 1] .. " is being defined again in line " .. getLn(iter, lnNums) .. " inside " .. f)
				else
					table.insert(fns, t[iter + 1])
					table.insert(fnStack, t[iter + 1])
					table.insert(ft, t[iter])
					table.insert(ft, t[iter + 1])
				end
				iter = iter + 1
			elseif t[iter] == "endfn" then
				if #fnStack == 0 then
					compileError("Error! 'endfn' keyword appeared before 'fn' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f)
				else
					table.remove(fnStack)
					table.insert(ft, t[iter])
				end
			-- This was also inspired by Basic.
			elseif t[iter] =="let" then
				if contains(dataTypes, t[iter + 1]) then
					if contains(vars, t[iter + 2]) then
						compileError("Error! Variable " .. t[iter + 2] .. " is being defined again in line " .. getLn(iter, lnNums) .. " inside " .. f)
					else
						table.insert(vars, t[iter + 2])
						table.insert(ft, t[iter])
						table.insert(ft, t[iter + 1])
						table.insert(ft, t[iter + 2])
					end
				else
					compileError("Error! Invalid datatype in line " .. getLn(iter, lnNums) .. " inside " .. f)
				end
				iter = iter + 2
			-- Constant.
			elseif t[iter] == "const" then
				if contains(dataTypes, t[iter + 1]) then
					if contains(vars, t[iter + 2]) then
						compileError("Error! Constant " .. t[iter + 2] .. " is being defined again in line " .. getLn(iter, lnNums) .. " inside " .. f)
					else
						-- This condition is absurdly long. Too damn long.
						if t[iter + 1] == "int" and tonumber(t[iter + 3]) and tonumber(t[iter + 3]) >= -0x8000 and tonumber(t[iter + 3]) < 0x8000 and math.type(tonumber(t[iter + 3])) == "integer" 
						or t[iter + 1] == "fixed" and tonumber(t[iter + 3]) and tonumber(t[iter + 3]) >= -128.0 and tonumber(t[iter + 3]) < 127.9961 
						or t[iter + 1] == "char" and string.match(t[iter + 3], "\".\"") 
						or t[iter + 1] == "bool" and t[iter + 3] == "true" or t[iter + 3] == "false" then
							table.insert(vars, t[iter + 2])
							table.insert(ft, t[iter])
							table.insert(ft, t[iter + 1])
							table.insert(ft, t[iter + 2])
							table.insert(ft, t[iter + 3])
						else
							compileError("Error! Invalid data for the constant in line " .. getLn(iter, lnNums) .. " inside " .. f)
						end
					end
				else
					compileError("Error! Invalid datatype in line " .. getLn(iter, lnNums) .. " inside " .. f)
				end
				iter = iter + 3
			-- The name of keyword explains itself.
			elseif t[iter] == "array" then
				if contains(dataTypes, t[iter + 1]) then
					if contains(vars, t[iter + 2]) then
						compileError("Error! Array " .. t[iter + 2] .. " is being defined again in line " .. getLn(iter, lnNums) .. " inside " .. f)
					else
						-- Yes, it's ctrl + c and ctrl + v of const keyword, but condition is shorter.
						if tonumber(t[iter + 3]) and math.type(tonumber(t[iter + 3])) == "integer" and tonumber(t[iter + 3]) >= -0x8000 and tonumber(t[iter + 3]) < 0x8000 then
							table.insert(vars, t[iter + 2])
							table.insert(ft, t[iter])
							table.insert(ft, t[iter + 1])
							table.insert(ft, t[iter + 2])
							table.insert(ft, t[iter + 3])
						else
							compileError("Error! Invalid length of array in line " .. getLn(iter, lnNums) .. " inside " .. f)
						end
					end
				else
					compileError("Error! Invalid datatype in line " .. getLn(iter, lnNums) .. " inside " .. f)
				end
				iter = iter + 3
			-- Conditional statement.
			elseif t[iter] == "if" then
				ifCount = ifCount + 1
				table.insert(ifStack, ifCount)
				table.insert(ifs, {iter, 0, 0})
				table.insert(ft, t[iter])
			elseif t[iter] == "else" then
				if #ifStack == 0 then
					compileError("Error! 'else' keyword before 'if' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f)
				else
					ifs[ifStack[#ifStack]][2] = iter
					table.insert(ft, t[iter])
				end
			-- Yes, conditiona statement ends with then keyword. Just like in Forth.
			elseif t[iter] == "then" then
				if #ifStack == 0 then
					compileError("Error! 'then' keyword before 'if' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f)
				else
					ifs[ifStack[#ifStack]][3] = iter
					table.remove(ifStack)
					table.insert(ft, t[iter])
				end
			-- While loop. I might add for loop when I figure out how the fuck does it work.
			elseif t[iter] == "while" then
				loopCount = loopCount + 1
				table.insert(loopStack, loopCount)
				table.insert(loops, {iter, 0, 0})
				table.insert(ft, t[iter])
			elseif t[iter] == "do" then
				if #loopStack == 0 then
					compileError("Error! 'do' keyword before 'while' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f)
				elseif #loops[loopStack[#loopStack]] == 2 then
					compileError("Error! 'do' keyword used for repeat until loop in line " .. getLn(iter, lnNums) .. " inside " .. f)
				else
					loops[loopStack[#loopStack]][2] = iter
					table.insert(ft, t[iter])
				end
			elseif t[iter] == "endwhile" then
				if #loopStack == 0 then
					compileError("Error! 'endwhile' keyword before 'while' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f)
				elseif #loops[loopStack[#loopStack]] == 2 then
					compileError("Error! 'endwhile' keyword used for repeat until loop in line " .. getLn(iter, lnNums) .. " inside " .. f)
				else
					if loops[loopStack[#loopStack]][2] == 0 then
						compileError("Error! 'endwhile' keyword before 'do' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f)
					else
						loops[loopStack[#loopStack]][3] = iter
						table.remove(loopStack)
						table.insert(ft, t[iter])
					end
				end
			-- repeat until loop. It's like while loop, but it will always execute at least once.
			elseif t[iter] == "repeat" then
				loopCount = loopCount + 1
				table.insert(loopStack, loopCount)
				table.insert(loops, {iter, 0})
				table.insert(ft, t[iter])
			elseif t[iter] == "until" then
				if #loopStack == 0 then
					compileError("Error! 'until' keyword before 'repeat' keyword in line " .. getLn(iter, lnNums) .. " inside " .. f)
				elseif #loops[loopStack[#loopStack]] == 3 then
					compileError("Error! 'until' keyword used for while loop in line " .. getLn(iter, lnNums) .. " inside " .. f)
				else
					loops[loopStack[#loopStack]][2] = iter
					table.remove(loopStack)
					table.insert(ft, t[iter])
				end
			-- Numbers.
			elseif math.type(tonumber(t[iter])) == "integer" then
				if tonumber(t[iter]) >= -0x8000 and tonumber(t[iter]) < 0x8000 then
					table.insert(ft, t[iter])
				else
					compileError("Error! Invalid number in line " .. getLn(iter, lnNums) .. " inside " .. f)
				end
			elseif math.type(tonumber(t[iter])) == "float" then
				if tonumber(t[iter]) >= -128 and tonumber(t[iter]) < 127.9961 then
					table.insert(ft, t[iter])
				else
					compileError("Error! Invalid number in line " .. getLn(iter, lnNums) .. " inside " .. f)
				end
			-- Everything else.
			else
				table.insert(ft, t[iter])
			end
		-- You got error.
		else
			compileError("Error! The word in line " ..getLn(iter, lnNums) .. " inside " .. f .. " can't be understand by compiler.")
		end
		iter = iter + 1
	end
	
	-- You forgot something.
	if #fnStack > 0 then
		compileError("Error! Function " .. fnStack[1] .. " is unclosed inside " .. f)
	elseif #ifStack > 0 then
		compileError("Error! Conditional statement from line " .. getLn(ifStack[1][1], lnNums) .. " inside " .. f .. " is unclosed.")
	elseif #loopStack > 0 then
		compileError("Error! Loop from line " .. getLn(loopStack[1][1], lnNums) .. " inside " .. f .. " is unclosed.")
	end
	
	return ft
end

-- It's still shit.
argv = {...}
pit = 1
prg_file = ""
sav_file = ""
if #argv == 0 or argv[1] == "--help" then
	diserror("Usage:\n./fsc.lua [params]\n--help - this message.\n--version - display version.\n-i - input file.\n-o - output file.")
end

while pit <= #argv do
	if argv[pit] == "--version" then
		diserror("FurStack version 0.2.1")
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
	sav_file = string.gsub(prg_file, "%.fu", "%.s")
end

if not string.match(prg_file, ".+%.fu") then
	compileError("Error! The input file is not a FurStack program.")
end

-- Reading program.
prg = io.open(prg_file, "r")
if prg == nil then
	compileError("Error! File doesn't exist.")
end
content = prg.read(prg, "*all")
io.close(prg)

-- The reason those are global, is include keyword.
vars = {}
fns = {}
included = {prg_file}
-- The start of this madness.
words = parse(content, prg_file)

it = 1
stackCond = {}
countCond = 0
stackLoop = {}
countLoop = 0
stackRep = {}
countRep = 0
var = {}
var_addr = 0
temp1 = ""
temp2 = {}
-- Does it compiles to x86? No.
-- Does it compile to arm? No.
-- Does it compile to risc-v? No.
-- Does it compile to anything real? No. It compiles to shitty assembly for FurStack Virtual Machine.
compiled = {
	"cal main\n",
	"exit\n"
}

-- This is the second longest part og the program. The first one is the parse function.
-- The compiled code will probably not be that far behind assembly code written by human. The VM is a stack machine.
-- Yes, you can program FurStack Virtual Machine in assembly.
while it <= #words do
	-- Numbers, string and variables.
	if tonumber(words[it]) or var[words[it]] then
		table.insert(compiled, "push " .. words[it] .. "\n")
	elseif string.match(words[it], "\".*\"") then
		temp1 = string.sub(words[it], 2, -2)
		for p, c in utf8.codes(temp1) do
			table.insert(temp2, "push " .. c .. "\n")
		end
		for i = 1, #temp2, 1 do
			table.insert(compiled, temp2[#temp2 - i + 1])
		end
		temp2 = {}
	-- Keywords.
	-- Yes, comments are also written into the compiled program.
	-- No. I'm not getting rid of it. Fuck you.
	elseif words[it] == "rem" then
		temp1 = words[it]
		it = it + 1
		while words[it] ~= "endrem" do
			temp1 = temp1 .. " " .. words[it]
			it = it + 1
		end
		table.insert(compiled, temp1 .. "\n")
	elseif words[it] == "fn" then
		table.insert(compiled, "deflab " .. words[it + 1] .. "\n")
		it = it + 1
	elseif words[it] == "endfn" then
		table.insert(compiled, "ret\n")
	elseif words[it] == "let" then
		var[words[it + 2]] = var_addr
		table.insert(compiled, "def " .. words[it + 2] .. " " .. var_addr .. "\n")
		var_addr = var_addr + 1
		it = it + 2
	elseif words[it] == "const" then
		var[words[it + 2]] = -1
		if words[it + 1] == "int" or words[it + 1] == "fixed" then
			table.insert(compiled, "def " .. words[it + 2] .. " " .. words[it + 3] .. "\n")
		elseif words[it + 1] == "char" then
			temp1 = string.sub(words[it + 3], 2, 2)
			table.insert(compiled, "def " .. words[it + 2] .. " " .. utf8.codepoint(temp1) .. "\n")
		elseif words[it + 1] == "bool" then
			if words[it + 3] == "true" then
				table.insert(compiled, "def " .. words[it + 2] .. " -1\n")
			else
				table.insert(compiled, "def " .. words[it + 2] .. " 0\n")
			end
		end
		it = it + 3
	elseif words[it] == "array" then
		var[words[it + 2]] = var_addr
		table.insert(compiled, "def " .. words[it + 2] .. " " .. var_addr .. "\n")
		var_addr = var_addr + tonumber(words[it + 3])
		it = it + 3
	elseif words[it] == "set" then
		table.insert(compiled, "sw\n")
	elseif words[it] == "fetch" then
		table.insert(compiled, "lw\n")
	elseif words[it] == "true" then
		table.insert(compiled, "push -1\n")
	elseif words[it] == "false" then
		table.insert(compiled, "push 0\n")
	elseif words[it] == "if" then
		countCond = countCond + 1
		table.insert(stackCond, {countCond, false})
		table.insert(compiled, "jc if" .. countCond .. "\n")
		table.insert(compiled, "j else" .. countCond .. "\n")
		table.insert(compiled, "deflab if" .. countCond .. "\n")
	elseif words[it] == "else" then
		stackCond[#stackCond][2] = true
		table.insert(compiled, "j then" .. stackCond[#stackCond][1] .. "\n")
		table.insert(compiled, "deflab else" .. stackCond[#stackCond][1] .. "\n")
	elseif words[it] == "then" then
		if stackCond[#stackCond][2] then
			table.insert(compiled, "deflab then" .. stackCond[#stackCond][1] .. "\n")
		else
			table.insert(compiled, "deflab else" .. stackCond[#stackCond][1] .. "\n")
		end
		table.remove(stackCond)
	elseif words[it] == "while" then
		countLoop = countLoop + 1
		table.insert(stackLoop, countLoop)
		table.insert(compiled, "deflab while" .. countLoop .. "\n")
	elseif words[it] == "do" then
		table.insert(compiled, "jc do" .. stackLoop[#stackLoop] .. "\n")
		table.insert(compiled, "j endwhile" .. stackLoop[#stackLoop] .. "\n")
		table.insert(compiled, "deflab do" .. stackLoop[#stackLoop] .. "\n")
	elseif words[it] == "endwhile" then
		table.insert(compiled, "j while" .. stackLoop[#stackLoop] .. "\n")
		table.insert(compiled, "deflab endwhile" .. stackLoop[#stackLoop] .. "\n")
		table.remove(stackLoop)
	elseif words[it] == "repeat" then
		countRep = countRep + 1
		table.insert(stackRep, countRep)
		table.insert(compiled, "deflab repeat" .. countRep .. "\n")
	elseif words[it] == "until" then
		table.insert(compiled, "deflab until" .. stackRep[#stackRep] .. "\n")
		table.insert(compiled, "jc repeat" .. stackRep[#stackRep] .. "\n")
	-- There used to be gofn. Now it's just function name.
	elseif contains(fns, words[it]) then
		table.insert(compiled, "cal " .. words[it] .. "\n")
	elseif words[it] == "bye" then
		table.insert(compiled, "exit\n")
	elseif words[it] == "put" then
		table.insert(compiled, "por reg0\n")
		table.insert(compiled, "push 0x8000\n")
		table.insert(compiled, "pur reg0\n")
		table.insert(compiled, "sw\n")
	elseif words[it] == "cls" then
		table.insert(compiled, "push 0x8001\n")
		table.insert(compiled, "push 0\n")
		table.insert(compiled, "sw\n")
	elseif words[it] == "getin" then
		table.insert(compiled, "push 0x8002\n")
		table.insert(compiled, "lw\n")
	-- Operators.
	elseif words[it] == "+" then
		table.insert(compiled, "add\n")
	elseif words[it] == "-" then
		table.insert(compiled, "sub\n")
	elseif words[it] == "*" then
		table.insert(compiled, "mul\n")
	elseif words[it] == "fmul" then
		table.insert(compiled, "fmul\n")
	elseif words[it] == "/" then
		table.insert(compiled, "div\n")
	elseif words[it] == "fdiv" then
		table.insert(compiled, "fdiv\n")
	elseif words[it] == "%" then
		table.insert(compiled, "mod\n")
	elseif words[it] == "&" then
		table.insert(compiled, "and\n")
	elseif words[it] == "|" then
		table.insert(compiled, "or\n")
	elseif words[it] == "~" then
		table.insert(compiled, "xor\n")
	elseif words[it] == "!" then
		table.insert(compiled, "dup\n")
		table.insert(compiled, "nor\n")
	elseif words[it] == "<<" then
		table.insert(compiled, "sll\n")
	elseif words[it] == ">>" then
		table.insert(compiled, "sra\n")
	elseif words[it] == ">>>" then
		table.insert(compiled, "srl\n")
	elseif words[it] == "=" then
		table.insert(compiled, "eq\n")
	elseif words[it] == "~=" then
		table.insert(compiled, "ne\n")
	elseif words[it] == ">" then
		table.insert(compiled, "gt\n")
	elseif words[it] == ">=" then
		table.insert(compiled, "ge\n")
	elseif words[it] == "<" then
		table.insert(compiled, "lt\n")
	elseif words[it] == "<=" then
		table.insert(compiled, "le\n")
	elseif words[it] == "dup" then
		table.insert(compiled, "dup\n")
	elseif words[it] == "over" then
		table.insert(compiled, "over\n")
	elseif words[it] == "swap" then
		table.insert(compiled, "por reg0\n")
		table.insert(compiled, "por reg1\n")
		table.insert(compiled, "pur reg0\n")
		table.insert(compiled, "pur reg1\n")
	elseif words[it] == "rot" then
		table.insert(compiled, "por reg0\n")
		table.insert(compiled, "por reg1\n")
		table.insert(compiled, "por reg2\n")
		table.insert(compiled, "pur reg1\n")
		table.insert(compiled, "pur reg0\n")
		table.insert(compiled, "pur reg2\n")
	elseif words[it] == "drop" then
		table.insert(compiled, "drop\n")
	end
	it = it + 1
end

-- Compiled. Now it can be saved.
asm = io.open(sav_file, "w")
for i = 1, #compiled, 1 do
	asm.write(asm, compiled[i])
end
io.close(asm)
