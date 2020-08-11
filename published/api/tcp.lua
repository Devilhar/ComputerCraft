
function Connect(aHostnameOrId, aPort)
	local id = aHostnameOrId
	
	if type(id) == "string" then
		local result, err = nil
		
		result, err, aPort, id = dns.Lookup(aHostnameOrId)
		
		if not result then
			return false, err
		end
	end
	
	local nextRequestId = 0
	
	local function SendMessage(aMessage)
		local message = {
			protocol = "TCP",
			command = "SEND",
			request = nextRequestId,
			message = aMessage
		}
		
		nextRequestId = nextRequestId + 1
		
		return net.Send(aPort, id, message), message.request
	end
	local function WaitForMessage()
		
	end
	
	local function SendAwaitReply(aMessage)
		local result, err, request = SendMessage(aMessage)
		
		if not result then
			return false, "TCP." .. err
		end
		
		while true do
			local e = {os.pullEvent()}
			
			if e[1] == net.EventName then
				if e[2] == aPort
					and e[3] == id
					and type(e[4]) == "table"
					and e[4].protocol == "TCP"
					and e[4].command == "REPLY"
					and e[4].request == request then
					return "SUCCESS"
				end
			end
		end
	end
	
	local connection = {}
	
	function connection.Send(aMessage)
		SendMessage(aMessage)
	end
	
	function connection.Receive()
		
	end
	
	function connection.Disconnect()
		
	end
	
	return true, nil, connection
end

function Listen(aPort, aProcConnect, aProcDisconnect, aProcMessage)
	
end
