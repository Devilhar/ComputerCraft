
local lQueryProcs = {}

function Send(aQueryType, ...)
	if not lQueryProcs[aQueryType] then
		return false
	end
	
	return true, lQueryProcs[aQueryType](...)
end

function SetProc(aQueryType, aProc)
	if aProc and lQueryProcs[aQueryType] then
		return false
	end
	
	lQueryProcs[aQueryType] = aProc
	
	return true
end
