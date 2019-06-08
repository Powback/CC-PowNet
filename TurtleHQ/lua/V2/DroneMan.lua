--DroneMan
--Goal: Handle drones and their status

local m_Monitor = peripheral.wrap("left")

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
    print(s_Data)
    return true, s_Data
end

local m_DroneEvents = {
    Heartbeat = OnHeartbeat
}

local m_ServerEvents = {
    RegisterDrone = OnRegisterDrone,
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
parallel.waitForAny(PowNet.main, PowNet.control)

print("Unhosting")
rednet.unhost(PowNet.SERVER_PROTOCOL)
