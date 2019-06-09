

-- waypoint locations
waypoints = {}

-- exclusion locations (will not pathfind through area)
exclusions = {}

-- cache world geometry
cachedWorld = {}
-- cached wrld with block names
cachedWorldDetail = {}

aged = {}


-- A* parameters
local stopAt, nilCost = 1500, 1000


-- Directions
North, West, South, East, Up, Down = 0, 1, 2, 3, 4, 5
local shortNames = {[North] = "N", [West] = "W", [South] = "S",
                    [East] = "E", [Up] = "U", [Down] = "D" }
local deltas = {[North] = {0, 0, -1}, [West] = {-1, 0, 0}, [South] = {0, 0, 1},
                [East] = {1, 0, 0}, [Up] = {0, 1, 0}, [Down] = {0, -1, 0}}

----------------------------------------
-- getBlock
--
-- function: tests to see if there is a block or space.
-- return: bool (true if there is a block)
-- return: nil if there is no information on the block
--

function getBlock(bX, bY, bZ)
    local idx_block = bX..":"..bY..":"..bZ
    if cachedWorld[idx_block] == nil then
        return nil
    elseif cachedWorld[idx_block] == 1 then
        return true, cachedWorldDetail[idx_block]
    elseif cachedWorld[idx_block] == 0 then
        return false
    else
        return nil
    end
end

----------------------------------------
-- drawMap()
--
-- function: draws a map of the current coordinates
-- input x, y, z
-- input optional: characters to replace the ones it uses to draw
--

function drawMap(ox, oy, oz, block, empty, floor, none)
    resx, resy = term.getSize()
    ox = ox - math.floor(resx/2)--west = negx
    oz = oz - math.floor(resy/2)--north = negz
    block = block or "@"
    empty = empty or " "
    floor = floor or "#"
    none = none or "'"
    --term.clear()
    for i=1, resy do
        for j=1, resx do
            term.setCursorPos(j, i)
            if getBlock(ox+j, oy, oz+i) == nil then
                --draw empty
                term.write(none)
            elseif getBlock(ox+j, oy, oz+i) then
                --draw block
                term.write(block)
            elseif getBlock(ox+j, oy-1, oz+i) == true then
                --draw floor
                term.write(floor)
            else
                term.write(empty)
            end
        end
    end
    --drawTurtleOnMap(ox, oy, oz, cachedX, cachedY, cachedZ, cachedDir)
end

----------------------------------------
-- drawTurtleOnMap
--
-- function: for use with drawMap, draws a turtle on the map
-- input ox, oy, oz - x, y, z values used to draw the map
-- input x, y, z, d - location and direction of turtle
--

function drawTurtleOnMap(ox, oy, oz, x, y, z, d)
    local resx, resy = term.getSize()
    term.setCursorPos(math.floor(resx/2) + (x - ox), math.floor(resy/2) + (z - oz))
    if(d == 0) then
        term.write("^")--north
    elseif(d == 1) then
        term.write("<")--west
    elseif(d == 2) then
        term.write("v")--south
    elseif(d == 3) then
        term.write(">")
    else
        term.write("#")
    end
end


----------------------------------------
-- printWorld
--
-- function: for debugging, prints raw world data to screen
--

function printWorld()
    print(textutils.serialize(cachedWorld))
end

----------------------------------------
-- getCachedWorld
--
-- return: cached world as table
--

function getCachedWorld()
    return cachedWorld
end


----------------------------------------
-- worldSize
--
-- return: size of the world map (number of blocks)
--

function worldSize()--TODO: this does not work.. fix it
    local count = 0
    for _ in pairs(cachedWorld) do
        count = count + 1
    end
    return count
end



----------------------------------------
--
--
--
--
--
--

function getFile(name)
    if fs.exists("/egpsData/"..name) then
        local file = fs.open("/egpsData/"..name,"r")
        local data = file.readAll()
        file.close()
        return data
    else
        print("file not found: "..name)
        return ""
    end
end

----------------------------------------
--
--
--
--
--
--

function setFile(name, data)
    if fs.isDir("/egpsData") then
        local file = fs.open("/egpsData/"..name,"w")
        file.write(textutils.serialize(data))
        file.close()
        return true
    else
        print("creating "..name.." file...")
        fs.makeDir("/egpsData")
        return setFile(name)
    end
    print("a black hole happened")
    return false
