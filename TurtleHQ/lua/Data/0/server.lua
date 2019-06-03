rednet.open("top")

local m_Turtles = {}
local m_Map = {}

function ReportStatus()
	rednet.broadcast("ManagerOnline")
end

function OnRegister( id, p_Params )
	print(id)
	print(p_Params)
	local s_Pos = vector.new(p_Params[1],p_Params[2],p_Params[3])
	print("Pos: X:" .. s_Pos.x .. ", Y: ".. s_Pos.y .. " Z: " .. s_Pos.z)
	rednet.broadcast("pownet:workerRegistered:".. id .. ":")
end

function OnOnline( id )

end

local m_Commands = {
	register = OnRegister,
	online = OnOnline
}

function RegisterOnline( id )
	m_Turtles[id] {
		lastPing = os.time(),
		position = nil,
		task = nil
	}
end

function GetCoords(x,y,z)
	if m_Map[x] == nil then
		m_Map[x] = {}
	end
	if m_Map[x][y] == nil then
		m_Map[x][y] = {}
	end
	if m_Map[x][y][z] == nil then
		m_Map[x][y][z] = {}
	end
	return m_Map[x][y][z]
end


function dump(o)
	if(o == nil) then
		print("tried to load jack shit")
	end
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
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
	return split(p_Params, ',')
end

function ParseCommand( p_Command )
	local s_Command = split(p_Command, ":")
	local s_CommandName = s_Command[1]
	local s_CommandParams = ParseParams(s_Command[2])
	if(s_CommandName == nil) then
		print("nil command")
		return
	end
	print("params: ") 
	print(dump(s_CommandParams))
	return {name = s_CommandName, params = s_CommandParams}
end
function OnRecieveCommand( p_Id, p_Command )
	local s_CommandName = p_Command.name
	local s_CommandParams = p_Command.params

	local s_CommandFunction = m_Commands[s_CommandName]
	if (s_CommandFunction == nil) then
		print("Attempted to call a nil function: " .. tostring(s_CommandName))
		return
	end
	print("lego")
	print(tostring(s_CommandParams))
	local s_Result = s_CommandFunction(p_Id, s_CommandParams)
	if(s_Result == nil) then
		print(s_CommandName .. " returned nil")
		return
	end
	print(s_CommandName ..":")
	print(s_Result)
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