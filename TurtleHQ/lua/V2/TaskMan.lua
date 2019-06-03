--DroneMan
--Goal: Handle drones and their status

local m_Data
Log("Starting...")

--===== UTILS =====--
local receivedMessages = {}
local receivedMessageTimeouts = {}


--===== MAIN =====--
local function main()
    while true do
        local serverID, serverMessage = rednet.receive(PowNet.SERVER_PROTOCOL)
        if type(serverMessage) == "table" then
            if(serverMessage.type == PowNet.MESSAGE_TYPE.INIT and serverMessage.ID == 0) then
                print("Server has been initialized. Rebooting and performing updates.")
                os.reboot()
            end
        end

        local droneID, droneMessage = rednet.receive(PowNet.DRONE_PROTOCOL)
        if type(droneMessage) == "table" then

        end
    end
end

SetStatus("Connected!", colors.green)
print("Waiting for signal...")
parallel.waitForAny(main, PowNet.control)
rednet.unhost(PowNet.SERVER_PROTOCOL)