end


function loadAll()
    load()
    loadDetail()
    loadWaypoints()
    loadExclusions()
end

function saveAll()
    save()
    saveDetail()
    saveWaypoints()
    saveExclusions()
end

----------------------------------------
-- load
--
-- function: load cachedWorld from a file
-- return: boolean "success"
--

function load()
    local data = getFile("blockData")
    if data ~= "" then
        cachedWorld = textutils.unserialize(data)
        if cachedWorld ~= nil then
            return true
        else
            -- print("could not read blockData file: \n"..data)
            cachedWorld = {}
            return false
        end
    else
        print("no world data")
        return false
    end
end

----------------------------------------
-- save
--
-- function: save cachedWorld to a file
-- return: boolean "success"
--

function save()
    setFile("blockData", cachedWorld)
end

----------------------------------------
-- loadDetail
--
-- function: load cachedWorlddetail from a file
-- return: boolean "success"
--

function loadDetail()
    local data = getFile("blockDataDetail")
    if data ~= {} then
        cachedWorldDetail = textutils.unserialize(data)
        if cachedWorldDetail ~= nil then
            return true
        else
            -- print("could not read blockDataDetail file: \n"..data)
            cachedWorldDetail = {}
            return false
        end
    else
        print("no detailed world data")
        saveDetail()
        return false
    end
end

----------------------------------------
-- saveDetail
--
-- function: save cachedWorldDetail to a file
-- return: boolean "success"
--

function saveDetail()
    setFile("blockDataDetail", cachedWorldDetail)
end


----------------------------------------
-- empty
--
-- funtion: test if the cachedWorld is empty
-- return: boolean cachedWorld is empty
--

function empty(table)
    table = table or cachedWorld
    for _, value in pairs(table) do
        if value ~= nil then
            return false
        end
    end
    return true
end


----------------------------------------
-- delCache
--
-- function: remove ALL data from cache
-- input: boolean are you sure?
-- return: boolean "success"
--

function delCache(sure)
    if sure then
        cachedX, cachedY, cachedZ, cachedDir = nil, nil, nil, nil
        cachedWorld, waypoints, exclusions = {}, {}, {}
        print("all data deleted from cache")
        return true
    else
        return false
    end
end


----------------------------------------
-- loadWaypoints
--
-- function: load waypoints from the file
-- return: boolean "success"
--

function loadWaypoints()
    local data = getFile("waypoints")
    if data ~= {} then
        waypoints = textutils.unserialize(data)
        if waypoints ~= nil then
            return true
        else
            -- print("could not read waypoints file: \n"..data)
            waypoints = {}
            return false
        end
    else
        print("no waypoint data")
        return false
    end
end

----------------------------------------
-- saveWaypoints
--
-- function: save waypoints to a file
-- return: boolean "success"
--

function saveWaypoints()
    setFile("waypoints", waypoints)
end

----------------------------------------
-- setWaypoint
--
-- function: save a waypoint to cache
-- input: name of waypoint, coordinates
-- returns: boolean "success"
--

function setWaypoint(name, x, y, z, d)
    d = d or 0
    x = x or nil
    y = y or nil
    z = z or nil
    if x == nil and y == nil and z == nil then
        waypoints[name] = nil
        print("waypoint deleted")
        return true
    end
    waypoints[name] = {x, y, z, d}
    if waypoints[name] ~= nil then
        return true
    else
        return false
    end
end

----------------------------------------
-- getWaypoint
--
-- function: get a waypoint from cache
-- input: name of waypoint
-- returns: waypoint coordinates and direction
-- returns: false if its not found
--

function getWaypoint(name)
    local x, y, z, d
    if waypoints[name] ~= nil then
        x = waypoints[name][1]
        y = waypoints[name][2]
        z = waypoints[name][3]
        d = waypoints[name][4]
        return x, y, z, d
    else
        print("waypoint "..name.." not found")
        return nil, nil, nil, nil
    end
end

----------------------------------------
-- loadExclusions
--
-- function: load exclusions from the file
-- return: boolean "success"
--

