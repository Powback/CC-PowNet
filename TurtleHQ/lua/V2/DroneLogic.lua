-- TankStation
os.loadAPI("pgps")
local x,y,z
local m_Status = "idle"


print("I AM ALIVE!")
pgps.startGPS()
x,y,z = pgps.setLocationFromGPS()


function Init()
    if(DATA["world"] == nil) then
        DATA["world"] = {}
    end



    if(os.getComputerLabel() == nil) then
        print("Who am i...?")
        if(x == nil or y == nil or z == nil) then
            print("I have no GPS, my battery is low and it’s getting dark...")
            return
        end
        local s_Data = {id = os.getComputerID(), pos = {x = x, y = y, z = z}}
        local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "RegisterDrone", s_Data)
        local s_Response = PowNet.sendAndWaitForResponse("DroneMan", s_Message, PowNet.SERVER_PROTOCOL)
        if(not s_Response) then
            print("Failed to call home.")
            return false
        end
        if(not type(s_Response == "table")) then
            print(s_Response)
            return
        end
        print(s_Response)
        os.setComputerLabel(s_Response.name)
        print("I am " .. s_Response.name .. ", and I am here to serve.")
        print("Allfather give me sight!")
        --local s_WorldRequestMessage = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "LoadWorld", {id = os.getComputerID()})
        --local s_WorldRequestResponse = PowNet.sendAndWaitForResponse("MapServer", s_Message, PowNet.DRONE_PROTOCOL)
        print(s_Response)
        for k,v in pairs(s_Response) do
            print(k)
        end
        print("^^^")
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
end

function SendHeartBeat()
    x,y,z = pgps.setLocationFromGPS()

    if(x == nil or y == nil or z == nil) then
        print("I have no GPS signal.")
        return
    end
    local s_Data = {pos = {x = x, y = y, z = z}, status = m_Status}
    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "Heartbeat", s_Data)
    PowNet.Send("DroneMan", s_Message, PowNet.DRONE_PROTOCOL)
end

local m_DroneEvents = {

}

local m_ServerEvents = {

}


if Init() == false then
    return
end
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents, Render)
parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)