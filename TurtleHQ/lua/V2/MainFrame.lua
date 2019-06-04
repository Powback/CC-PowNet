--Mainframe
-- Goal: Handle communications and updates between servers
os.loadAPI("disk/PowNet")


--===== LOAD VFS =====--
if not VFS then
    if not os.loadAPI("disk/VFS") then
        error("could not load API: VFS")
    end
end
VFS.Init("MainFrame")

Log("Loading...")

--===== HOST AS SERVER =====--
print("Starting MainFrame")
rednet.host(PowNet.SERVER_PROTOCOL, "MAINFRAME")

--===== UTILS =====--

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
        local senderID, message = rednet.receive(PowNet.SERVER_PROTOCOL)
        if type(message) == "table" then
            print(message.type)
            print(message.dataKey)
            if message.type == PowNet.MESSAGE_TYPE.GET then
                local data = VFS.getData(message.dataKey)
                local replyMessage = newMessage(PowNet.MESSAGE_TYPE.GET, message.ID, message.dataKey, data)
                rednet.send(senderID, replyMessage, PowNet.SERVER_PROTOCOL)


            elseif message.type == PowNet.MESSAGE_TYPE.SET then
                if not receivedMessages[message.ID] then
                    if(message.data ~= nil ) then
                        VFS.setData(message.dataKey, message.data)
                        VFS.saveData(message.dataKey)
                    end
                    receivedMessages[message.ID] = true
                    receivedMessageTimeouts[os.startTimer(15)] = message.ID
                end
                local replyMessage = newMessage(PowNet.MESSAGE_TYPE.SET, message.ID, message.dataKey, true)
                rednet.send(senderID, replyMessage, PowNet.SERVER_PROTOCOL)
            elseif message.type == PowNet.MESSAGE_TYPE.INIT then
                if(message.dataKey == nil) then
                    return
                end
                local s_EnvData = VFS.Init(message.dataKey)
                local replyMessage = newMessage(PowNet.MESSAGE_TYPE.INIT, message.ID, message.dataKey, s_EnvData)
                rednet.send(senderID, replyMessage, PowNet.SERVER_PROTOCOL)

            elseif message.type == PowNet.MESSAGE_TYPE.UPDATE then
                if (fs.exists("disk/" .. message.dataKey) == false) then
                    local replyMessage = newMessage(PowNet.MESSAGE_TYPE.UPDATE, message.ID, message.dataKey, "InvalidName")
                    rednet.send(senderID, replyMessage, PowNet.SERVER_PROTOCOL)
                else
                    local file = fs.open("disk/" .. message.dataKey,"r")
                    local data = file.readAll()
                    file.close()
                    local replyMessage = newMessage(PowNet.MESSAGE_TYPE.UPDATE, message.ID, message.dataKey, data)
                    rednet.send(senderID, replyMessage, PowNet.SERVER_PROTOCOL)

                end
            end
        end
    end
end


local function Connect()
    -- Initialize our data for faster lookup
    local s_Message = newMessage(PowNet.MESSAGE_TYPE.INIT, 0,"MAINFRAME")
    rednet.broadcast(s_Message, PowNet.SERVER_PROTOCOL)
    print("Dispatched server boot")
    Log("Connected!", colors.green)
end

Connect()
parallel.waitForAny(main, clearOldMessages, PowNet.control)

rednet.unhost(PowNet.SERVER_PROTOCOL)