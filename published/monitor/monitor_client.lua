
if not monitor_api and not os.loadAPI("monitor/monitor_api") then
	error("Requied API not installed: monitor/monitor_api.")
end

local args = parameters.Parse({...})

if args["monitor"]
	and #args["monitor"] == 0 then
	error("Invalid monitor parameter.")
end

if args["text_scale"]
	and (#args["text_scale"] == 0
		or not tonumber(args["text_scale"][1])) then
	error("Invalid monitor parameter.")
end

if args["system"]
	and #args["system"] == 0 then
	error("Invalid system parameter.")
end

local lSystems = monitor_api.GetSystem()
local lSystemsOrdered = {}
local lCurrentSystem = nil
local lTerm = term.current()
local lMonitor = nil

if args["monitor"] then
	lMonitor = args["monitor"][1]
	lTerm = peripheral.wrap(lMonitor)
	
	if not lTerm then
		error("Monitor not found: " .. lMonitor .. ".")
	end
end

if args["text_scale"] then
	lTerm.setTextScale(tonumber(args["text_scale"][1]))
end

local cTermWidth, cTermHeight = lTerm.getSize()

local cWinWidth = cTermWidth
local cWinHeight = cTermHeight - 2

local cContentWindow = window.create(lTerm, 1, 2, cWinWidth, cWinHeight, true)
local cStatusColours = {}

cStatusColours[monitor_api.STATUS_EXCELLENT] = {
	text = colors.black,
	back = colors.green
}
cStatusColours[monitor_api.STATUS_GOOD] = {
	text = colors.black,
	back = colors.yellow
}
cStatusColours[monitor_api.STATUS_FAIR] = {
	text = colors.black,
	back = colors.orange
}
cStatusColours[monitor_api.STATUS_POOR] = {
	text = colors.black,
	back = colors.red
}
cStatusColours[monitor_api.STATUS_TERRIBLE] = {
	text = colors.white,
	back = colors.black
}

local function DrawHeader(aTitle)
	lTerm.setCursorPos(1, 1)
	lTerm.setTextColor(colors.black)
	lTerm.setBackgroundColor(colors.lightGray)
	
	lTerm.clearLine()
	
	lTerm.write(aTitle)
end

local function ClearPanel()
	cContentWindow.setBackgroundColor(colors.black)
	
	cContentWindow.clear()
	cContentWindow.setCursorPos(1, 1)
end

local function DrawMenu()
	DrawHeader("Systems")
	
	ClearPanel()
	
	lTerm.setCursorPos(1, cTermHeight)
	lTerm.setBackgroundColor(colors.gray)
	
	lTerm.clearLine()
	
	local line = 1
	
	for _, system in ipairs(lSystemsOrdered) do
		local status = system.proc(monitor_api.PROC_GET_STATUS)
		local title = system.proc(monitor_api.PROC_GET_TITLE)
		
		if type(title) ~= "string" then
			title = "<MISSING TITLE: " .. system.name .. ">"
		end
		
		local statusColors = cStatusColours[status]
		
		if not statusColors then
			statusColors = cStatusColours[monitor_api.STATUS_FAIR]
		end
		
		cContentWindow.setTextColor(statusColors.text)
		cContentWindow.setBackgroundColor(statusColors.back)
		cContentWindow.setCursorPos(1, line)
		
		cContentWindow.clearLine()
		cContentWindow.write(title)
		
		line = line + 1
	end
end

local function DrawSystem(aSystem)
	DrawHeader(aSystem.name)
	
	ClearPanel()
	
	lTerm.setCursorPos(1, cTermHeight)
	lTerm.setBackgroundColor(colors.gray)
	
	lTerm.clearLine()
	
	lTerm.setTextColor(colors.black)
	lTerm.setBackgroundColor(colors.lightGray)
	
	lTerm.write("Back")
	
	term.redirect(cContentWindow)
	
	aSystem.proc(monitor_api.PROC_DRAW)
	
	term.redirect(term.native())
end

local function DrawPanel()
	if lCurrentSystem then
		DrawSystem(lCurrentSystem)
	else
		DrawMenu()
	end
end

local function OnInput(aX, aY)
	if lCurrentSystem then
		if aY == 1 then
			return
		elseif aY == cTermHeight then
			if aX <= 4 then
				lCurrentSystem = nil
				
				DrawPanel()
			end
			
			return
		end
		
		lCurrentSystem.proc(monitor_api.PROC_CLICK, aX, aY - 1)
	else
		if aY > 1 and aY - 1 <= #lSystemsOrdered then
			lCurrentSystem = lSystemsOrdered[aY - 1]
			
			DrawPanel()
		end
	end
end

local programs = fs.list("monitor/programs")

for _, file in ipairs(programs) do
	local absoluteFile = "monitor/programs/" .. file
	
	if not fs.isDir(absoluteFile) then
		shell.run(absoluteFile)
	end
end

for id, system in pairs(lSystems) do
	if args["system"]
		and args["system"][1] == id then
		lCurrentSystem = system
	end
	
	table.insert(lSystemsOrdered, system)
end

query.SetProc("MONITOR_UPDATED", function(aId)
	if lCurrentSystem and aId ~= lCurrentSystem.id then
		return
	end
	
	DrawPanel()
end)

if lMonitor then
	signal.Hook("monitor_touch", function(_, aMonitor, aX, aY)
		if aMonitor ~= lMonitor then
			return
		end
		
		OnInput(aX, aY)
	end)
else
	signal.Hook("mouse_up", function(_, aButton, aX, aY)
		if aButton ~= 1 then
			return
		end
		
		OnInput(aX, aY)
	end)
end

DrawPanel()

if not args["non_blocking"] then
	while true do
		os.pullEvent()
	end
end
