-- TankStation
rednet.open("right")
os.loadAPI("egps")
print(egps)
egps.startGPS()
egps.setLocationFromGPS()

local m_Pos = nil


function OnMoveTo( p_Command )
	if(turtle.getFuelLevel() == 0) then
		print("Out of fuel...")
		while(turtle.getFuelLevel() == 0) do
			turtle.refuel()
		end
	end

	egps.moveTo(p_Command.pos.x, p_Command.pos.y, p_Command.pos.z)
	
	return true
end

function GetPos () 
	print("Man I am so lost right now!")
	local x, y, z = gps.locate(5)
	if not x then --If gps.locate didn't work, it won't return anything. So check to see if it did.
		print("Failed to get my location!")
		return nil
	else
		print("I am at (" .. x .. ", " .. y .. ", " .. z .. ")") --This prints 'I am at (1, 2, 3)' or whatever your coordinates are
		return {x = x, y = y, z = z}
	end
	return nil
end

function Register()
	local s_Command = {
		name = "RegisterWorker",
		realm = "Client",
		pos = m_Pos
	}
	rednet.broadcast(textutils.serialize( s_Command ))
	print("Requested Registration")
end

function ParseCommand( p_Command )
	local s_Command = textutils.unserialize( tostring(p_Command) )
	if(s_Command == nil) then
		print("Could not deserialize command?")
		return
	end
	local s_CommandName = s_Command.name
	if(s_CommandName == nil) then
		print("nil command")
		return
	end
	return s_Command
end


local m_Commands = {
	MoveTo = OnMoveTo,
}

function OnRecieveCommand(p_Command )
	local s_CommandFunction = m_Commands[p_Command.name]
	if (s_CommandFunction == nil) then
		print("No command with that name found")
		return
	end
	print("Executing Command: " .. p_Command.name)
	local s_Result = s_CommandFunction(p_Command)
	if(s_Result == true) then
		local s_Message = {
			name = "TaskDone",
		}
		rednet.broadcast(textutils.serialize( s_Command ))
	end
	if(s_Result == nil) then
		print(p_Command.name .. " returned nil")
		return
	end
end


function Start()
	m_Pos = GetPos()
	if(m_Pos == nil) then
		print("Failed to get pos, cannot continue")
		return
	end
	Register()

	while(true) do
		print("Waiting for signal...")
		local id, text = rednet.receive() -- need to capture the output from the receive in some vars
		local s_Command = ParseCommand(text)
		if(s_Command ~= nil) then
			OnRecieveCommand(s_Command)
		else
			print("error " .. text)
		end
	end
end

Start()