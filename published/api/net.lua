
local cSides = { "front", "right", "back", "left", "top", "bottom" }

local lActivePorts = {}
local lPendingMessages = {}

EventName = "net_message"

local function FindPort(aPort)
	for i, port in ipairs(lActivePorts) do
		if port == aPort then
			return i
		end
	end
end

local function IsPortInList(aPort)
	return (FindPort(aPort) ~= nil)
end
local function AddPort(aPort)
	table.insert(lActivePorts, aPort)
end
local function RemovePort(aPort)
	local i = FindPort(aPort)
	
	table.remove(lActivePorts, i)
end

local function IsModem(aSide)
	return peripheral.getType(aSide) == "modem"
end

local function SendMessage(aPort, aId, aMessage)
	if not IsPortInList(aPort) then
		return false, "PORT_CLOSED"
	end
	
	local id = os.getComputerID()
	
	local message = { recipient=aId, sender=id, message=aMessage }
	local sent = false
	
	for _, side in ipairs(cSides) do
		if IsModem(side) then
			peripheral.call(side, "transmit", aPort, aPort, message)
			sent = true
		end
	end
	
	if not sent then
		return false, "NO_MODEM"
	end
	
	return true, "SUCCESS"
end

local function OnPeripheral(aEvent, aSide)
	if not IsModem(aSide) then
		return
	end
	
	for _, port in ipairs(lActivePorts) do
		peripheral.call(aSide, "open", port)
	end
end
local function OnModemMessage(aEvent, aSide, aPort, _, aMessage, _)
	if type(aMessage) ~= "table" then
		return
	end
	
	if aMessage.recipient
		and aMessage.recipient ~= os.getComputerID() then
		return
	end
	
	os.queueEvent(EventName, aPort, aMessage.sender, aMessage.message)
end

signal.Hook("peripheral", OnPeripheral)
signal.Hook("modem_message", OnModemMessage)

function Open(aPort)
	if IsPortInList(aPort) then
		return
	end
	
	for _, side in ipairs(cSides) do
		if IsModem(side) then
			peripheral.call(side, "open", aPort)
		end
	end
	
	AddPort(aPort)
end

function Close(aPort)
	if not IsPortInList(aPort) then
		return
	end
	
	for _, side in ipairs(cSides) do
		if IsModem(side) then
			peripheral.call(side, "close", aPort)
		end
	end
	
	RemovePort(aPort)
end

function IsOpen(aPort)
	return IsPortInList(aPort)
end

function Broadcast(aPort, aMessage)
	return SendMessage(aPort, nil, aMessage)
end
function Send(aPort, aId, aMessage)
	return SendMessage(aPort, aId, aMessage)
end
