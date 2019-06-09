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
turtle.refuel(64)
s_Connected, DATA = PowNet.Connect("Drone")
while not s_Connected do
    s_Connected, DATA = PowNet.Connect("Drone")
end

PowNet.UpdateModule("PowNet")
PowNet.UpdateModule('DroneBoot.lua', '/startup')
PowNet.UpdateModule('DroneLogic.lua', '/DroneLogic.lua')
PowNet.UpdateModule('pgps.lua', '/pgps')

shell.run("DroneLogic.lua")

print("EXITED")
os.sleep(3)
os.reboot()