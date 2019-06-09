local s_Label = os.getComputerLabel()
if(s_Label ~= nil or s_Label == "DroneMan") then
    shell.run("/startup")
    return
end
print("Initializing Drone...")


shell.run('copy /disk/droneData/* /*')
while(turtle.getFuelLevel() == 0) do
    turtle.suckDown(5)
    turtle.refuel()
end
print("Done copying! Rebooting.")
turtle.forward()
os.reboot()