-- TankStation
os.loadAPI("pgps")
local x,y,z
local m_Status = "idle"
local executing = false

print("I AM ALIVE!")

function TaskStart()
    executing = true
end
function TaskEnd()
    executing = false
    pgps.StartExec() -- Task has ended, allow force allow execution agian.
end

function Init()
    pgps.startGPS()
    x,y,z = pgps.setLocationFromGPS()
    if(os.getComputerLabel() == nil) then
        print("Who am i...?")
        if(x == nil or y == nil or z == nil) then
            print("I have no GPS, my battery is low and it’s getting dark...")
            return
        end
        local s_Fuel = turtle.getFuelLevel()
        local s_Data = {id = os.getComputerID(), pos = {x = x, y = y, z = z}, fuel = s_Fuel}
        local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "RegisterDrone", s_Data)
        local s_Response = PowNet.sendAndWaitForResponse("DroneMan", s_Message, PowNet.SERVER_PROTOCOL)
        if(not s_Response) then
            print("Failed to call home.")
            return false
        end
        if(type(s_Response) ~= "table") then
            print("response: " .. s_Response)
            return false
        end
        print(s_Response)
        os.setComputerLabel(s_Response.name)
        print("I am " .. s_Response.name .. ", and I am here to serve.")

        if(s_Response.go) then
            print("Docking!")
            print(s_Response.go.x)
            print(s_Response.go.y)
            print(s_Response.go.z)
            print(s_Response.heading)
            print(pgps.moveTo(s_Response.go.x, s_Response.go.y, s_Response.go.z))
            print(pgps.turnTo(s_Response.heading))
        end
    end

    SendHeartBeat()
end

function SendHeartBeat()
    x,y,z = pgps.setLocationFromGPS()

    local s_Pos = nil
    if(x == nil or y == nil or z == nil) then
        print("I have no GPS signal.")
    else
        s_Pos = {x = x, y = y, z = z}
    end
    local s_Fuel = turtle.getFuelLevel()

    local s_Data = {pos = s_Pos, status = m_Status, fuel = s_Fuel}
    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "Heartbeat", s_Data)
    PowNet.SendToServer("DroneMan", s_Message)
    print("Sent heartbeat")
end

function OnReboot(p_ID, p_Message)
    os.reboot()
end

function OnGoTo(p_ID, p_Message)
    print(os.time())
    x,y,z = pgps.setLocationFromGPS()
    if(p_Message.data.pos == nil) then
        print("No pos specified")
        return
    end
    m_Status = "moving"

    TaskStart()
    local s_Status, s_message = pgps.moveTo(p_Message.data.pos.x, p_Message.data.pos.y, p_Message.data.pos.z)
    TaskEnd()
    m_Status = "idle"
    if(s_Status == false) then
        print("Failed to move to position")
        return false, "Failed to move to position"
    end
    if(p_Message.data.heading == nil) then
        print("No heading specified")
    else
        m_Status = "rotation"
        print(pgps.turnTo(p_Message.data.heading))
        m_Status = "idle"
    end
end


function OnAbort()
    if(not executing) then
        return false
    end
    print("Aborting...")
    pgps.BreakExec()
    return true, "Aborted"
end


function OnStartTask(p_ID, p_Message)

end

function OnAbortTask(p_ID, p_Message)

end



local m_DroneEvents = {
    Reboot = {
        func = OnReboot,
    },
    GoTo = {
        func = OnGoTo,
    }
}


local m_ServerEvents = { -- Runs on a different thread so that we can interrupt drones while they execute work on the Drone message thread.
    Abort = {
        func = OnAbort,
    },
    StartTask = {
        func = OnStartTask
    },
    AbortTask = {
        func = OnAbortTask
    },
}

if Init() == false then
    return
end


PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents)
parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)