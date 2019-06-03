-- Server
rednet.open("top")

local m_Turtles = {}
local m_Map = {}
local m_StorageMin = {x = -825, z = 525, y = 4}
local m_StorageMax = {x = -829, z = 520, y = 6}
local m_Storage = {x = -829, z = 525, y = 10}


function ReportStatus()
	local s_Message = {
		name = "ServerStatus",
		realm = "Server",
		server = "Main",
		status = "Online"
	}
	rednet.broadcast(textutils.serialize( s_Command ))
end


function OnRegisterWorker( p_Id,  p_Command )
	print(p_Command.pos.x)
	local s_Pos = p_Command.pos
	print("Registering: " .. p_Id .. " | " .. "Pos: X:" .. s_Pos.x .. ", Y: ".. s_Pos.y .. " Z: " .. s_Pos.z)
	m_Turtles["turtle_" .. p_Id] = {
		id = p_Id,
		pos = s_Pos,
		direction = "s";
		online = true,
		registered = os.time(),
		lastTick = os.time()
	}

	local s_Command = {
		name = "RegisterTurtle",
		data = m_Turtles["turtle_" .. p_Id]
	}

	local s_DockCommand = {
		name = "DockTurtle",
		id = p_Id
	}
	rednet.broadcast(textutils.serialize( s_Command ))
	rednet.broadcast(textutils.serialize( s_DockCommand ))
	return "Registered"
end


function OnRequestUpdate( p_Id,  p_Command )
	local s_Command = {
		name = "GetFullUpdate",
		realm = "Server",
		data = m_Turtles
	}
	rednet.send(p_Id, textutils.serialize( s_Command ))
	return "Sent update"
end

local m_Commands = {
	RegisterWorker = OnRegisterWorker,
	RequestUpdate = OnRequestUpdate,
}

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




function OnRecieveCommand( p_Id, p_Command )
	print(p_Command.name)
	local s_CommandFunction = m_Commands[p_Command.name]
	if (s_CommandFunction == nil) then
		print("No command with that name found")
		return
	end
	print("Executing Command: " .. p_Command.name)
	local s_Result = s_CommandFunction(p_Id, p_Command)
	if(s_Result == nil) then
		print(p_Command.name .. " returned nil")
		return
	end
	print("end")

end

function Start()
	ReportStatus()
	while(true) do
		print("Waiting for signal...")
		local id, text = rednet.receive() -- need to capture the output from the receive in some vars
		print(id .. ": " .. text)
		local s_Command = ParseCommand(text)
		if(s_Command ~= nil) then
			OnRecieveCommand(id, s_Command)
		else
			print("error " .. id .. ": " .. text)
		end
	end
end

Start()