function checkInsert(t, v)
	if v ~= "" then
		table.insert(t, v)
	end
end

function disError(m)
	print("\27[91m" .. m .. "\27[0m")
	os.exit(1)
end

function isValNum(s, min, max)
	return tonumber(s) and tonumber(s) >= min and tonumber(s) <= max
end
