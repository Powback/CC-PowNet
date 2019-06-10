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
PowNet.UpdateModule("PowNetRemote.lua", "p")

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

                if(l_param.length ~= nil and l_param.length ~= 1) then
                    -- Flag
                    if(l_param.length == 0) then
                        s_Vars[l_paramName] = true
                    elseif tArgs[i + l_param.length] ~= nil then
                        s_Vars[l_paramName] = {}
                        for argIndex = 1, l_param.length, 1 do
                            s_Vars[l_paramName][argIndex] = tArgs[i + argIndex]:lower()
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

function IsOption(p_Input, p_Options)
    if(p_Input == nil or p_Options == nil) then
        return false
    end
    if (p_Options[p_Input] == nil) then
        return false
    end
    return true
end
function getVal(p_Val, p_OptionName)
    if(type(p_Val) == "table") then
        local s_Ret = ""
        local s_Padding = ""
        for k,v in pairs(p_Val) do
            if(type(v) == "table") then
                s_Ret = s_Ret .. "-: " .. k .."\n".. getVal(v) .. "\n"
            else
                s_Ret = s_Ret .. " " .. k ..": " .. tostring(v)
            end
        end
        return s_Ret
    end
    if(type(p_Val) == "string") then
        return p_Val
    end
end
function ParseOptions(p_Options, p_Answers)
    for optionName,option in pairs(p_Options) do
        if(optionName ~= "message" and optionName ~= "type" and optionName ~= "optional") then
            if(option.optional == true) then
                term.setTextColor( colors.yellow )

            elseif(option.optional == false) then
                term.setTextColor( colors.red )

            elseif(option.optional == nil) then
                term.setTextColor( colors.white )
            end
            if(p_Answers[optionName] ~= nil) then
                term.setTextColor( colors.green )
            end
            print("-" ..optionName)
            if(p_Answers[optionName] ~= nil) then

                term.setTextColor( colors.gray )
                print(getVal(p_Answers[optionName], optionName))
            end
            term.setTextColor( colors.white )
        end
    end
end

function SelectOption(p_Options, s_Answers)
    local s_OptionName = nil
    while(IsOption(s_OptionName, p_Options) == false) do
        print("")
        print("Options:")
        ParseOptions(p_Options, s_Answers)
        print("Enter option:")
        s_OptionName = read()

        if(s_OptionName == "") then
            return false
        end
        if(IsOption(s_OptionName, p_Options) == false) then
            print("Invalid option.")
        end
    end
    return s_OptionName, p_Options[s_OptionName]
end

function SelectSingleOption(p_Installer, p_Answers)
    print("Select an option")
    local s_Send = false
    if(p_Answers == nil) then
        p_Answers = {}
    end
    while(s_Send == false) do
        local s_OptionName, s_CurrentOption = SelectOption(p_Installer, p_Answers)
        if(s_OptionName == false) then
            s_Send = true
        else
            local s_Value = ParseValue(s_CurrentOption.type, s_CurrentOption, p_Answers[s_OptionName])
            p_Answers[s_OptionName] = s_Value
            return p_Answers
        end
    end
    return false
end

function ParseValue(p_Type, p_CurrentOption, p_Answers)
    if(p_Type == "string") then
        print("Enter value:")
        return read()
    end
    if(p_Type == "int") then
        while(true) do
            print("Enter value:")
            local s_Value = read()
            if(tonumber(s_Value) ~= nil) then
                return s_Value
            end
            print("Not a number.")
        end
    end
    if p_Type == "option" then
        return SelectSingleOption(p_CurrentOption, p_Answers)
    end
    if p_Type == "list" then
        return RunInstaller(p_CurrentOption, p_Answers)
    end
    if(p_Type == "vec3") then
        while true do
            print("VEC3: x y z")
            print("GPS: enter")
            local s_Vec3TypeInput = read()
            if(s_Vec3TypeInput == "" or s_Vec3TypeInput == nil) then
                local x,y,z = gps.locate()
                x = math.floor(x)
                y = math.floor(y) - 1
                z = math.floor(z)

                if not x then
                    print("no gps signal available.")
                else

                    return {x = x, y = y, z = z}
                end
            end
        end
    end
end

function RunInstaller(p_Installer, p_Answers)
    print("")--empty line
    local s_Send = false
    if(p_Answers == nil) then
        p_Answers = {}
    end
    while(s_Send == false) do
        local s_OptionName, s_CurrentOption = SelectOption(p_Installer, p_Answers)
        if(s_OptionName == false) then
            s_Send = true
        else
            local s_Value = ParseValue(s_CurrentOption.type, s_CurrentOption, p_Answers[s_OptionName])
            p_Answers[s_OptionName] = s_Value
        end
    end
    return p_Answers