function loadExclusions()
    local data = getFile("exclusions")
    if data ~= {} then
        exclusions = textutils.unserialize(data)
        if exclusions ~= nil then
            return true
        else
            print("could not read exclusions file: \n"..data)
            exclusions = {}
            return false
        end
    else
        print("no exclusion data")
        return false
    end
end

----------------------------------------
-- saveExclusions
--
-- function: save exclusions to a file
-- return: boolean "success"
--

function saveExclusions()
    setFile("exclusions", exclusions)
end

----------------------------------------
-- setDronePos
--
-- function: save an drone Pos to cache
-- input: exclusions coordinates
-- returns: boolean "success"
--

function SetDronePos(idx, y, z)
    local x

    if y == nil and z == nil then
        x = tonumber(string.match(idx, "(.*):"))
        y = tonumber(string.match(idx, ":(.*):"))
        z = tonumber(string.match(idx, ":(.*)"))
    else
        x = idx
        idx = x..":"..y..":"..z
    end
    d = d or 0
    cachedWorld[idx] = 2
    return true
end

----------------------------------------
-- setExclusion
--
-- function: save an exclusion to cache
-- input: exclusions coordinates
-- returns: boolean "success"
--

function setExclusion(idx, y, z)
    local x

    if y == nil and z == nil then
        x = tonumber(string.match(idx, "(.*):"))
        y = tonumber(string.match(idx, ":(.*):"))
        z = tonumber(string.match(idx, ":(.*)"))
    else
        x = idx
        idx = x..":"..y..":"..z
    end
    d = d or 0
    exclusions[idx] = {x, y, z}
    if exclusions[idx] ~= nil then
        return true
    else
        return false
    end
end

----------------------------------------
-- excludeZone
--
-- function: exclude a cuboid
-- input: 2 opposite corners (x, y, z, x2, y2, z2)
-- option: boolean to include the zone
--

function excludeZone(x, y, z, x2, y2, z2, include)
    local temp, temp2
    temp, temp2 = x, x2
    x = math.min(temp, temp2)
    x2 = math.max(temp, temp2)
    temp, temp2 = y, y2
    y = math.min(temp, temp2)
    y2 = math.max(temp, temp2)
    temp, temp2 = z, z2
    z = math.min(temp, temp2)
    z2 = math.max(temp, temp2)

    for i = x, x2 do
        for j = y, y2 do
            for k = z, z2 do
                if include then
                    delExclusion(i, j, k)
                else
                    setExclusion(i, j, k)
                end
            end
        end
    end
end

----------------------------------------
-- getExclusion
--
-- function: get an exclusion from cache
-- input: index of exclusion: "x:y:z"
-- returns: exclusion coordinates (or nil, nil, nil)
--

function getExclusion(idx, y, z)
    local x
    if y == nil and z == nil then
        x = tonumber(string.match(idx, "(.*):"))
        y = tonumber(string.match(idx, ":(.*):"))
        z = tonumber(string.match(idx, ":(.*)"))
    else
        x = idx
        idx = x..":"..y..":"..z
    end
    if exclusions[idx] ~= nil then
        x = exclusions[idx][1]
        y = exclusions[idx][2]
        z = exclusions[idx][3]
        return x, y, z
    else
        print("exclusion "..idx.." not found")
        return nil, nil, nil
    end
end

----------------------------------------
-- delExclusion
--
-- function: remove an exclusion from cache
-- input: index of exclusion: "x:y:z" OR x, y, z
-- returns: boolean "success"
--

function delExclusion(idx, y, z)
    local x
    if y == nil and z == nil then
        x = tonumber(string.match(idx, "(.*):"))
        y = tonumber(string.match(idx, ":(.*):"))
        z = tonumber(string.match(idx, ":(.*)"))
    else
        x = idx
        idx = x..":"..y..":"..z
    end
    exclusions[idx] = nil
    print("exclusion deleted")
    return true
end

----------------------------------------
-- heuristic_cost_estimate
--
-- function: A* heuristic
-- input: X, Y, Z of the 2 points
-- return: Manhattan distance between the 2 points
--

local function heuristic_cost_estimate(x1, y1, z1, x2, y2, z2)
    return math.abs(x2 - x1) + math.abs(y2 - y1) + math.abs(z2 - z1)
end

----------------------------------------
-- reconstruct_path
--
-- function: A* path reconstruction
-- input: A* visited nodes and goal
-- return: List of movement to be executed
--

