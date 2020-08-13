
local args = {...}

local cSeedTypes = {
	diamond		= { name = "Diamond",		color = colors.lightBlue },
	gold		= { name = "Gold",			color = colors.yellow	 },
	iron		= { name = "Iron",			color = colors.lightGray },
	coal		= { name = "Coal",			color = colors.black	 },
	quartz		= { name = "Nether Quartz",	color = colors.white	 },
	emerald		= { name = "Emerald",		color = colors.lime		 },
	inferium	= { name = "Inferium",		color = colors.green	 },
	glowstone	= { name = "Glowstone",		color = colors.yellow	 },
	redstone	= { name = "Redstone",		color = colors.red		 },
	lapis		= { name = "Lapiz",			color = colors.blue		 },
	dye			= { name = "Dye",			color = colors.pink		 },
	ender		= { name = "Enderman",		color = colors.purple	 },
	osmium		= { name = "Osmium",		color = colors.cyan		 },
	prismarine	= { name = "Prismarine",	color = colors.cyan		 },
	dirt		= { name = "Dirt Essence",	color = colors.brown	 },
	water		= { name = "Water Essence",	color = colors.lightBlue }
}

local lHostname = args[1]
local lPort = tonumber(args[2])

local lFields = {
	field1x1 = { hostname = "agriturt1_1", x = 1, z = 1 },
	field1x2 = { hostname = "agriturt1_2", x = 1, z = 2 },
	field1x3 = { hostname = "agriturt1_3", x = 1, z = 3 },
	field2x1 = { hostname = "agriturt2_1", x = 2, z = 1 },
	field2x2 = { hostname = "agriturt2_2", x = 2, z = 2 },
	field2x3 = { hostname = "agriturt2_3", x = 2, z = 3 },
	field3x1 = { hostname = "agriturt3_1", x = 3, z = 1 },
	field3x2 = { hostname = "agriturt3_2", x = 3, z = 2 },
	field3x3 = { hostname = "agriturt3_3", x = 3, z = 3 }
};

if not lPort then
	lPort = 5000
end

if type(lHostname) ~= "string"
	or (not lPort and args[2]) then
	error("Invalid args, expected hostname: [string], <port: [number]>")
end

print("Running Agridome Service program...")

local function GetFieldSeed(aFieldId)
	local result, err, payload = tp.Get(lFields[aFieldId].hostname, nil, "seed")
	
	if not result then
		print("Failed to fetch field info: " .. aFieldId .. ", " .. err )
		
		return false, nil
	end
	
	return true, payload.type
end

local function SetFieldSeed(aFieldId, aSeedType)
	local result, err = tp.Post(lFields[aFieldId].hostname, nil, "seed", { type = aSeedType }, 10)
	
	if not result then
		local message = aFieldId
		
		if aSeedType then
			message = message .. ", " .. aSeedType
		end
		
		print("Failed to set field type: " .. message .. ", " .. err )
	end
	
	return result, err
end

local function ProcGet(aPath, aPayload)
	if aPath == "fields" then
		local fields = {}
		
		for fieldId, field in pairs(lFields) do
			table.insert(fields, { field = fieldId, x = field.x, z = field.z })
		end
		
		return "SUCCESS", { fields = fields }
	elseif aPath == "seed" then
		if aPayload
			and (type(aPayload) ~= "table"
				or (aPayload.field
				and type(aPayload.field) ~= "string")) then
			return "BAD_REQUEST"
		end
		
		if aPayload
			and aPayload.field then
			local result, seed = GetFieldSeed(aPayload.field)
			
			return "SUCCESS", { fields = { field = aPayload.field, available = result, type = seed } }
		end
		
		local fields = {}
		
		for fieldId, _ in pairs(lFields) do
			local result, seed = GetFieldSeed(fieldId)
			
			table.insert(fields, { field = fieldId, available = result, type = seed })
		end
		
		return "SUCCESS", { fields = fields }
	elseif aPath == "types" then
		return "SUCCESS", { types = cSeedTypes }
	end
	
	return "NOT_FOUND"
end

local function ProcPost(aPath, aPayload)
	if aPath == "seed" then
		if type(aPayload) ~= "table" 
			or type(aPayload.field) ~= "string" then
			return "BAD_REQUEST"
		end
		
		if aPayload.type
			and type(aPayload.type) ~= "string" then
			return "BAD_REQUEST"
		end
		
		if not lFields[aPayload.field] then
			return "BAD_REQUEST"
		end
		
		local result, err = SetFieldSeed(aPayload.field, aPayload.type)
		
		if not result then
			return err
		end
		
		return "SUCCESS"
	end
	
	return "NOT_FOUND"
end

dns.RegisterHostname(lHostname, lPort)
tp.SetupProcs(lPort, ProcGet, ProcPost)
