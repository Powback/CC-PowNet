-- TankStation
os.loadAPI("netNav")


-- LOAD NETNAV API
if not netNav then
    if not os.loadAPI("netNav") then
        error("could not load netNav API")
    end
end

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

-- SET NETNAV MAP
netNav.setMap("PowMap", 15) -- the second argument determines how frequently the turtle will check with the server for newer map data

