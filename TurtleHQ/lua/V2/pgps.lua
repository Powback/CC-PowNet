-- This library provide high level turtle movement functions.
--
-- Before being able to use them, you should start the GPS with egps.startGPS()
--    then get your current location with egps.setLocationFromGPS().
-- egps.forward(), egps.back(), egps.up(), egps.down(), egps.turnLeft(), egps.turnRight()
--    replace the standard turtle functions.
-- If you need to use the standard functions, you
--    should call egps.setLocationFromGPS() again before using any egps functions.

-- Gist at: https://gist.github.com/SquidLord/4741746

-- The MIT License (MIT)

-- Copyright (c) 2012 Alexander Williams

-- Permission is hereby granted, free of charge, to anexclusionsy person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--[[

-------------------MODIFIED BY 1wsx10---------------------------
 instructions:
 1. install it as an api
 2. look at comments above each function to see what they do
 3. write code
 4. complain about shit instructions





 recently added: support for LAMA
 exclusion zone file - turtle wont pathfind through an excluded block.
 exclusions are similar to waypoints but instead of name it has index "x:y:z" and does not store direction
 a_star has boolean "priority" - will ignore exclusion zone
--------------------------------------------------------------

-----------------MODIFIED BY POWBACK ---------------------------
 Modified this modification to add PowNet support for eGPS.
 It features a client/server design, where the server sends the path the client should use,
 and the client updates the server with it's mapping data.
 This means that the server can sync mapping data across all turtles.
 Resulting in a (potentially) really fast and efficient pathfinding method.
 Blocked paths will automatically trigger the server to update existing data, so future visitors can get there fast.

Functions:
    RequestPath(x,y,z) // Returns paths[]
        runs standard A* method

    RequestPath(x,y,z, {pathdata: updated local pathdata, with the !updated! paths })
        returns same as PrequestPath(x,y,z)

    SavePath(pathData) // void
        Turtle completed move, update age on the path the turtle took.


--------------------------------------------------------------

--]]

-- Cache of the current turtle position and direction
local cachedX, cachedY, cachedZ, cachedDir

-- Directions
North, West, South, East, Up, Down = 0, 1, 2, 3, 4, 5
local shortNames = {[North] = "N", [West] = "W", [South] = "S",
                    [East] = "E", [Up] = "U", [Down] = "D" }
local deltas = {[North] = {0, 0, -1}, [West] = {-1, 0, 0}, [South] = {0, 0, 1},
                [East] = {1, 0, 0}, [Up] = {0, 1, 0}, [Down] = {0, -1, 0}}

-- cache world geometry
cachedWorld = {}
-- cached wrld with block names
cachedWorldDetail = {}




-- compatibility with LAMA
local isLama = false
if fs.isDir("/.lama") then
    isLama = true
    lama.overwrite() --replaces turtle.forward() etc. with lama.forward()
    print("lama detected, using lama movement...")
end

----------------------------------------
-- printWorld
--
-- function: for debugging, prints raw world data to screen
--

function printWorld()
    print(textutils.serialize(cachedWorld))
end



----------------------------------------TODO: worldDetail support
-- detectAll
--
-- function: Detect up, forward, down and writes it to cachedWorld
--

function detectAll()
    local F, U, D = deltas[cachedDir], deltas[Up], deltas[Down]
    local block
    cachedWorld[cachedX..":"..cachedY..":"..cachedZ] = 0

    block = 0
    if turtle.detect()      then block = 1 end
    cachedWorld[(cachedX + F[1])..":"..(cachedY + F[2])..":"..(cachedZ + F[3])] = block
    cachedWorldDetail[(cachedX + F[1])..":"..(cachedY + F[2])..":"..(cachedZ + F[3])] = {turtle.inspect()}

    block = 0
    if turtle.detectUp()    then block = 1 end
    cachedWorld[(cachedX + U[1])..":"..(cachedY + U[2])..":"..(cachedZ + U[3])] = block
    cachedWorldDetail[(cachedX + U[1])..":"..(cachedY + U[2])..":"..(cachedZ + U[3])] = {turtle.inspectUp()}

    block = 0
    if turtle.detectDown()  then block = 1 end
    cachedWorld[(cachedX + D[1])..":"..(cachedY + D[2])..":"..(cachedZ + D[3])] = block
    cachedWorldDetail[(cachedX + D[1])..":"..(cachedY + D[2])..":"..(cachedZ + D[3])] = {turtle.inspectDown()}
end


----------------------------------------
-- forward
--
-- function: Move the turtle forward if possible and put the result in cache
-- return: boolean "success"
--

function forward()
    local D = deltas[cachedDir]--if north, D = {0, 0, -1}
    local x, y, z = cachedX + D[1], cachedY + D[2], cachedZ + D[3]--adds corisponding delta to direction
    local idx_pos = x..":"..y..":"..z

    if turtle.forward() then
        cachedX, cachedY, cachedZ = x, y, z
        detectAll()
        return true
    else
        cachedWorld[idx_pos] = (turtle.detect() and 1 or 0.5)
        return false
    end
