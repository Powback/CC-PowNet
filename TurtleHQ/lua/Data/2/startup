--TurtleManager
rednet.open("top")
local monitor = peripheral.wrap( "left" )
monitor.clear()
monitor.setCursorPos(1,1)
monitor.setTextScale(0.5)

m_ServerId = {}
local m_Turtles = {}

function MergeTables(p_Old, p_New)
	if(p_New == nil) then
		return p_Old
	end

	if(p_Old == nil) then
		return p_New
	end

	for k,v in pairs(p_New) do
		p_Old[k] = v
	end

	return p_Old
end

function OnGetFullUpdate( p_Command)
	m_Turtles = p_Command.data
	return true
end
function OnGetSingleUpdate( p_Command)
	m_Turtles[p_Command.data.id] = MergeTables(m_Turtles[p_Command.data.id], p_Command.data)
	return true
end


function ReportStatus()
	local s_Message = {
		name = "ServerStatus",
		realm = "Server",
		server = "TurtleManager",
		status = "Online"
	}
	rednet.broadcast(textutils.serialize( s_Command ))
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
	GetFullUpdate = OnGetFullUpdate,
	GetSingleUpdate = OnGetSingleUpdate,
}

function OnRecieveCommand( p_Id, p_Command )
	print(p_Command.name)
	local s_CommandFunction = m_Commands[p_Command.name]
	if (s_CommandFunction == nil) then
		print("No command with that name found")
		return
	end
	print("Executing Command: " .. p_Command.name)
	local s_Result = s_CommandFunction(p_Command)
	if(s_Result == nil) then
		print(p_Command.name .. " returned nil")
		return
	end
	print("end")

end

function DrawStatus()
	monitor.setCursorPos(1,1)
	monitor.write("Status:")	
	local i = 1;		
	for k,l_Turtle in pairs(m_Turtles) do
		i = i + 1
		monitor.setCursorPos(1,i)
		monitor.write("[" )	
		if(l_Turtle.online) then
 			monitor.setTextColor(colors.green)
 			monitor.write("O")
 			monitor.setTextColor(colors.white)
		else
			monitor.setTextColor(colors.red)
 			monitor.write("X")
 			monitor.setTextColor(colors.white)
		end
		for k,v in pairs(l_Turtle) do
			print(k)
		end
		monitor.write("] " .. l_Turtle.id .. " | " .." Pos:" .. l_Turtle.pos.x .. ", " .. l_Turtle.pos.y .. ", " .. l_Turtle.pos.z )	
		print("Write")
	end
end
function RequestUpdate()
	local s_Command = {
		name = "RequestUpdate",
		realm = "Server",
		server = "TurtleManager",
		status = "Online"
	}
	rednet.broadcast(textutils.serialize( s_Command ))
end



function Start()
	ReportStatus()
	DrawStatus()
	RequestUpdate()
	while(true) do
		print("Waiting for signal...")
		local id, text = rednet.receive() -- need to capture the output from the receive in some vars
		local s_Command = ParseCommand(text)
		if(s_Command ~= nil) then
			OnRecieveCommand(id, s_Command)
		else
			print("error " .. id .. ": " .. text)
		end
		DrawStatus()
	end
end
Start()