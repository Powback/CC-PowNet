--DroneMan
--Goal: Handle drones and their status

local m_Monitor = peripheral.wrap("left")

Log("Starting...")
function Init()
    if DATA["towers"] == nil then
        DATA["towers"] = {}
    end
end

function OnAddDockingTower(p_Pos, p_Height)
    local s_Tower = {
        pos = p_Pos,
        height = p_Height,
        freeSlot = 0,
        slots = 11,
        occupants = {}
    }
    table.insert(DATA["towers"], s_Tower)
    return true
end

local m_DroneEvents = {

}

local m_ServerEvents = {
    AddTower = OnAddTower
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