end

----------------------------------------
-- back
--
-- function: Move the turtle backward if possible and put the result in cache
-- return: boolean "success"
--

function back()
    local D = deltas[cachedDir]
    local x, y, z = cachedX - D[1], cachedY - D[2], cachedZ - D[3]
    local idx_pos = x..":"..y..":"..z

    if turtle.back() then
        cachedX, cachedY, cachedZ = x, y, z
        detectAll()
        return true
    else
        cachedWorld[idx_pos] = 0.5
        return false
    end
end

----------------------------------------
-- up
--
-- function: Move the turtle up if possible and put the result in cache
-- return: boolean "success"
--

function up()
    local D = deltas[Up]
    local x, y, z = cachedX + D[1], cachedY + D[2], cachedZ + D[3]
    local idx_pos = x..":"..y..":"..z

    if turtle.up() then
        cachedX, cachedY, cachedZ = x, y, z
        detectAll()
        return true
    else
        cachedWorld[idx_pos] = (turtle.detectUp() and 1 or 0.5)
        return false
    end
end

----------------------------------------
-- down
--
-- function: Move the turtle down if possible and put the result in cache
-- return: boolean "success"
--

function down()
    local D = deltas[Down]
    local x, y, z = cachedX + D[1], cachedY + D[2], cachedZ + D[3]
    local idx_pos = x..":"..y..":"..z

    if turtle.down() then
        cachedX, cachedY, cachedZ = x, y, z
        detectAll()
        return true
    else
        detectAll()
        cachedWorld[idx_pos] = (turtle.detectDown() and 1 or 0.5)
        return false
    end
end

----------------------------------------
-- turnLeft
--
-- function: Turn the turtle to the left and put the result in cache
-- return: boolean "success"
--

function turnLeft()
    cachedDir = (cachedDir + 1) % 4
    turtle.turnLeft()
    detectAll()
    return true
end

----------------------------------------
-- turnRight
--
-- function: Turn the turtle to the right and put the result in cache
-- return: boolean "success"
--

function turnRight()
    cachedDir = (cachedDir + 3) % 4
    turtle.turnRight()
    detectAll()
    return true
end

----------------------------------------
-- turnTo
--
-- function: Turn the turtle to the choosen direction and put the result in cache
-- input: number _targetDir
-- return: boolean "success"
--

function turnTo(_targetDir)
    --print(string.format("target dir: {0}\ncachedDir: {1}", _targetDir, cachedDir))
    if _targetDir == cachedDir then
        return true
    elseif ((_targetDir - cachedDir + 4) % 4) == 1 then--moveTo caused exception
        turnLeft()
    elseif ((cachedDir - _targetDir + 4) % 4) == 1 then
        turnRight()
    else
        turnLeft()
        turnLeft()
    end
    return true
end

----------------------------------------
-- clearWorld
--
-- function: Clear the world cache
--

function clearWorld()
    cachedWorld = {}
    detectAll()
end


-- moveTo
--
-- function: Move the turtle to the choosen coordinates in the world
-- input: X, Y, Z and direction of the goal
-- return: boolean "success"
--

function SavePath()

    local s_Request = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "UpdatePath", {id = os.getComputerID(), path = cachedWorld})
    local s_Response = PowNet.sendAndWaitForResponse("MapServer", s_Request)
    cachedWorld = {}
end

