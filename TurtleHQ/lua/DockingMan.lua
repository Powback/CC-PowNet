rednet.open("top")
local monitor = peripheral.wrap( "right" )
monitor.clear()
monitor.setCursorPos(1,1)
monitor.setTextScale(0.5)

local m_Turtles = {}
local m_Towers = {
	{
		pos = {
			x = -820,
			y = 4,
			z = 526
		},
		freeSlot = 0,
		height = 3,
		slots = 11,
		occupants = {}
	},
	{
		pos = {
			x = -824,
			y = 4,
			z = 526
		},
		freeSlot = 0,
		height = 10,
		slots = 11,
		occupants = {}
	},
	{
		pos = {
			x = -828,
			y = 4,
			z = 526
		},
		freeSlot = 0,
		height = 10,
		slots = 11,
		occupants = {}
	}
}

function ReportStatus()
	local s_Message = {
		name = "ServerStatus",
		realm = "Server",
		server = "DockingMan",
		status = "Online"
	}
	rednet.broadcast(textutils.serialize( s_Command ))
end


function GetXZFromHeading( p_Heading )
	if( p_Heading == 0) then
		return {x = 0, z = 1}
	end
	if( p_Heading == 1) then
		return {x = 1, z = 0}
	end
	if( p_Heading == 2) then
		return {x = 0, z = -1}
	end
	if( p_Heading == 3) then
		return {x = -1, z = 0}
	end
	return false
end
function GetTowerPos( p_Index )
	local s_Pos = m_Towers[p_Index].pos
	return {x= s_Pos.x, y = s_Pos.y, z = s_Pos.z}
end
function GetXYZFromSlot( p_Tower, p_Slot)
	local s_Direction = (p_Slot % 4)
	local s_TowerPos = GetTowerPos(p_Tower)
	local s_Offset = GetXZFromHeading(s_Direction)
	local s_Ret = s_TowerPos 
	local s_yLevel = math.floor(p_Slot / 4)

	s_Ret.x = s_TowerPos.x + s_Offset.x
	s_Ret.z = s_TowerPos.z + s_Offset.z
	s_Ret.y = s_yLevel + s_TowerPos.y
	return s_Ret
end

function GetSlotPosition(p_Tower, p_Slot)
	local s_SlotHeading = p_Slot % 4
	print(s_SlotHeading)
end

function GetFreeSlot( )
	for k,v in pairs(m_Towers) do
		if(v.freeSlot < v.slots) then
			return {tower = k, slot = v.freeSlot}
		end
	end
end

function RegisterSlot( p_Id, p_Tower, p_Slot )
	m_Towers[p_Tower].occupants[m_Towers[p_Tower].freeSlot + 1] = p_Id
	m_Towers[p_Tower].freeSlot = m_Towers[p_Tower].freeSlot + 1 
end

function OnRegisterTurtle( p_Command )
	local s_Slot = GetFreeSlot()
	local s_DockingPos = GetXYZFromSlot(s_Slot.tower, s_Slot.slot)
	RegisterSlot(p_Command.data.id, s_Slot.tower, s_Slot.slot)
	print(s_DockingPos.x .. " | " .. s_DockingPos.y .. " | " .. s_DockingPos.z)
	
	print("Registered")
	m_Turtles[p_Command.data.id] = {
		tower = s_Slot.tower,
		slot = s_Slot.slot,
		dockingPos = s_DockingPos,
	}

end

function OnDockTurtle( p_Command )
	local s_Turtle = m_Turtles[p_Command.id]
	if(s_Turtle == nil) then
		print("Failed to get turtle")
	end
	local s_Command = {
		name = "SetTask",
		taskName = "Dock",
		id = p_Command.id,
		task = {
			name = "MoveTo",
			pos = s_Turtle.dockingPos
		}
	}
	rednet.broadcast(textutils.serialize( s_Command ))
end

local m_Commands = {
	RegisterTurtle = OnRegisterTurtle,
	DockTurtle = OnDockTurtle,
}

function Render()
	monitor.clear()
	monitor.setCursorPos(1,1)
	monitor.write("Status:")	
	local i = 1;		
	for k,l_Tower in pairs(m_Towers) do
		i = i + 1
		monitor.setCursorPos(1,i)
		monitor.write("[" )	
		if(l_Tower.freeSlot >= l_Tower.slots) then
 			monitor.setTextColor(colors.red)
 			monitor.write(l_Tower.freeSlot .. "/" .. l_Tower.slots)
 			monitor.setTextColor(colors.white)
		else
			monitor.setTextColor(colors.green)
 			monitor.write(l_Tower.freeSlot .. "/" .. l_Tower.slots)
 			monitor.setTextColor(colors.white)
		end
		monitor.write("]" )	
		print("Write")
	end
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

function OnRecieveCommand( p_Id, p_Command )
	local s_CommandFunction = m_Commands[p_Command.name]
	if (s_CommandFunction == nil) then
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

function Start()
	ReportStatus()
	while(true) do
		Render()
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