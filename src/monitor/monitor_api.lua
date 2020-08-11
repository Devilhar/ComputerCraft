
local lSystem = {}

function AddSystem(aId, aName, aProc)
	lSystem[aId] = {
		id		= aId,
		proc	= aProc,
		name	= aName
	}
end

function Updated(aId)
	query.Send("MONITOR_UPDATED", aId)
end

function GetSystem()
	return lSystem
end

STATUS_EXCELLENT	= 5
STATUS_GOOD			= 4
STATUS_FAIR			= 3
STATUS_POOR			= 2
STATUS_TERRIBLE		= 1

PROC_GET_STATUS		= "GET_STATUS"		-- ()					-> status: STATUS
PROC_GET_TITLE		= "GET_TITLE"		-- ()					-> title: string
PROC_DRAW			= "DRAW"			-- ()					-> nil
PROC_CLICK			= "CLICK"			-- (aX, aY)				-> nil
