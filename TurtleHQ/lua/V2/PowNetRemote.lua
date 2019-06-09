local tArgs = {...}
local m_Callable = {}
os.loadAPI("PowNet")
-- OPEN REDNET
if(os.getComputerLabel() == nil) then
    print("Please set the label first.")
    return
end
for _, side in ipairs({"left", "right"}) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
    end
end
if not rednet.isOpen() then
    printError("Could not open rednet")
    return
end

s_Connected, DATA = PowNet.Connect()

PowNet.UpdateModule("PowNet")
PowNet.UpdateModule("PowNetRemote.lua", "pnr")

function CallCallable(module, func, params)
    if(params == nil) then
        print("No params specified")
        return
    end
    local x,y,z = gps.locate()

    if x then
        x = math.floor(x)
        y = math.floor(y) - 1
        z = math.floor(z)

        params.gps = {x = x, y = y, z = z}
    end

    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, func, params)
    local s_Result = PowNet.sendAndWaitForResponse(module, s_Message)
    if(type(s_Result) == "table") then
        print(s_Result.message)
    else
        print(s_Result)
    end
end

local numArgs = # tArgs

function ResolveVars(p_Callable)
    local s_Vars = {}
    for l_paramName,l_param in pairs(p_Callable.params) do
        for i,value in pairs(tArgs) do
            if value:lower() == "-"..l_paramName:lower() then
                -- Param has a length of 1
                if(l_param.length ~= nil) then
                    -- Flag
                    if(l_param.length == 0) then
                        s_Vars[l_paramName] = true
                    elseif tArgs[(i + 1) + l_param.length] ~= nil then
                        s_Vars[l_paramName] = {}
                        for argIndex = i + 1, l_param.length, 1 do
                            s_Vars[l_paramName][argIndex] = tArgs[(i + 1) + argIndex]:lower()
                        end
                    end
                else
                    -- Single var
                    if( tArgs[i + 1] ~= nil) then
                        s_Vars[l_paramName] = tArgs[i + 1]:lower()
                    end
                end
            end
        end
    end
    return s_Vars
end

function Start()
    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.REGISTER, "GetCallable")
    local s_Result = PowNet.sendAndWaitForResponse(-1, s_Message)
    if(type(s_Result) == "table") then
        m_Callable = s_Result
        if numArgs == 0 then
            print("Modules: ")
        end
        for k,v in pairs(s_Result) do
            if(numArgs == 0) then
                print(" -" .. k)
            end
        end
        if tArgs[1] == nil then
            return
        end
    else
        print(s_Result)
    end

    if not m_Callable[tArgs[1]] then
        print("Module not found")
        print(PowNet.dump(m_Callable))
        return
    end

    local s_Callable = m_Callable[tArgs[1]]
    --print(PowNet.dump(s_Callable))
    if tArgs[2] == nil then
        print("Functions:")
        for k,v in pairs(s_Callable) do
            print(" -" .. v.name)
        end
        return
    end
    if not s_Callable[tArgs[2]] then
        print("Function not found")
        return
    end
    if (tArgs[3] == nil or tArgs [3] == "?") then
        print("Params:")
        for k,v in pairs(s_Callable[tArgs[2]].params) do
            print(" -" .. k)
        end
        return
    end
    local s_Params = ResolveVars(s_Callable[tArgs[2]])
    CallCallable(tArgs[1], tArgs[2], s_Params)
end

Start()