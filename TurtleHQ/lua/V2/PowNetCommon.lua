
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

function sendAndWaitForResponse(recipientID, message, protocol)
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

--===== USER INTERFACE =====--
local function control()
    while true do
        local event, key = os.pullEvent("key")
        if key == keys.backspace then
            break
        end
    end
end