m_Min = {}
m_Max = {}



local function getDist(min, max)
	local distX = math.abs(max.x - min.x)
	local distY = math.abs(max.y - min.y)
	local distZ = math.abs(max.z - min.z)
	return {x = distX, y = distY, z = distZ}
end


local function GetOrientation(min,max)
	local s_Dist = getDist(min,max)
	if(s_Dist.x <= s_Dist.z) then
		return "x"
	else
		return "z"
	end
end

function round(x)
	if x%2 ~= 0.5 then
		return math.floor(x+0.5)
	end
	return x-0.5
end

function GetMinMax(p_Min, p_Max)
	local s_Min = p_Min
	local s_Max = p_Max
	if(p_Min.x > p_Max.x) then
		s_Min.x = p_Max.x;
		s_Max.x = p_Min.x;
	end
	if(p_Min.y > p_Max.y) then
		s_Min.y = p_Max.y;
		s_Max.y = p_Min.y;
	end
	if(p_Min.z > p_Max.z) then
		s_Min.z = p_Max.z;
		s_Max.z = p_Min.z;
	end
end

local function ZigZag(worker, distanceA, distanceB, flip, push)
	local x = 0
	local z = push

	local xInvert = false
	print("a: " .. distanceA)
	print("b: " .. distanceB)
	for i = 0, distanceA, 1 do
		for i2 = push, distanceB, 1 do

			if (x == distanceB) then
				xInvert = true
			end
			if (x == push) then
				xInvert = false
			end


			if (flip == false) then
				-- add this value?
				worker.path[#worker.path + 1] = {worker.start.x + x, worker.start.z + z} -- Draw current pos
			else
				worker.path[#worker.path + 1] = {worker.start.x + z, worker.start.z + x} -- Draw current pos
			end
			if(xInvert) then
				x = x - 1
				worker.turn[#worker.turn + 1] = "south"
			else
				x = x + 1
				worker.turn[#worker.turn + 1] = "north"
			end

			if (flip == false) then
				-- add this value?
				worker.path[#worker.path + 1] = {worker.start.x + x, worker.start.z + z} -- Draw current pos
			else
				worker.path[#worker.path + 1] = {worker.start.x + z, worker.start.z + x} -- Draw current pos
			end
		end
		if(z == distanceA) then
			return -- Wait what?
		end
		worker.turn[#worker.turn + 1] = "left"
		-- push left?
		z = z + 1

		-- Why?
		if(flip == false) then
			worker.path[#worker.path + 1] = {worker.start.x + x, worker.start.z + z} -- Draw current pos
		else
			worker.path[#worker.path + 1] = {worker.start.x + z, worker.start.z + x} -- Draw current pos
		end


	end

end


local function GeneratePath(p_Workers, p_Orientation)
	for k,worker in pairs(p_Workers) do

		local s_Distance = {
			x = math.abs(worker.start.x - worker.stop.x),
			y = math.abs(worker.start.y - worker.stop.y),
			z = math.abs(worker.start.z - worker.stop.z)
		}

		local s_Orientation = GetOrientation(worker.start, worker.stop)
		local safeZone = 2

		if(s_Orientation == "x") then
			ZigZag(worker, 1, s_Distance.x, false, 0)
			ZigZag(worker, s_Distance.x , s_Distance.z, true, 2)
		else
			ZigZag(worker, 1, s_Distance.z, true, 0)
			ZigZag(worker, s_Distance.z, s_Distance.x, false, 2)
		end
	end
	return p_Workers
end

function PrepareTask(p_Params)
	local s_Min, s_Max = GetMinMax(p_Params.start, p_Params.stop)

	local s_Orientation = GetOrientation(s_Min, s_Max)
	local s_Dist = getDist(s_Min, s_Max)

	--TODO: Calculate optimal number of workers
	local s_WorkerCount = 1

	if(s_Orientation == "x" and s_Dist.x < s_WorkerCount) then
		s_WorkerCount = s_Dist.x
	end
	if(s_Orientation == "z" and s_Dist.z < s_WorkerCount) then
		s_WorkerCount = s_Dist.x
	end

	local increment = {x = 0, z = 0}
	increment.x = round(s_Dist.x / s_WorkerCount);
	increment.z = round(s_Dist.z / s_WorkerCount);

	local s_Workers = {}
	for i = 0, s_WorkerCount, 1 do
		local s_Start = { x = 0, z = 0, y = 0}
		local s_Stop = { x = 0, z = 0, y = 0}

		if(s_Orientation == "x") then
			s_Start.x = s_Min.x + (i * increment.x)
			s_Start.z = s_Min.z

			s_Stop.x = s_Max.x + (i + 1) * increment.x
			s_Stop.z = s_Max.z
		else

			s_Start.x = s_Min.x
			s_Start.z = s_Min.z + (i * increment.z)

			s_Stop.x = s_Max.x
			s_Stop.z = s_Min.z + (i + 1) * increment.z - 1
		end


		s_Workers[#s_Workers + 1] ={start = s_Start, stop = s_Stop, path = {}, turn = {}}

	end

	return GeneratePath(s_Workers, s_Orientation)

end
local start = {x = 7,y = 0, z = 23}
local stop = {x = 1, y= 0, z = 80}

local params = {
	start = start,
	stop = stop
}


local file = fs.open("out","w")
file.write(textutils.serialize(PrepareTask(params)))
file.close()
