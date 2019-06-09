--DroneMan
--Goal: Handle drones and their status

local m_Monitor = peripheral.wrap("top")

Log("Starting...")
function Init()
    if DATA["lastDrone"] == nil then
        DATA["lastDrone"] = 1
    end
    if DATA["drones"] == nil then
        DATA["drones"] = {}
    end
    if DATA["ids"] == nil then
        DATA["ids"] = {}
    end
end

function GetDroneIDByCCID(p_ID)
    return DATA["ids"][p_ID]
end

function RegisterDrone(p_ID, p_Pos, p_Heading)
    local s_DroneName = "D" .. DATA["lastDrone"]
    local s_DroneID = tostring(DATA["lastDrone"])

    DATA["lastDrone"] = DATA["lastDrone"] + 1
    DATA["drones"][s_DroneID] = {
        droneID = s_DroneID,
        id = p_ID,
        pos = p_Pos,
        status = "idle",
        name = s_DroneName,
        role = "peasant"
    }
    DATA["ids"][p_ID] = s_DroneID

    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "AllocateDocking", {id = s_DroneID})
    local s_Response = PowNet.sendAndWaitForResponse("DockingMan", s_Message)
    if(not s_Response) then
        print("Failed to get docking")
        return false, "Failed to get docking"
    end
    if(type(s_Response) ~= "table") then
        print("wtf")
        return false, s_Response
    end
    return true, {name = s_DroneName, go = s_Response.pos, heading = s_Response.heading}
end

function OnHeartbeat(p_ID, p_Message)
    local s_ID = GetDroneIDByCCID(p_ID)
    for k,v in pairs(p_Message.data) do
        DATA["drones"][s_ID][k] = v
    end

    return true
end

function GetDroneByID(p_Id)
    return DATA["drones"][(tostring(p_Id))]
end

function GetDronesByRange(p_Min, p_Max)
    local s_Drones = {}
    for i = tonumber(p_Min), tonumber(p_Max), 1 do
        if(DATA["drones"][tostring(i)] ~= nil) then
            table.insert(s_Drones, DATA["drones"][tostring(i)].id)
        end
    end
end

function ParseMessage(p_Message)
    if(p_Message.data.pos == nil and p_Message.data.gps ~= nil) then
        p_Message.data.pos = p_Message.data.gps
    end

    local s_Drones = {}
    if(p_Message.data.id) then
        if(tostring(p_Message.data.id) == "-1") then
            for k,v in pairs (DATA["drones"]) do
                table.insert(s_Drones, v.id)
            end
        else
            if(DATA["drones"][tostring(p_Message.data.id)] == nil) then
                return false, "Could not find drone with ID: " .. tostring(p_Message.data.id)
            end
            table.insert(s_Drones, DATA["drones"][tostring(p_Message.data.id)].id)
        end
    end

    if(p_Message.data.range) then
        for i = tonumber(p_Message.data.range[1]), tonumber(p_Message.data.range[2]), 1 do
            if(DATA["drones"][tostring(i)] ~= nil) then
                table.insert(s_Drones, DATA["drones"][tostring(i)].id)
            end
        end
    end
    p_Message.data.drones = s_Drones
    return true, p_Message
end



function OnRegisterDrone(p_ID, p_Message)
    print("New Drone")
    local s_Result, s_Data = RegisterDrone(p_ID, p_Message.data.pos, p_Message)
    return s_Result, s_Data
end

function OnRestartDrones(p_ID, p_Message)
    print("Restarting drones")
    if(p_Message.range ~= nil) then

    else

    end

    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "Reboot", {})
    local s_Response = PowNet.SendToAllDrones(s_Message)
    return true, "Dispatched restart"
end

function OnDockDrones(p_ID, p_Message)
    print("Docking drones")
    if(p_Message.data.id == nil and p_Message.data.range == nil) then
        return false, "Missing id/range"
    end

    local p_Message = ParseMessage(p_Message)

    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "GetDroneInfo", {})
    local s_Response = PowNet.sendAndWaitForResponse("DockingMan", s_Message)
    if(type(s_Response) == "table") then
        local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "GoTo", {pos = v.pos, heading = v.heading})
        local s_Response = PowNet.SendToDrone(k, s_Message)
    end

    return true
end

function OnGoTo(p_ID, p_Message)
    if(p_Message.data.pos == nil and p_Message.data.gps == nil) then
        return false, "Missing pos"
    end
    if(p_Message.data.id == nil and p_Message.data.range == nil) then
        return false, "Missing id/range"
    end

    local s_Status, s_Mesage = ParseMessage(p_Message)
    if(s_Status == false) then
        return s_Status, s_Mesage
    end
    for k,v in pairs(s_Mesage.data.drones) do

        local s_AbortMessage = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "Abort", {})
        local s_AbortResponse = PowNet.sendAndWaitForResponse(v, s_AbortMessage, PowNet.SERVER_PROTOCOL) -- Override the current drone action
        if(s_AbortResponse) then
           os.sleep(1) -- Wait for abortion to complete. Takes 1 tick.
        end

        local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "GoTo", {pos = p_Message.data.pos})
        local s_GoToResponse = PowNet.SendToDrone(v, s_Message)
        print(s_GoToResponse)
        print("Sent to: " .. v)
    end

    return true
end

local m_DroneEvents = {
    Heartbeat = OnHeartbeat,
}

local m_ServerEvents = {
    RegisterDrone = OnRegisterDrone,
    Heartbeat = OnHeartbeat,

    RestartDrone = {
        func = OnRestartDrones,
        callable = true,
        params = {
            id = {
                optional = true,
                type = "number"
            },
            range = {
                optional = true,
                type = "vec2"
            }
        }
    },
    DockDrones = {
        func = OnDockDrones,
        callable = true,
        params = {
            range = {
                optional = true,
                type = "vec2"
            }
        }
    },
    GoTo = {
        func = OnGoTo,
        callable = true,
        params = {
            id = {
                optional = true,
                length = 1,
                type = "number"
            },
            range = {
                optional = true,
                length = 2,
                type = "vec2"
            }
        }
    }
}

function Render()
    print("Render!")
    m_Monitor.clear()
    m_Monitor.setCursorPos(1,1)
    m_Monitor.setTextScale(0.5)
    -- Header
    m_Monitor.write("DroneMan!")
    local i = 1
    local left = true
    for k,v in pairs(DATA["drones"]) do
        local s_Turtle = DATA["drones"][k]
        if(left) then
            m_Monitor.setCursorPos(1,i)
            left = false
        else
            m_Monitor.setCursorPos(45,i)
            left = true
            i = i + 1
        end
        local s_Fuel = s_Turtle.fuel
        if s_Fuel == nil then
            s_Fuel = "?"
        end
        m_Monitor.write("[" .. s_Turtle.name .. "] | " .. s_Turtle.status .." | " .. s_Fuel .. " - (" .. s_Turtle.pos.x .. ", " .. s_Turtle.pos.y .. ", " .. s_Turtle.pos.z ..")")

    end
end


Init()
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents, Render)

SetStatus("Connected!", colors.green)

Render()
parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)

print("Unhosting")
rednet.unhost(PowNet.SERVER_PROTOCOL)
