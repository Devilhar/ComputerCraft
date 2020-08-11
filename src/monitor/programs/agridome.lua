
if not monitor_api and not os.loadAPI("monitor/monitor_api") then
	error("Requied API not installed: monitor/monitor_api.")
end

local cId			= "f9e9d8a3-3886-4718-817f-620ec7acbeb7"
local cHostname		= "agridome"

local cSeedTypeResetType = "RESET"

local cSeedTypeReset = { type = cSeedTypeResetType, name = "None", color = colors.gray }

local cTextColor = {}
cTextColor[colors.white]		= colors.black
cTextColor[colors.orange]		= colors.black
cTextColor[colors.magenta]		= colors.black
cTextColor[colors.lightBlue]	= colors.black
cTextColor[colors.yellow]		= colors.black
cTextColor[colors.lime]			= colors.black
cTextColor[colors.pink]			= colors.black
cTextColor[colors.gray]			= colors.black
cTextColor[colors.lightGray]	= colors.black
cTextColor[colors.cyan]			= colors.black
cTextColor[colors.purple]		= colors.black
cTextColor[colors.blue]			= colors.black
cTextColor[colors.brown]		= colors.black
cTextColor[colors.green]		= colors.black
cTextColor[colors.red]			= colors.black
cTextColor[colors.black]		= colors.white

local lOnline			= true
local lFields			= nil
local lFieldsIndexed	= nil
local lSeedTypes		= nil
local lSeedTypesIndexed	= nil
local lSelectedField	= nil
local lSelectedIndex	= 1
local lMessage			= nil

local function HasData()
	return lOnline
		and lFields
		and lSeedTypes
end

local function Redraw()
	monitor_api.Updated(cId)
end

local function FetchData()
    local result, err, payload = tp.Get(cHostname, nil, "seed")
	
	if not result then
		lOnline = false
		lFields = nil
		
		Redraw()
		
		return
	end
	
	lFields = payload.fields
	
    local result, err, payload = tp.Get(cHostname, nil, "types")
	
	if not result then
		lOnline = false
		
		Redraw()
		
		return
	end
	
	lOnline = true
	
	lSeedTypes = payload.types
	lSeedTypesIndexed = {}
	lFieldsIndexed = {}
	
	for _, field in pairs(lFields) do
		table.insert(lFieldsIndexed, field)
	end
	for k, seedType in pairs(lSeedTypes) do
		seedType.type = k
		table.insert(lSeedTypesIndexed, seedType)
	end
	
	lSeedTypes[cSeedTypeReset.type] = cSeedTypeReset
	table.insert(lSeedTypesIndexed,	cSeedTypeReset)
	
	Redraw()
end
 
local function SetFieldType(aField, aType)
	lMessage = "Processing..."
	
	Redraw()
	
	if aType == cSeedTypeResetType then
		aType = nil
	end
	
    local result, err = tp.Post(cHostname, nil, "seed", { field = aField, type = aType }, 10)
	
	lMessage = nil
	
    FetchData()
end

local function DrawMessage()
	local width, height = term.getSize()

	term.setCursorPos(1, height)
	term.setBackgroundColor(colors.black)
	term.setTextColor(cTextColor[colors.black])
	
	term.clearLine()
	
	if lMessage then
		write(lMessage)
	end
end

local function DrawFieldSlot(aFieldType, aX, aY)
	term.setCursorPos(aX, aY)
	
	if not aFieldType then
		aFieldType = cSeedTypeResetType
	end
	
	local seedName = aFieldType
	local seedType = lSeedTypes[aFieldType]
	
	if seedType then
		seedName = seedType.name
		term.setBackgroundColor(seedType.color)
		term.setTextColor(cTextColor[seedType.color])
	else
		term.setBackgroundColor(colors.black)
		term.setTextColor(cTextColor[colors.black])
	end
	
	for i = string.len(seedName) + 1, 13 do
		seedName = seedName .. " "
	end
	
	write(seedName)
end

local function DrawFields()
	for i, field in ipairs(lFieldsIndexed) do
		DrawFieldSlot(field.type, 1, i)
	end
end

local function DrawFieldSelection()
	DrawFieldSlot(lSelectedField.type, 1, lSelectedIndex)
	
	for i, seedType in ipairs(lSeedTypesIndexed) do
		DrawFieldSlot(seedType.type, 14, i)
	end
end

local function Draw()
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(1, 1)
	
	term.clear()
	
	if not HasData() then
		write("Unable to fetch data.")
		
		return
	end
	
	DrawMessage()
	
	if lSelectedField then
		DrawFieldSelection()
	else
		DrawFields()
	end
end

local function OnClick(aX, aY)
	if not HasData() then
		return
	end
	
	if lSelectedField then
		if aX <= 13 then
			lSelectedField = nil
			
			Redraw()
			
			return
		end
		
		if aX > 26 or aY > #lSeedTypesIndexed then
			return
		end
		
		local field = lSelectedField.field
		local seedType = lSeedTypesIndexed[aY].type
		
		lSelectedField = nil
		
		SetFieldType(field, seedType)
		
	else
		if aX > 13 or aY > #lFieldsIndexed then
			return
		end
		
		lSelectedField = lFieldsIndexed[aY]
		lSelectedIndex = aY
		
		Redraw()
	end
end

local function Proc(aProc, ...)
	if aProc == monitor_api.PROC_GET_STATUS then
		if not lOnline then
			return monitor_api.STATUS_POOR
		end
		
		return monitor_api.STATUS_EXCELLENT
	elseif aProc == monitor_api.PROC_GET_TITLE then
		if not lOnline then
			return "Agridome: Offline"
		end
		
		return "Agridome: Online"
	elseif aProc == monitor_api.PROC_DRAW then
		Draw()
	elseif aProc == monitor_api.PROC_CLICK then
		OnClick(...)
	end
end

local timerUpdate = nil

local function Update()
	FetchData()
end

signal.Hook("timer", function(_, aTimer)
	if aTimer ~= timerUpdate then
		return
	end
	
	Update()
	
	timerUpdate = os.startTimer(30)
end)

monitor_api.AddSystem(cId, "Agridome", Proc)

timerUpdate = os.startTimer(1)