local function reconstruct_path(_cameFrom, _currentNode)
    if _cameFrom[_currentNode] ~= nil then
        local dir, nextNode = _cameFrom[_currentNode][1], _cameFrom[_currentNode][2]
        local path = reconstruct_path(_cameFrom, nextNode)
        table.insert(path, dir)
        return path
    else
        return {}
    end
end


local function isAged(p_Day, p_Time)
    if(os.day() > p_Day) then
        return true
    end
    if(os.time() > p_Time + 1) then
        print(os.time())
        print(p_Time)

        return true
    end
    return false
end


local function mergeCachedWorldDetail(newData, p_ID)
    for k,v in pairs(newData) do
        if(cachedWorldDetail[k] == nil) then
            cachedWorldDetail[k] = {}
            cachedWorldDetail[k].discoverer = p_ID
            cachedWorldDetail[k].discovered = {day = os.day(), time = os.time()}
        end
        cachedWorldDetail[k].lastUpdated = {day = os.day(), time = os.time()}
        cachedWorldDetail[k].data = v

        if(type(v[2]) == table) then
            if(v[2].name == "ComputerCraft:CC-TurtleAdvanced" or "ComputerCraft:CC-Turtle") then
                table.insert(aged, {coords = k, lastUpdated = cachedWorldDetail[k].lastUpdated})
            end
        end
    end
end

local function mergeCachedWorld(newData)
    for k,v in pairs(newData) do
        cachedWorld[k] = v
    end
end

function UpdateCachedWorld(newData, p_ID)
    mergeCachedWorld(newData, p_ID)
end
function UpdateCachedWorldDetail(newData, p_ID)
    mergeCachedWorldDetail(newData, p_ID)
end

-- CachedWorldDetail is our primary resource for the actual state of the world.
-- CachedWorld is the stuff we use for pathfinding.
function ClearAged()
    local s_Aged = {}
    for k,v in pairs(aged) do
        print(k)
        if(isAged(v.lastUpdated.day, v.lastUpdated.time)) then
            print("cleared as too old")
            cachedWorld[k] = nil
            table.insert(s_Aged, k)
        end
    end

    for k,v in pairs(s_Aged) do
        aged[k] = nil
    end
end

----------------------------------------
-- a_star
--
-- function: A* path finding
-- input: start and goal coordinates
-- return: List of movement to be executed
--

function a_star(x1, y1, z1, x2, y2, z2, discover, priority)
    discover = discover or 1
    local start, idx_start = {x1, y1, z1}, x1..":"..y1..":"..z1
    local goal,  idx_goal  = {x2, y2, z2}, x2..":"..y2..":"..z2
    priority = priority or false

    if exclusions == nil then
        loadExclusions()
    end

    if exclusions[idx_goal] ~= nil and not priority then
        print("goal is in exclusion zone")
        return {}
    end

    -- If goal is empty, unknown or a turtle position
    if (cachedWorld[idx_goal] == 2 or 0)then
        local openset, closedset, cameFrom, g_score, f_score, tries = {}, {}, {}, {}, {}, 0

        openset[idx_start] = start
        g_score[idx_start] = 0
        f_score[idx_start] = heuristic_cost_estimate(x1, y1, z1, x2, y2, z2)

        while not empty(openset) do
            local current, idx_current
            local cur_f = 9999999

            for idx_cur, cur in pairs(openset) do --for each entry in openset
                if cur ~= nil and f_score[idx_cur] <= cur_f then
                    idx_current, current, cur_f = idx_cur, cur, f_score[idx_cur]
                end
            end
            if idx_current == idx_goal then
                return reconstruct_path(cameFrom, idx_goal)
            end

            -- no more than 500 moves
            if cur_f >= stopAt then
                print("max limit")
                break
            end

            openset[idx_current] = nil
            closedset[idx_current] = true

            local x3, y3, z3 = current[1], current[2], current[3]

            for dir = 0, 5 do -- for all direction find the neighbor of the current position, put them on the openset
                local D = deltas[dir]
                local x4, y4, z4 = x3 + D[1], y3 + D[2], z3 + D[3]
                local neighbor, idx_neighbor = {x4, y4, z4}, x4..":"..y4..":"..z4
                if (exclusions[idx_neighbor] == nil or priority) and (((cachedWorld[idx_neighbor] or 0) == 0 ) or idx_neighbor == idx_goal)then -- if its free or unknow and not on exclusion list
                    if closedset[idx_neighbor] == nil then -- if not closed
                        local tentative_g_score = g_score[idx_current] + ((cachedWorld[idx_neighbor] == nil) and discover or 1)
                        if (cachedWorld[idx_neighbor] == 2) then
                            tentative_g_score = tentative_g_score - 1
                        end
                        --if block is undiscovered and there is a value for discover, it adds the discover value. else, it adds 1
                        if openset[idx_neighbor] == nil or tentative_g_score <= g_score[idx_neighbor] then -- tentative_g_score is always at least 1 more than g_score[idx_neighbor] T.T
                            --evaluates to if its not on the open list
                            cameFrom[idx_neighbor] = {dir, idx_current}
                            g_score[idx_neighbor] = tentative_g_score
                            f_score[idx_neighbor] = tentative_g_score + heuristic_cost_estimate(x4, y4, z4, x2, y2, z2)
                            openset[idx_neighbor] = neighbor
                        end
                    end
                end
            end
        end
    end
    print("no path found")
    return false
