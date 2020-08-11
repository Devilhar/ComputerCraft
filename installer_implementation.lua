local cPackages = {
	apis = {
		{ v = "1.1", p = "zr6G4VvV", n = "api/signal" },
		{ v = "1.1", p = "UedyfUfX", n = "api/net" },
		{ v = "1.1", p = "1gdaUH6f", n = "api/dns" },
		{ v = "1.1", p = "iFfZ3LzP", n = "api/tp" },
		{ v = "1.1", p = "cJE64GYG", n = "api/query" },
		{ v = "1.1", p = "gnm17en1", n = "api/parameters" },
		{ v = "1.1", p = "Jkw7wpRk", n = "startup/AAA_api_loader" }
	},
	monitor_client = {
		{ v = "1.2", p = "E6vwMjyg", n = "monitor/monitor_client" },
		{ v = "1.2", p = "X0RH3BBc", n = "monitor/monitor_api" },
		{ v = "1.2", p = "kv7EKExM", n = "monitor/programs/agridome" }
	},
	agridome_turtle = {
		{ v = "1.1", p = "sKrMibUV", n = "agridome/turtle" }
	},
	agridome_service = {
		{ v = "1.1", p = "qqat5e3q", n = "agridome/service" }
	},
	agridome_client = {
		{ v = "1.1", p = "zKe6GDv5", n = "agridome/field" }
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
	},
	agridome_client = {
		"apis",
		"agridome_client"
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
local function DownloadFile(aPastebinId, aFile)
	local response = http.get("http://www.pastebin.com/raw.php?i=" .. aPastebinId)
	
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
