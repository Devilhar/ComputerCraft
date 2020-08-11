
local args = {...}

local lHostname = args[1]
local lPort = tonumber(args[2])

if not lPort then
	lPort = 6000
end

if type(lHostname) ~= "string"
	or (not lPort and args[2]) then
	error("Invalid args, expected hostname: [string], <port: [number]>")
end

print("Running Agridome Turtle program...")

local cSeedConfig = {
	diamond		= { pos = 1, side = "left" },
	gold		= { pos = 2, side = "left" },
	iron		= { pos = 3, side = "left" },
	coal		= { pos = 4, side = "left" },
	quartz		= { pos = 5, side = "left" },
	emerald		= { pos = 6, side = "left" },
	inferium	= { pos = 7, side = "left" },
	redstone	= { pos = 1, side = "right" },
	lapis		= { pos = 2, side = "right" },
	dye			= { pos = 3, side = "right" },
	ender		= { pos = 4, side = "right" },
	osmium		= { pos = 5, side = "right" },
	prismarine	= { pos = 6, side = "right" }
}
local cFileSeed = "agridome_seed.dat"

local lCurrentPos	= 1
local lSeedType		= nil

local function SaveSeed(aSeedType)
	if not aSeedType then
		fs.delete(cFileSeed)
		
		return
	end
	
	local file = fs.open(cFileSeed, "w")
	
	file.write(aSeedType)
	
	file.flush()
	
	file.close()
end

local function LoadSeed()
	if not fs.exists(cFileSeed) then
		return
	end
	
	local file = fs.open(cFileSeed, "r")
	
	local seedType = file.readAll()
	
	file.close()
	
	return seedType
end

local function Reset()
	rs.setOutput("left",	false)
	rs.setOutput("right",	false)
	
	lCurrentPos = 1
	while turtle.back() do end
end

local function GoToPos(aPos)
	local diff = aPos - lCurrentPos
	
	if diff == 0 then
		return
	end
	
	local moveFunc = turtle.forward
	
	if diff < 0 then
		moveFunc = turtle.back
		diff = -diff
	end
	
	for i = 1, diff do
		moveFunc()
	end
	
	lCurrentPos = aPos
end

local function RefuelIfNeeded()
	if turtle.getFuelLevel() > 100 then
		return true
	end
	
	GoToPos(1)
	
	while turtle.getFuelLevel() <= 100 do
		if not turtle.suckUp() then
			return false
		end
		
		turtle.refuel()
	end
	
	return true
end

local function ActivateSeed(aSeedType)
	local seed = cSeedConfig[aSeedType]
	
	if not seed then
		return false
	end
	
	lSeedType = aSeedType
	SaveSeed(aSeedType)
	
	rs.setOutput("left",	false)
	rs.setOutput("right",	false)
	
	GoToPos(seed.pos)
	
	rs.setOutput(seed.side, true)
	
	return true
end

Reset()

RefuelIfNeeded()

lSeedType = LoadSeed()

if lSeedType then
	ActivateSeed(lSeedType)
end

local function ProcGet(aPath, _)
	if aPath == "seed" then
		return "SUCCESS", { type = lSeedType }
	elseif aPath == "fuel" then
		return "SUCCESS", { fuel = turtle.getFuelLevel() }
	end
	
	return "NOT_FOUND"
end

local function ProcPost(aPath, aPayload)
	if aPath == "seed" then
		if not aPayload.type then
			lSeedType = nil
			SaveSeed(nil)
			
			Reset()
			
			return "SUCCESS"
		end
		
		if type(aPayload.type) ~= "string" then
			return "BAD_REQUEST"
		end
		
		if not cSeedConfig[aPayload.type] then
			return "BAD_REQUEST"
		end
		
		if not RefuelIfNeeded() then
			return "INTERNAL_ERROR"
		end
		
		if not ActivateSeed(aPayload.type) then
			return "INTERNAL_ERROR"
		end
		
		return "SUCCESS"
	end
	
	return "NOT_FOUND"
end

dns.RegisterHostname(lHostname, lPort)
tp.SetupProcs(lPort, ProcGet, ProcPost)
