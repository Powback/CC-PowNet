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
local message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "DroneOnline", "FUCK YEAH")
PowNet.SendToServer("DroneMan", message)

parallel.waitForAny(PowNet.main, PowNet.control)

rednet.unhost(PowNet.SERVER_PROTOCOL)
