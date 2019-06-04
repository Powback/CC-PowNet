local tArgs = {...}

os.loadAPI("PowNet")
print("Updating...")
-- OPEN REDNET
if(os.getComputerLabel() == nil) then
    print("Please set the label first.")
    return
end
for _, side in ipairs({"left", "right"}) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
    end
end
if not rednet.isOpen() then
    printError("Could not open rednet")
    return
end

s_Connected, DATA = PowNet.Connect()

PowNet.UpdateModule("PowNet")
PowNet.UpdateModule("PowNetRemote.lua")

function AddDockingTower(p_Name, p_Height)
    local x,y,z = gps.locate()
    if not x then
        print("Failed to get GPS location")
        return false
    end

    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "AddDockingTower", {pos = {x = x, y=y, z=z}, height = 3, name = math.random(0, 2^30)})
    local s_Result = PowNet.sendAndWaitForResponse("DockingMan", s_Message)
    if(type(s_Result == "table")) then
        print(s_Result.message)
    else
        print(s_Result)
    end
end

function DelDockingTower(p_Id)
    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "DelDockingTower", p_Id)
    local s_Result = PowNet.sendAndWaitForResponse("DockingMan", s_Message)
    if(type(s_Result == "table")) then
        print(s_Result.message)
    else
        print(s_Result)
    end
end

function ListDockingTowers()
    local s_Message = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "ListDockingTowers")
    local s_Result = PowNet.sendAndWaitForResponse("DockingMan", s_Message)
    if(type(s_Result == "table")) then
        print(s_Result.message)
    else
        print(s_Result)
    end
end

ListDockingTowers()

function Start()
    if tArgs[1] == nil then
        print("")
    end
end

Start()