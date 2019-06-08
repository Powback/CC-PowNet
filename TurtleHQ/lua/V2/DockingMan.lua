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
    if(DATA["nextTower"] == nil) then
        DATA["nextTower"] = 1
    end
    if DATA["occupants"] == nil then
        DATA["occupants"] = {}
    end
    North, West, East, South, Up, Down = 0, 1, 2, 3, 4, 5
end

function GetXZFromHeading( p_Heading )
    if( p_Heading == 0) then --n
        return {x = 0, z = 1}
    end
    if( p_Heading == 1) then -- e
        return {x = 1, z = 0}
    end
    if( p_Heading == 2) then -- s
        return {x = 0, z = -1}
    end
    if( p_Heading == 3) then -- w
        return {x = -1, z = 0}
    end
    return false
end
function GetTowerPos( p_Index )
    local s_Pos = DATA["towers"][p_Index].pos
    return {x= s_Pos.x, y = s_Pos.y, z = s_Pos.z}
end
function GetSlotDirection(p_Slot)
    return p_Slot % 4
end
function GetSlotHeading(p_Slot)
    local s_Slot = p_Slot % 4
    if(s_Slot == 0) then
        return 2
    end
    if(s_Slot == 1) then
        return 3
    end
    if(s_Slot == 2) then
        return 0
    end
    if(s_Slot == 3) then
        return 1
    else
        return 0
    end
end

function GetXYZFromSlot( p_Tower, p_Slot)
    local s_Direction = (p_Slot % 4)
    local s_TowerPos = GetTowerPos(p_Tower)
    local s_Offset = GetXZFromHeading(s_Direction)
    local s_Ret = s_TowerPos
    local s_yLevel = math.floor(p_Slot / 4)

    s_Ret.x = s_TowerPos.x + s_Offset.x
    s_Ret.z = s_TowerPos.z + s_Offset.z
    s_Ret.y = s_yLevel + s_TowerPos.y
    return s_Ret
end

function GetSlotPosition(p_Tower, p_Slot)
    local s_SlotHeading = p_Slot % 4
    print(s_SlotHeading)
end

function GetFreeSlot( )
    for k,v in pairs(DATA["towers"]) do
        if(v.freeSlot + 1 <= v.slots) then
            return {tower = k, slot = v.freeSlot}
        end
    end
end

function RegisterSlot( p_Id, p_Tower, p_Slot )
    DATA["towers"][p_Tower].occupants[p_Slot] = p_Id + 1
    DATA["towers"][p_Tower].freeSlot = DATA["towers"][p_Tower].freeSlot + 1
end

function OnAllocateDocking(p_Id, p_Message)
    local s_Id = p_Message.data.id
    local s_Slot = GetFreeSlot()
    if(s_Slot == nil) then
        print("No registered docking stations")
        return false, "No registered docking stations"
    end
    local s_DockingPos = GetXYZFromSlot(s_Slot.tower, s_Slot.slot)
    local s_DockingHeading = GetSlotHeading(s_Slot.slot)
    RegisterSlot(p_Message.data.id, s_Slot.tower, s_Slot.slot)

    DATA["occupants"][s_Id] = {tower = s_Slot.tower, slot = s_Slot.slot, pos = s_DockingPos, heading = s_DockingHeading}
    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "SetDronePos", {id = s_Id, pos = s_DockingPos})
    local s_Response = PowNet.sendAndWaitForResponse("MapServer", s_Message, PowNet.SERVER_PROTOCOL)
    print(s_Response)
    -- Ignore the response, we just want to wait for it
    return true, DATA["occupants"][s_Id]
end

function OnListDockingTowers(p_Id, p_Message)
    local s_List = {}
    local s_Message = ""
    for _,l_Tower in pairs(DATA["towers"]) do
        print(_)
        s_List[l_Tower.id] = l_Tower.name
        s_Message = s_Message .. l_Tower.id .. ", "
    end
    if s_Message == "" then
        s_Message = "No towers registered."
    end
    return true, {message = s_Message, list = s_List}
end

function OnDelDockingTower(p_Id, p_Message)
    if(p_Message.data == nil or p_Message.data.id == nil) then
        return false, "No ID specified"
    end
    local s_ID = p_Message.data.id

    if(DATA["towers"][s_ID] == nil) then
        return false, "Tower " .. s_ID .. " does not exist."
    end
    for _,l_DroneID in DATA["towers"][s_ID].occupants do
        local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "DroneHomeless", {id = l_DroneID})
        PowNet.send("DroneMan", s_Message)
    end
    DATA["towers"][s_ID] = nil
    return true, {message = "Destroyed tower. ID: " .. s_Tower.id, id = s_Tower.id}
end


function OnAddDockingTower(p_Id, p_Message)
    -- Fix defaults
    if(p_Message.data.gps ~= nil and p_Message.data.pos == nil) then
        p_Message.data.pos = p_Message.data.gps
    end
    if(p_Message.data.height == nil) then
        return false, "Missing height"
    end
    if (p_Message.data.pos == nil) then
        return false, "Missing pos"
    end
    if (p_Message.data.name == nil) then
        return false, "Missing name"
    end

    local s_Tower = {
        id = DATA["nextTower"],
        name = p_Message.data.name,
        pos = p_Message.data.pos,
        height = p_Message.data.height,
        freeSlot = 0,
        slots = height * 4,
        occupants = {}
    }

    DATA["towers"][s_Tower.id] = s_Tower
    DATA["nextTower"] = DATA["nextTower"] + 1
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
            name = {
                required = true
            },
            height = {
            },
            pos = {
                length = 3
            },
        },
        func = OnAddDockingTower
    },

    DelDockingTower = {
        callable = true,
        params = {
            id = {
                required = true
            }
        },
        func = OnDelDockingTower
    },
    ListDockingTowers = {
        callable = true,
        params = {
            pos  ={
                length = 0,
                optional = true
            },
            height  ={
                length = 0,
                optional = true
            },
            free  ={
                length = 0,
                optional = true
            },
            slots = {
                length = 0,
                optional = true
            }
        },
        func = OnListDockingTowers
    },
    EditDockingTower = {
        callable = true,
        params = {
            id = {

            },
            name = {

            },
            height = {

            },
            pos = {
                length = 3
            },
        },
        func = OnEditDockingTower
    },

    AllocateDocking = {
        callable = true,
        params = {
            id = {

            },
            Tower = {

            }
        },
        func = OnAllocateDocking
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
        m_Monitor.write("[" .. v.id .. "] " .. v.name .. " - [" .. #v.occupants .. "/" .. v.slots .. "] -  " .. "("..v.pos.x .. ", " .. v.pos.y .. ", " .. v.pos.z .. ")")
    end
end


Init()
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents, Render)

SetStatus("Connected!", colors.green)

Render()
parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)

print("Unhosting")
rednet.unhost(PowNet.SERVER_PROTOCOL)
