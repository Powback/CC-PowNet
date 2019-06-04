--DroneMan
--Goal: Handle drones and their status

local m_Monitor = peripheral.wrap("left")

Log("Starting...")
function Init()
    if DATA["tasks"] == nil then
        DATA["tasks"] = {}
    end
end

function CreateTask(p_ID, p_Pos)

end

local m_DroneEvents = {

}

local m_ServerEvents = {
    CreateTask = {
        callable = true,
        params = {
            "Name",
            "Task",
            "TaskParams",
            "Priority",
            "MinWorkers",
            "MaxWorkers",
        },
        func = OnAddDockingTower
    }
}

function Render()
    print("Render!")
    m_Monitor.clear()
    m_Monitor.setCursorPos(1,1)
    m_Monitor.setTextScale(0.5)
    -- Header
    m_Monitor.write("TaskMan!")
    local i = 1

end


Init()
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents, Render)

SetStatus("Connected!", colors.green)

Render()
parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)

print("Unhosting")
rednet.unhost(PowNet.SERVER_PROTOCOL)
