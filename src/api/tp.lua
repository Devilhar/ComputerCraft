
local lNextRequestId = 0

local function Send(aCommand, aId, aPort, aPath, aPayload, aRequestId, aResult)
	local message = {}
	
	message.request = aRequestId
	
	message.protocol = "TP"
	if not message.request then
		message.request = lNextRequestId
		
		lNextRequestId = lNextRequestId + 1
	end
	message.command = aCommand
	message.path = aPath
	message.payload = aPayload
	message.result = aResult
	
	net.Send(aPort, aId, message)
	
	return message.request
end

local function PerformRequest(aCommand, aHostname, aPort, aPath, aPayload, aTimeout)
	if not aTimeout then
		aTimeout = 1
	end
	
	local id = aHostname
	
	if type(id) == "string" then
		local currentTime = os.time()
		local result, err = nil
		
		result, err, aPort, id = dns.Lookup(aHostname, aTimeout)
		
		if not result then
			return false, err
		end
		
		aTimeout = aTimeout - (os.time() - currentTime)
	end
	
	local portOpen = net.IsOpen(aPort)
	
	if not portOpen then
		net.Open(aPort)
	end
	
	local request = Send(aCommand, id, aPort, aPath, aPayload)
	local timer = os.startTimer(aTimeout)
	
	while true do
		local e = {os.pullEvent()}
		
		if e[1] == "timer" then
			if e[2] == timer then
				if not portOpen then
					net.Close(aPort)
				end
				
				return false, "TP.TIMEOUT"
			end
		elseif e[1] == net.EventName then
			if e[2] == aPort
				and e[3] == id
				and type(e[4]) == "table"
				and e[4].protocol == "TP"
				and e[4].request == request
				and e[4].path == aPath
				and type(e[4].result) == "string" then
				if not portOpen then
					net.Close(aPort)
				end
				
				return (e[4].result == "SUCCESS"), e[4].result, e[4].payload
			end
		end
	end
end

function Get(aHostname, aPort, aPath, aPayload, aTimeout)
	return PerformRequest("GET", aHostname, aPort, aPath, aPayload, aTimeout)
end

function Post(aHostname, aPort, aPath, aPayload, aTimeout)
	return PerformRequest("POST", aHostname, aPort, aPath, aPayload, aTimeout)
end

function Put(aHostname, aPort, aPath, aPayload, aTimeout)
	return PerformRequest("PUT", aHostname, aPort, aPath, aPayload, aTimeout)
end

function Delete(aHostname, aPort, aPath, aPayload, aTimeout)
	return PerformRequest("DELETE", aHostname, aPort, aPath, aPayload, aTimeout)
end

function SetupProcs(aProcPort, aProcGet, aProcPost, aProcPut, aProcDelete)
	procs = {
		GET		= aProcGet,
		POST	= aProcPost,
		PUT		= aProcPut,
		DELETE	= aProcDelete
	}
	
	signal.Hook(net.EventName, function(_, aPort, aSender, aMessage)
		if aPort ~= aProcPort
			or type(aMessage) ~= "table"
			or aMessage.protocol ~= "TP"
			or type(aMessage.request) ~= "number"
			or (aMessage.command ~= "GET"
				and aMessage.command ~= "POST"
				and aMessage.command ~= "PUT"
				and aMessage.command ~= "DELETE")
			or type(aMessage.path) ~= "string" then
			return
		end
		
		if not procs[aMessage.command] then
			Send(aMessage.command, aSender, aPort, aMessage.path, nil, aMessage.request, "UNSUPPORTED_COMMAND")
		end
		
		local result, payload = procs[aMessage.command](aMessage.path, aMessage.payload)
		
		if type(result) ~= "string" then
			Send(aMessage.command, aSender, aPort, aMessage.path, nil, aMessage.request, "INTERNAL_SERVER_ERROR")
			print("Invalid TP command proc result type. Got: ", type(result))
			return
		end
		
		Send(aMessage.command, aSender, aPort, aMessage.path, payload, aMessage.request, result)
	end)
	
	net.Open(aProcPort)
end