end

function RunInstallerOld(p_Installer)
    local s_TaskName = ""
    local s_WorkParams = {}

    local s_Send = false
    while (s_Send == false) do
        while(IsOption(s_TaskName, p_Installer.params) == false) do
            print("Options:")


            local params = p_Installer.params
            print("Enter option:")
            s_TaskName = read()
        end

        local s_WorkParamName = nil
        local s_ParseParams = true

        while(s_ParseParams == true) do
            while (s_ParseParams and IsOption(s_WorkParamName, p_Installer.params[s_TaskName]) == false ) do
                local s_RequiredCount = 0
                local s_OptionalCount = 0
                if(s_TaskName ~= nil and p_Installer.params[s_TaskName] ~= nil and p_Installer.params[s_TaskName].type ~= nil) then
                    print("Enter value for " .. s_TaskName)
                    s_WorkParams[s_TaskName] = read()
                    s_ParseParams = false
                    s_TaskName = ""
                elseif(s_ParseParams and p_Installer[s_TaskName] == nil) then
                    print("Options:")
                    for k,v in pairs(p_Installer.params[s_TaskName]) do
                        if(k ~= "message" and k ~= "list" and k~= "optional") then
                            if(v.optional == true) then
                                term.setTextColor( colors.yellow )
                                s_OptionalCount = s_OptionalCount+ 1

                            elseif(v.optional == false) then
                                term.setTextColor( colors.red )
                                s_RequiredCount = s_RequiredCount + 1

                            elseif(v.optional == nil) then
                                s_OptionalCount = s_OptionalCount + 1
                                term.setTextColor( colors.white )
                            end
                            print(" - "..k)
                            term.setTextColor( colors.white )
                        end
                    end
                    s_WorkParamName = read()
                    if(s_WorkParamName == "") then -- Enter is pressed
                        s_ParseParams = false
                    elseif(IsOption(s_WorkParamName, p_Installer.params[s_TaskName]) == false) then
                        print("Unknown option: " .. s_WorkParamName)
                    end
                end
            end
            if(s_ParseParams and s_WorkParams[s_TaskName] == nil) then
                local s_Value = nil
                if(p_Installer.params[s_TaskName][s_WorkParamName] ~= nil) then
                    while (s_ParseParams and IsOption(s_WorkParamName, p_Installer.params[s_TaskName]) == false ) do
                        local s_RequiredCount = 0
                        local s_OptionalCount = 0
                        if(s_TaskName ~= nil and p_Installer.params[s_TaskName] ~= nil and p_Installer.params[s_TaskName].type ~= nil) then
                            print("Enter value for " .. s_TaskName)
                            s_WorkParams[s_TaskName] = read()
                            s_ParseParams = false
                            s_TaskName = ""
                        elseif(s_ParseParams and p_Installer[s_TaskName] == nil) then
                            print("Options:")
                            for k,v in pairs(p_Installer.params[s_TaskName]) do
                                if(k ~= "message" and k ~= "list" and k~= "optional") then
                                    if(v.optional == true) then
                                        term.setTextColor( colors.yellow )
                                        s_OptionalCount = s_OptionalCount+ 1

                                    elseif(v.optional == false) then
                                        term.setTextColor( colors.red )
                                        s_RequiredCount = s_RequiredCount + 1

                                    elseif(v.optional == nil) then
                                        s_OptionalCount = s_OptionalCount + 1
                                        term.setTextColor( colors.white )
                                    end
                                    print(" - "..k)
                                    term.setTextColor( colors.white )
                                end
                            end
                            s_WorkParamName = read()
                            if(s_WorkParamName == "") then -- Enter is pressed
                                s_ParseParams = false
                            elseif(IsOption(s_WorkParamName, p_Installer.params[s_TaskName]) == false) then
                                print("Unknown option: " .. s_WorkParamName)
                            end
                        end
                    end
                    if(p_Installer.params[s_TaskName][s_WorkParamName].type == "vec3") then

                    end
                end
                s_WorkParams[s_TaskName][s_WorkParamName] = s_Value
                s_WorkParamName = nil
            end
        end
    end
    print("EOL ")
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
    if(s_Callable[tArgs[2]].installer) then
        local s_Args = RunInstaller(s_Callable[tArgs[2]].params)
        print(PowNet.dump(s_Args))
        local file = fs.open("out.bin", "w")
        file.write(textutils.serialize(s_Args))
        file.close()

        CallCallable(tArgs[1], tArgs[2], s_Args)
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