local cBasePath = "https://raw.githubusercontent.com/Devilhar/ComputerCraft/master/"

local cPackages = {
	apis = {
		{ v = "1.1", p = "api/signal.lua",					n = "api/signal" },
		{ v = "1.1", p = "api/net.lua",						n = "api/net" },
		{ v = "1.1", p = "api/dns.lua",						n = "api/dns" },
		{ v = "1.1", p = "api/tp.lua",						n = "api/tp" },
		{ v = "1.1", p = "api/query.lua",					n = "api/query" },
		{ v = "1.1", p = "api/parameters.lua",				n = "api/parameters" },
		{ v = "1.1", p = "api/startup.lua",					n = "startup/AAA_api_loader" }
	},
	monitor_client = {
		{ v = "1.2", p = "monitor/monitor_client.lua",		n = "monitor/monitor_client" },
		{ v = "1.2", p = "monitor/monitor_api.lua",			n = "monitor/monitor_api" },
		{ v = "1.2", p = "monitor/programs/agridome.lua",	n = "monitor/programs/agridome" }
	},
	agridome_turtle = {
		{ v = "1.1", p = "agridome/agridome_turtle.lua",	n = "agridome/turtle" }
	},
	agridome_service = {
		{ v = "1.1", p = "agridome/agridome_service.lua",	n = "agridome/service" }
	}
}
local cInstalls = {
	monitor_client = {
		"apis",
		"monitor_client"
	},
	agridome_turtle = {
		"apis",
		"agridome_turtle"
	},
	agridome_service = {
		"apis",
		"agridome_service"
	}
}
local cFilename = "versions.json"

local function LoadPackagesVersion()
	if not fs.exists(cFilename) then
		return {}
	end
	
	local file = fs.open(cFilename, "r")
	
	local versions = textutils.unserializeJSON(file.readAll())
	
	file.close()
	
	return versions
end
local function SavePackagesVersion(aVersions)
	local file = fs.open(cFilename, "w")
	
	file.write(textutils.serializeJSON(aVersions))
	
	file.flush()
	
	file.close()
end
local function DownloadFile(aPath, aFile)
	local response = http.get(cBasePath .. aPath)
	
	if not response then
		return false
	end
	
	local content = response.readAll()
	
	response.close()
	
	local file = fs.open(aFile, "w")
	
	file.write(content)
	
	file.flush()
	
	file.close()
	
	return true
end

local args = {...}

local installName = args[1]

if not installName then
	error("Install name required")
end

local install = cInstalls[installName]

if not install then
	error("No install with name: " .. installName .. ".")
end

local lVersions = LoadPackagesVersion()

for _, v in ipairs(install) do
	for _, p in ipairs(cPackages[v]) do
		if lVersions[p.n] ~= p.v
			or not fs.exists(p.n) then
			local tempFile = p.n .. "_temp"
			
			if DownloadFile(p.p, tempFile) then
				fs.delete(p.n)
				
				fs.move(tempFile, p.n)
				lVersions[p.n] = p.v
				
				print("File downloaded: " .. p.n)
			else
				print("Failed to download file: " .. p.n)
			end
		end
	end
end

SavePackagesVersion(lVersions)