end

----------------------------------------


------------------------------------------
-- progressBar
--
-- function: write a progress bar at cursor position (12 characters)
-- input: %
--

function progressBar(percent)
    term.write("[")
    for i=1, 10 do
        if math.floor(percent/10) >= i then
            term.write("|")
        elseif math.ceil(percent/10) == i then
            term.write(":")
        else
            term.write(" ")
        end
    end
    term.write("]")
end

------------------------------------------
-- explore v2.0
--
-- function: map out an area
-- inputs:
-- int _range: size of the cuboid to check (radius excluding center)
-- bool limitY: if true, height of cuboid is 3
-- bool drawMap: if true, draws a map as it goes along so you can see progress
--

function explore(_range, limitY, drawAMap)--TODO: flag to explore previously explored blocks
    local ox, oy, oz, od = locate()
    local x, y, z, d = 0, 0, 0, 0
    --local i = 0
    --local total = 0
    local toCheck = {}
    local count = 0
    local maxCount
    local idx
    local dist
    local skip
    local yVal = _range
    drawMap = drawMap or false
    limitY = limitY or false

    if limitY then
        yVal = 1
    end

    for dx = -_range, _range do
        for dy = -yVal, yVal do
            for dz = -_range, _range do
                idx = ox+dx..":"..oy+dy..":"..oz+dz
                toCheck[idx] = {ox+dx, oy+dy, oz+dz}--set up the toCheck table
                count = count + 1
            end
        end
    end

    maxCount = count
    while count > 1 do--go through all entries in table
        x, y, z, d = locate()
        term.clear()
        term.setCursorPos(1, 1)
        if drawAMap then
            drawMap(ox, oy, oz)
            drawTurtleOnMap(ox, oy, oz, x, y, z, d)
            term.setCursorPos(1, 1)
        end
        progressBar(100*(maxCount - count)/(maxCount))
        dist = 500
        skip = false

        for k, v in pairs(toCheck) do--find closest block to check
            if v[1] == x and v[2] == y and v[3] == z then--if on the block then remove from list
                toCheck[k] = nil
                skip = true--and run again
                count = count - 1
                maxCount = maxCount - 1
                break
            elseif (math.abs(x - v[1]) + math.abs(y - v[2]) + math.abs(z - v[3])) < dist then
                dist = math.abs(x - v[1]) + math.abs(y - v[2]) + math.abs(z - v[3])--TODO: pathfind to the location and use number of instructions instead of huristic distance
                idx = k
                if dist == 1 then
                    break
                end
            end
        end

        if not skip then
            count = count - 1
            moveTo(toCheck[idx][1], toCheck[idx][2], toCheck[idx][3], d, false, nilCost)--still not sure about nilcost
            toCheck[idx] = nil
        end
        sleep(0)--yield... remove this if possible
    end


    term.clear()
    term.setCursorPos(1, 1)
    progressBar(100)
    -- Go back to the starting point
    print(string.format("\nreturning..."))
    moveTo(ox, oy, oz, od, false, nilCost)
end

