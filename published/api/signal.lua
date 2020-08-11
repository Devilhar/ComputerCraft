
local lHookedFuncs = {}

local lPullEvent = os.pullEvent

os.pullEvent = function(aEvent)
	while true do
		local e = {lPullEvent()}
		
		for k, v in pairs(lHookedFuncs) do
			if v.event == e[1] then
				v.func(unpack(e))
			end
		end
		
		if not aEvent or e[1] == aEvent then
			return unpack(e)
		end
	end
end

function Hook(aEvent, aFunc)
	local pair = {}
	
	pair.event = aEvent
	pair.func = aFunc
	
	table.insert(lHookedFuncs, pair)
	
	return pair
end

function Unhook(aPair)
	for k, v in pairs(lHookedFuncs) do
		if v == aPair then
			lHookedFuncs[k] = nil
			
			return true
		end
	end
	
	return false
end
