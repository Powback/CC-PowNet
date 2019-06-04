os.loadAPI("PowNet")
print("Updating...")
-- OPEN REDNET
for _, side in ipairs({"left", "right"}) do
    if peripheral.getType(side) == "modem" then
        rednet.open(side)
    end
end
if not rednet.isOpen() then
    printError("Could not open rednet")
    return
end

s_Connected, DATA = PowNet.Connect("Drone")

PowNet.UpdateModule("PowNet")
PowNet.UpdateModule('DroneBoot.lua', '/startup')
PowNet.UpdateModule('DroneLogic.lua', '/DroneLogic.lua')
PowNet.UpdateModule('libs/aStar.lua', '/aStar')
PowNet.UpdateModule('libs/location.lua', '/location')
PowNet.UpdateModule('libs/pQueue.lua', '/pQueue')
PowNet.UpdateModule('libs/netnav/netNav.lua', '/netNav')
PowNet.UpdateModule('libs/maps/remoteMap/remoteMap.lua', '/remoteMap')

shell.run("DroneLogic.lua")