
function Parse(aArgs)
	local args = {}
	local lastArg = nil
	
	for _, arg in ipairs(aArgs) do
		if string.sub(arg, 1, 1) == "-" then
			lastArg = {}
			
			args[string.sub(arg, 2, string.len(arg))] = lastArg
		elseif lastArg then
			table.insert(lastArg, arg)
		end
	end
	
	return args
end
