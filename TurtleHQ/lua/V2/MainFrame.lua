--Mainframe
-- Goal: Handle communications and updates between servers

local args = {...}

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
--===== LOAD VFS =====--
if not VFS then
    if not os.loadAPI("VFS") then
        error("could not load API: VFS")
    end
end

VFS.Init("MainFrame")


--===== SET REDNET PROTOCOL =====--
local POWNET_SERVER_PROTOCOL = "PowNet:Server"


--===== HOST AS SERVER =====--
do
    local host = rednet.lookup(POWNET_SERVER_PROTOCOL, "MAINFRAME")
    if host and host ~= os.computerID() then
        printError("PowNet MAINFRAME server already running?")
        return
    end
end

rednet.host(POWNET_SERVER_PROTOCOL, "MAINFRAME")

--===== UTILS =====--
local MESSAGE_TYPE = {
    GET = 0,
    SET = 1,
    INIT = 2,
    PING = 2
}
local receivedMessages = {}
local receivedMessageTimeouts = {}


local function newMessage(messageType, messageID, dataKey, data)
    return {
        type = messageType,
        ID = messageID,
        dataKey = dataKey,
        data = data,
    }
end

--===== REPEATED MESSAGE HANDLING =====--
local function clearOldMessages()
    while true do
        local event, timer = os.pullEvent("timer")
        local messageID = receivedMessageTimeouts[timer]
        if messageID then
            receivedMessageTimeouts[timer] = nil
            receivedMessages[messageID] = nil
        end
    end
end

--===== MAIN =====--
local function main()
    while true do
        local senderID, message = rednet.receive(POWNET_SERVER_PROTOCOL)
        if type(message) == "table" then
            if message.type == MESSAGE_TYPE.GET then
                local data = vfs:getData(message.dataKey)
                local replyMessage = newMessage(MESSAGE_TYPE.GET, message.ID, message.dataKey, data)
                rednet.send(senderID, replyMessage, POWNET_SERVER_PROTOCOL)


            elseif message.type == MESSAGE_TYPE.SET then
                if not receivedMessages[message.ID] then
                    vfs:setData(message.dataKey, message.data)
                    receivedMessages[message.ID] = true
                    receivedMessageTimeouts[os.startTimer(15)] = message.ID
                end
                local replyMessage = newMessage(MESSAGE_TYPE.SET, message.ID, message.dataKey, true)
                rednet.send(senderID, replyMessage, POWNET_SERVER_PROTOCOL)

            elseif message.type == MESSAGE_TYPE.INIT then
                local s_EnvData = VFS.Init(message.dataKey)
                local replyMessage = newMessage(MESSAGE_TYPE.REGISTER, message.ID, message.dataKey, s_EnvData)
                rednet.send(senderID, replyMessage, POWNET_SERVER_PROTOCOL)
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

local function Connect()

    -- Initialize our data for faster lookup
    local s_Message = newMessage(MESSAGE_TYPE.INIT, 0,"MAINFRAME")
    rednet.broadcast(s_Message, POWNET_SERVER_PROTOCOL)
end

Connect()
parallel.waitForAny(main, clearOldMessages, control)

rednet.unhost(POWNET_SERVER_PROTOCOL)