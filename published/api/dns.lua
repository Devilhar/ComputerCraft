
local cPort = 600
local cDefaultTimeout = 1

local lHostnames = nil

local function NetLookup(aHostname, aTimeout)
	local message = {
		protocol = "DNS",
		command = "LOOKUP",
		hostname = aHostname
	}
	
	local result, err = net.Broadcast(cPort, message)
	
	if not result then
		return false, "DNS." .. err
	end
	
	if not aTimeout then
		aTimeout = cDefaultTimeout
	end
	
	local timer = os.startTimer(aTimeout)
	
	while true do
		local e = {os.pullEvent()}
		
		if e[1] == "timer" then
			if e[2] == timer then
				return false, "DNS_TIMEOUT"
			end
		elseif e[1] == net.EventName then
			if e[2] == cPort
				and type(e[4]) == "table"
				and e[4].protocol == "DNS"
				and e[4].command == "BROADCAST"
				and e[4].hostname == aHostname
				and type(e[4].id) == "number"
				and type(e[4].port) == "number" then
				return true, "SUCCESS", e[4].port, e[4].id
			end
		end
	end
end

local function OnNetMessage(_, aPort, aSender, aMessage)
	if aPort ~= cPort then
		return
	end
	
	if type(aMessage) ~= "table"
		and aMessage.protocol ~= "DNS"
		and aMessage.command ~= "LOOKUP"
		and type(aMessage.hostname) ~= "string" then
		return
	end
	
	if not lHostnames[aMessage.hostname] then
		return
	end
	
	local message = {
		protocol = "DNS",
		command = "BROADCAST",
		hostname = aMessage.hostname,
		id = os.getComputerID(),
		port = lHostnames[aMessage.hostname]
	}
	
	local result, err = net.Broadcast(cPort, message)
	
	if not result then
		print("Failed to broadcast DNS hostname, reason:", err)
	end
end

net.Open(cPort)

function Lookup(aHostname, aTimeout)
	return NetLookup(aHostname, aTimeout)
end

function RegisterHostname(aHostname, aPort)
	if not lHostnames then
		lHostnames = {}
		
		signal.Hook(net.EventName, OnNetMessage)
	end
	
	lHostnames[aHostname] = aPort
end
