--DroneMan
--Goal: Handle drones and their status

local m_Monitor = peripheral.wrap("left")

Log("Starting...")
function Init()
    if DATA["towers"] == nil then
        DATA["towers"] = {}
    end
    if DATA["nameLookup"] == nil then
        DATA["nameLookup"] = {}
    end
    if(DATA["lastTower"] == nil) then
        DATA["lastTower"] = 0
    end
end
function OnListDockingTowers(p_Id, p_Message)
    local s_List = {}
    local s_Message = ""
    for k,_ in pairs(DATA["towers"]) do
        table.insert(s_List, k)
        s_Message = s_Message .. k .. ", "
    end
    if s_Message == "" then
        s_Message = "No towers registered."
    end
    return true, {message = s_Message, list = s_List}
end
function OnDelDockingTower(p_Id, p_Message)
    if(p_Message.data == nil) then
        return false, "No ID specified"
    end
    if(DATA["towers"][p_Id] == nil) then
        return false, "Tower " .. p_Id .. " does not exist."
    end
    for _,l_DroneID in DATA["towers"][p_Id].occupants do
        local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "DroneHomeless", {id = l_DroneID})
        PowNet.send("DroneMan", s_Message)
    end
    DATA["towers"][p_Id] = nil
    return true, {message = "Destroyed tower. ID: " .. s_Tower.id, id = s_Tower.id}
end

function OnAddDockingTower(p_Id, p_Message)
    print("Yee to the haw")
    if(p_Message.data.pos == nil or p_Message.data.height == nil) then
        return false, "Missing pos/height"
    end
    if (p_Message.data.name == nil) then
        return false, "Please enter a name"
    end

    local s_Tower = {
        id = DATA["lastTower"],
        name = p_Message.data.name,
        pos = p_Message.data.pos,
        height = p_Message.data.height,
        freeSlot = 0,
        slots = 11,
        occupants = {}
    }

    DATA["lastTower"] = DATA["lastTower"] + 1
    DATA["towers"][DATA["lastTower"]] = s_Tower
    DATA["nameLookup"][p_Message.data.name] = s_Tower.id

    print("Added Docking Tower")
    return true, {message = "Created tower. ID: " .. s_Tower.id, id = s_Tower.id}
end


function OnEditDockingTower(p_Id, p_Message)

end
local m_DroneEvents = {

}

local m_ServerEvents = {
    AddDockingTower = {
        callable = true,
        params = {
            "Name",
            "Height",
            "Pos",
        },
        func = OnAddDockingTower
    },

    DelDockingTower = {
        callable = true,
        params = {
            "ID"
        },
        func = OnDelDockingTower
    },
    ListDockingTowers = {
        callable = true,
        params = {

        },
        func = OnListDockingTowers
    },
    EditDockingTower = {
        callable = true,
        params = {
            "Name",
            "Height",
            "Pos",
        },
        func = OnEditDockingTower
    }
}

function Render()
    print("Render!")
    m_Monitor.clear()
    m_Monitor.setCursorPos(1,1)
    m_Monitor.setTextScale(0.5)
    -- Header
    m_Monitor.write("DockingMan!")
    local i = 1
    for k,v in pairs(DATA["towers"]) do
        i = i + 1
        m_Monitor.setCursorPos(1,i)
        m_Monitor.write("[" .. v.id .. "] - [" .. #v.occupants .. "/" .. v.slots .. "]")
    end
end


Init()
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents, Render)

SetStatus("Connected!", colors.green)

Render()
parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)

print("Unhosting")
rednet.unhost(PowNet.SERVER_PROTOCOL)
