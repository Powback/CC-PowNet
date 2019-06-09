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
end

function RegisterDrone(p_ID, p_Pos, p_Heading)
    local s_DroneName = "D" .. DATA["lastDrone"]

    DATA["lastDrone"] = DATA["lastDrone"] + 1
    DATA["drones"][p_ID] = {
        id = p_ID,
        pos = p_Pos,
        status = "idle",
        name = s_DroneName,
        role = "peasant"
    }

    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "AllocateDocking", {id = p_ID})
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
    for k,v in pairs(p_Message.data) do
        DATA["drones"][p_ID][k] = v
    end

    return true
end

function OnRegisterDrone(p_ID, p_Message)
    print("New Drone")
    local s_Result, s_Data = RegisterDrone(p_ID, p_Message.data.pos, p_Message)
    return true, s_Data
end

function OnRestartDrones(p_ID, p_Message)
    print("Restarting drones")
    if(p_Message.range ~= nil) then

    else

    end

    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "Reboot", {})
    local s_Response = PowNet.SendToAllDrones(s_Message)
    return true
end

function OnDockDrones(p_ID, p_Message)
    print("Docking drones")
    if(p_Message.range ~= nil) then

    end
    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "GetDroneInfo", {})
    local s_Response = PowNet.Send("DockingMan", s_Message)
    if(type(s_Response) == "table") then
        for k,v in pairs(s_Response.drones) do
            local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "GoTo", {pos = v.pos, heading = v.heading})
            local s_Response = PowNet.SendToDrone(k, s_Message)
        end
    end

    return true
end

local m_DroneEvents = {
    Heartbeat = OnHeartbeat,
}

local m_ServerEvents = {
    RegisterDrone = OnRegisterDrone,
    Heartbeat = OnHeartbeat,

    RestartDrones = {
        func = OnRestartDrones,
        callable = true,
        params = {
            range = {
                optional = true
            }
        }
    },
    DockDrones = {
        func = OnDockDrones,
        callable = true,
        params = {
            range = {
                optional = true
            }
        }
    },
    GoTo = {
        func = OnGoTo,
        callable = true,
        params = {
            id = {
                optional = true
            },
            range = {
                optional = true
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
