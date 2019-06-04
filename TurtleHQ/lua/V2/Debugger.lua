--DroneMan
--Goal: Handle drones and their status


Log("Starting...")

--===== UTILS =====--
function OnDroneOnline(p_ID, p_Message)
    print(p_ID)
    print(p_Message.type)
end
local m_DroneEvents = {
    DroneOnline = OnDroneOnline
}
local m_ServerEvents = {
    DroneOnline = OnDroneOnline
}
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents)

SetStatus("Connected!", colors.green)
print("Waiting for signal...")
print("Sending First")
local message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "DroneOnline", "FUCK YEAH")
local s_Response = PowNet.sendAndWaitForResponse("DroneMan", message, PowNet.DRONE_PROTOCOL)
print(s_Response)
print("Sending 2nd")

local message2 = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "DroneOnline", "Ya dam bich")
local s_Response2 = PowNet.SendToServer("DroneMan", message2)
print(s_Response2)
parallel.waitForAny(PowNet.main, PowNet.control)

rednet.unhost(PowNet.SERVER_PROTOCOL)

