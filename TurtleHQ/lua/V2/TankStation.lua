--TANKSTATION
--Goal: Handle drones and their status

local REDNET_TIMEOUT = 1
local m_Data

--===== OPEN REDNET =====--
for _, side in ipairs(redstone.getSides()) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
    end
end

if not rednet.isOpen() then
    printError("could not open rednet")
    return
end

Log("Starting...")

--===== SET REDNET PROTOCOL =====--
local POWNET_SERVER_PROTOCOL = "PowNet:Server"
local POWNET_DRONE_PROTOCOL = "PowNet:Drone"
local MAINFRAME_ID =  nil



--===== HOST AS SERVER =====--
do
    local host = rednet.lookup(POWNET_SERVER_PROTOCOL, "TANKSTATION")
    if host and host ~= os.computerID() then
        printError("PowNet TANKSTATION server already running?")
        return
    end
end

rednet.host(POWNET_SERVER_PROTOCOL, "TANKSTATION")
rednet.host(POWNET_DRONE_PROTOCOL, "TANKSTATION")

--===== UTILS =====--
local MESSAGE_TYPE = {
    GET = 0,
    SET = 1,
    INIT = 2,
    REGISTER = 3,
    UPDATE = 4
}
local receivedMessages = {}
local receivedMessageTimeouts = {}


local function newMessage(messageType, dataKey, data)
    return {
        type = messageType,
        ID = math.random(0, 2^30),
        dataKey = dataKey,
        data = data,
    }
end


local function sendAndWaitForResponse(recipientID, message, protocol)
    rednet.send(recipientID, message, protocol)
    local attemptNumber = 1
    while true do
        local senderID, reply = rednet.receive(protocol, REDNET_TIMEOUT)
        if senderID == recipientID and type(reply) == "table" and reply.type == message.type and reply.ID == message.ID then
            return reply.data
        elseif not senderID then
            if attemptNumber < 3 then
                rednet.send(recipientID, message, protocol)
                attemptNumber = attemptNumber + 1
            else
                return false
            end
        end
    end
end


--===== MAIN =====--
local function main()
    while true do
        local serverID, serverMessage = rednet.receive(POWNET_SERVER_PROTOCOL)
        if type(serverMessage) == "table" then
            if(serverMessage.type == MESSAGE_TYPE.INIT and serverMessage.ID == 0) then
                -- Reboot?
                print("Server has been initialized. Rebooting and performing updates.")
                os.reboot()
            end
        end

        local droneID, droneMessage = rednet.receive(POWNET_DRONE_PROTOCOL)
        if type(droneMessage) == "table" then

        end
    end
end

--===== USER INTERFACE =====--
local function control()
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.backspace then
            break
        end
    end
end

function ApplyUpdate(p_Module, p_Path)
    local s_Message = {
        type = MESSAGE_TYPE.UPDATE,
        ID = math.random(0, 2^30),
        dataKey = p_Module,
        data = false
    }

    print("Updating:  " .. p_Module)
    local s_Response = sendAndWaitForResponse(MAINFRAME_ID, s_Message, POWNET_SERVER_PROTOCOL)
    if not s_Response then
        print("Failed to receive program: " .. p_Module)
        return false
    end
    if(s_Response == "InvalidName") then
        print("No module by this name: " .. p_Module)
        return false
    end

    local file = fs.open(p_Path, "w")
    file.write(s_Response)
    file.close()
end

local function Connect()
    print("Connecting to MainFrame...")
    MAINFRAME_ID = rednet.lookup(POWNET_SERVER_PROTOCOL, "MAINFRAME")
    if not MAINFRAME_ID then
        error("Unable to find mainframe")
        return false
    end

    -- Initialize our data for faster lookup
    print("Requesting data...")

    local s_Message = newMessage(MESSAGE_TYPE.INIT, "TANKSTATION")
    local s_Response = sendAndWaitForResponse(MAINFRAME_ID, s_Message, POWNET_SERVER_PROTOCOL)
    if s_Response then
        m_Data = s_Response
        print("Successfully updated data")
        Log("Connected!", colors.green)
        return true
    else
        error("Failed to fetch data")
        return false
    end
end

function UpdateStation()
    -- Main
    ApplyUpdate('DroneTankingBoot.lua', '/disk/startup')
    ApplyUpdate('DroneBoot.lua', '/disk/droneData/startup')
    ApplyUpdate('DroneLogic.lua', '/disk/droneData/DroneLogic.lua')
    ApplyUpdate('libs/aStar.lua', '/disk/droneData/aStar')
    ApplyUpdate('libs/location.lua', '/disk/droneData/location')
    ApplyUpdate('libs/pQueue.lua', '/disk/droneData/pQueue')
    ApplyUpdate('libs/netnav/netNav.lua', '/disk/droneData/netNav')
    ApplyUpdate('libs/maps/remoteMap/remoteMap.lua', '/disk/droneData/remoteMap')

end

if Connect() then
    UpdateStation()
    parallel.waitForAny(main, control)
end

rednet.unhost(POWNET_SERVER_PROTOCOL)
rednet.unhost(POWNET_DRONE_PROTOCOL)

