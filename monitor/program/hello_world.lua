
if not monitor_api and not os.loadAPI("monitor/monitor_api") then
    error("Requied API not installed: monitor/monitor_api.")
end

local cId = "dc95ee43-bfed-4b13-875b-ae4e927de8e1"

local function Proc(aProc, ...)
    if aProc == monitor_api.PROC_GET_STATUS then
        return monitor_api.STATUS_EXCELLENT
    elseif aProc == monitor_api.PROC_GET_TITLE then
        return "Hello"
    elseif aProc == monitor_api.PROC_DRAW then
        print("Hello world!")
    end
end

monitor_api.AddSystem(cId, "HelloWorld", Proc)