--DroneMan
--Goal: Handle drones and their status

local m_Monitor = peripheral.wrap("left")

Log("Starting...")
--===== LOAD VFS =====--
if not PowGPSServer then
    if not os.loadAPI("PowGPSServer") then
        return false, "could not load API: PowGPSServer"
    end
else
    print("yasy")
end

function Init()
    PowGPSServer.loadAll()
end

function OnSaveWorld(p_ID, p_Message)
    mergeData(p_Message.data)
end

function OnLoadWorld(p_ID, p_Message)
    return true, DATA["world"]
end

function OnGetPath(p_ID, p_Message)
    print(p_ID)
    print("Get Path")
    local x1 = p_Message.data[1]
    local y1 = p_Message.data[2]
    local z1 = p_Message.data[3]
    local x2 = p_Message.data[4]
    local y2 = p_Message.data[5]
    local z2 = p_Message.data[6]
    local discover = p_Message.data[7]
    local priority =p_Message.data[8]
    local s_Path = PowGPSServer.a_star(x1, y1, z1, x2, y2, z2, discover, priority)
    -- TODO: prevent path blocking?
    return true, {path = s_Path}
end

function OnUpdatePath(p_ID, p_Message)
    print(p_Message.data)
    print("lego")
    print(#p_Message.data)
    for k,v in pairs(p_Message.data) do
        print(k)
    end
    PowGPSServer.UpdatePath(p_Message.data.path)
    return true, true
end
local m_DroneEvents = {

}

local m_ServerEvents = {
    UpdatePath = {
        func = OnUpdatePath
    },
    SaveWorld = {
        func = OnSaveWorld
    },
    LoadWorld = {
        func = OnLoadWorld
    },
    GetPath = {
        func = OnGetPath
    }
}

function Render()
    print("Render!")
    m_Monitor.clear()
    m_Monitor.setCursorPos(1,1)
    m_Monitor.setTextScale(0.5)
    -- Header
    m_Monitor.write("MapServer!")
    local i = 1

end


Init()
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents, Render)

SetStatus("Connected!", colors.green)

Render()
parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)
PowGPSServer.saveAll()
print("Unhosting")
rednet.unhost(PowNet.SERVER_PROTOCOL)
