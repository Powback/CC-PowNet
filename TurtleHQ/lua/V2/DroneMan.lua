--DroneMan
--Goal: Handle drones and their status

local m_Monitor = peripheral.wrap("left")

Log("Starting...")
function Init()
    if DATA["lastDrone"] == nil then
        DATA["lastDrone"] = 0
    end
    if DATA["drones"] == nil then
        DATA["drones"] = {}
    end
end

function RegisterDrone(p_ID, p_Pos)
    local s_DroneName = "D" .. DATA["lastDrone"]

    DATA["lastDrone"] = DATA["lastDrone"] + 1;
    DATA["drones"][p_ID] = {
        id = p_ID,
        pos = p_Pos,
        status = "idle",
        name = s_DroneName
    }
    return s_DroneName
end

function OnHeartbeat(p_ID, p_Message)
    for k,v in pairs(p_Message.data) do
        DATA["drones"][p_ID][k] = v
    end
    return "Hello from the other side"
end

function OnRegisterDrone(p_ID, p_Message)
    print("New Drone")
    local s_DroneName = RegisterDrone(p_ID, p_Message.data.pos)
    return s_DroneName
end

local m_DroneEvents = {
    RegisterDrone = OnRegisterDrone,
    Heartbeat = OnHeartbeat
}

local m_ServerEvents = {

}

function Render()
    print("Render!")
    m_Monitor.clear()
    m_Monitor.setCursorPos(1,1)
    m_Monitor.setTextScale(0.5)
    -- Header
    m_Monitor.write("DroneMan!")
    local i = 1
    for k,v in pairs(DATA["drones"]) do
        local s_Turtle = DATA["drones"][k]
        i = i + 1
        m_Monitor.setCursorPos(1,i)

        m_Monitor.write("[" .. s_Turtle.name .. "] | " .. s_Turtle.status .." | (" .. s_Turtle.pos.x .. ", " .. s_Turtle.pos.y .. ", " .. s_Turtle.pos.z ..")")
    end
end


Init()
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents, Render)

SetStatus("Connected!", colors.green)

Render()
parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)

print("Unhosting")
rednet.unhost(PowNet.SERVER_PROTOCOL)