function moveTo(_targetX, _targetY, _targetZ, _targetDir, changeDir, discover)
    changeDir = changeDir or false
    while cachedX ~= _targetX or cachedY ~= _targetY or cachedZ ~= _targetZ do
        --TODO: NETWORK
        local s_Request = PowNet.newMessage(PowNet.MESSAGE_TYPE.CALL, "GetPath", {cachedX, cachedY, cachedZ, _targetX, _targetY, _targetZ, discover})
        local s_Response = PowNet.sendAndWaitForResponse("MapServer", s_Request)
        if (not s_Response) then
            print("Failed to get direction")
            print(s_Response)
            return false
        end
        if( not s_Response ) then
            print("No data")
            return false
        end
        local path = s_Response.path

        --[[
        local path = a_star(cachedX, cachedY, cachedZ, _targetX, _targetY, _targetZ, discover)
        if (#path == 0) then
            return false
        end
        --]]
        --print(textutils.serialize(table))
        for i, dir in ipairs(path) do
            if dir == Up then
                if not up() then
                    SavePath()
                    break
                end
            elseif dir == Down then
                if not down() then
                    SavePath()
                    break
                end
            else
                turnTo(dir)
                if not forward() then
                    SavePath()
                    break
                end
            end
        end
    end

    if changeDir then
        turnTo(_targetDir)
    end
    local x,y,z = setLocationFromGPS()
    if(x ~= _targetX or y ~= _targetY or z ~= _targetZ) then
        return moveTo(cachedX ~= _targetX or cachedY ~= _targetY or cachedZ ~= _targetZ)
    end
    return true
end

----------------------------------------
-- setLocation
--
-- function: Set the current X, Y, Z and direction of the turtle
-- d can be the direction name or number
--

function setLocation(x, y, z, d)
    cachedX, cachedY, cachedZ = x, y, z
    if d == 0 then
        d = "north"
        cachedDir = North
    elseif string.lower(d) == "north" then
        d = "north"
        cachedDir = North
    elseif d == 1 then
        d = "west"
        cachedDir = West
    elseif string.lower(d) == "west" then
        d = "west"
        cachedDir = West
    elseif d == 2 then
        d = "south"
        cachedDir = South
    elseif string.lower(d) == "south" then
        d = "south"
        cachedDir = South
    elseif d == 3 then
        d = "east"
        cachedDir = East
    elseif string.lower(d) == "east" then
        d = "east"
        cachedDir = East
    else
        print("unknown direction")
        return false
    end
    if isLama then
        lama.setPosition(x, y, z, d)
    end
    return cachedX, cachedY, cachedZ, cachedDir
end

----------------------------------------
-- startGPS
--
-- function: Open the rednet network
-- return: boolean "success"
--

function startGPS()
    local netOpen, modemSide = false, nil

    for _, side in pairs(rs.getSides()) do    -- for all sides
        if peripheral.getType(side) == "modem" then  -- find the modem
            modemSide = side
            if rednet.isOpen(side) then  -- check its status
                netOpen = true
                break
            end
        end
    end

    if not netOpen then  -- if the rednet network is not open
        if modemSide then  -- and we found a modem, open the rednet network
            rednet.open(modemSide)
        else
            print("No modem found")
            return false
        end
    end
    return true
end

-- setLocationFromGPS
--
-- function: Retrieve the turtle GPS position and direction (if possible)
-- return: current X, Y, Z and direction of the turtle (or false if it failed)
--

function setLocationFromGPS()
    if startGPS() then
        -- get the current position
        cachedX, cachedY, cachedZ  = gps.locate(4, false)
        local d = cachedDir or nil
        cachedDir = nil

        -- determine the current direction
        for tries = 0, 3 do  -- try to move in one direction
            if turtle.forward() then
                local newX, _, newZ = gps.locate(4, false) -- get the new position
                turtle.back()              -- and go back

                -- deduce the curent direction
                if newZ < cachedZ then
                    cachedDir = North
                    d = "north"
                elseif newZ > cachedZ then
                    cachedDir = South
                    d = "south"
                elseif newX < cachedX then
                    cachedDir = West
                    d = "west"
                elseif newX > cachedX then
                    cachedDir = East
                    d = "east"
                end

                -- Cancel out the tries
                turnTo((cachedDir - tries + 4) % 4)

                -- exit the loop
                break

            else -- try in another direction
                tries = tries + 1
                turtle.turnLeft()
            end
        end

        if cachedDir == nil then
            print("Could not determine direction")
            if isLama then--TODO: put lama direction
            else
                return false
            end
        end


        -- Return the current turtle position
        if isLama then
            lama.setPosition(cachedX, cachedY, cachedZ, d)
        end
        return cachedX, cachedY, cachedZ, cachedDir
    else
        print("no GPS signal")
        if isLama then

        else
            return false
        end
    end
end

----------------------------------------
-- setLocationFromLAMA
--
-- function: Retrieve the turtle position and direction from LAMA
-- return: current X, Y, Z and direction of the turtle (or false if it failed)
--

function setLocationFromLAMA()
    if isLama then
        cachedX, cachedY, cachedZ, d = lama.getPosition() --last resort if gps fails, get direction from Lama
        if d == "north" then
            cachedDir = North
        elseif d == "south" then
            cachedDir = South
        elseif d == "east" then
            cachedDir = East
        elseif d == "west" then
            cachedDir = West
        else
            print("could not get direction from lama")
            return false
        end
        return true
    else
        print("no lama")
        return false
    end
end

----------------------------------------
-- locate
--
-- function: Retrieve the cached turtle position and direction
-- return: cached X, Y, Z and direction of the turtle
--

function locate()
    if isLama then
        local x, y, z, f = lama.getPosition()
        local d
        if f == "north" then
            d = North
        elseif f == "west" then
            d = West
        elseif f == "south" then
            d = South
        elseif f == "east" then
            d = East
        else
            return cachedX, cachedY, cachedZ, cachedDir
        end
        cachedX, cachedY, cachedZ, cachedDir = x, y, z, d
        return x, y, z, d
    else
        return cachedX, cachedY, cachedZ, cachedDir
    end
end