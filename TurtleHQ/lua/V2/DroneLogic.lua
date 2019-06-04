-- TankStation
os.loadAPI("netNav")
local x,y,z
local m_Status = "idle"
-- LOAD NETNAV API
if not netNav then
    if not os.loadAPI("netNav") then
        error("could not load netNav API")
    end
end
-- SET NETNAV MAP
netNav.setMap("PowMap", 15) -- the second argument determines how frequently the turtle will check with the server for newer map data

print("I AM ALIVE!")
x,y,z = netNav.getPosition()


function Init()
    if(os.getComputerLabel() == nil) then
        print("Who am i...?")
        if(x == nil or y == nil or z == nil) then
            print("I have no GPS, my battery is low and it’s getting dark...")
            return
        end
        local s_Data = {id = os.getComputerID(), pos = {x = x, y = y, z = z}}
        local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "RegisterDrone", s_Data)
        local s_Response = PowNet.sendAndWaitForResponse("DroneMan", s_Message, PowNet.DRONE_PROTOCOL)
        if(s_Response == false) then
            print("Failed to call home.")
            return
        end
        os.setComputerLabel(s_Response)
        print("I am " .. s_Response .. ", and I am here to serve.")
    end
end
function SendHeartBeat()
    x,y,z = netNav.getPosition()
    if(x == nil or y == nil or z == nil) then
        print("I have no GPS signal.")
        return
    end
    local s_Data = {pos = {x = x, y = y, z = z}, status = m_Status}
    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "Heartbeat", s_Data)
    PowNet.Send("DroneMan", s_Message, PowNet.DRONE_PROTOCOL)
end
function OnBoot()
    SendHeartBeat()
end
Init()
OnBoot()



parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)