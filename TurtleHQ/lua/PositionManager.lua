-- PositionManager

local m_Commands = {
	WorkerRegistered = OnWorkerRegistered,
	WorkerOnline = OnWorkerOnline
}

function CreateCoords(x,y,z)
	if m_Map[x] == nil then
		m_Map[x] = {}
	end
	if m_Map[x][y] == nil then
		m_Map[x][y] = {}
	end
	if m_Map[x][y][z] == nil then
		m_Map[x][y][z] = {}
	end
end

function ReportStatus()
	local s_Message = {
		name = "ServerStatus",
		realm = "PositionManager",
		server = "Main",
		status = "Online"
	}
	rednet.broadcast(textutils.serialize( s_Command ))
end


function split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
	  if s ~= 1 or cap ~= "" then
	 table.insert(Table,cap)
	  end
	  last_end = e+1
	  s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
	  cap = pString:sub(last_end)
	  table.insert(Table, cap)
   end
   return Table
end

function ParseParams( p_Params )
	if(string.match(p_Params, ",")) then
		return split(p_Params, ',')
	else
		return p_Params
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
		print(s_CommandName .. " returned nil")
		return
	end
	print("end")

end


function Start()
	ReportStatus()
	while(true) do
		print("Waiting for signal...")
		local id, text = rednet.receive() -- need to capture the output from the receive in some vars
		local s_Command = ParseCommand(text)
		if(s_Command ~= nil) then
			OnRecieveCommand(id, s_Command)
		else
			print("error " .. id .. ": " .. text)
		end
	end
end
Start()