--Log
rednet.open("top")
local monitor = peripheral.wrap( "left" )
monitor.setTextScale(0.5)

function newLine()
  local _,cY= monitor.getCursorPos()
  monitor.setCursorPos(1,cY+1)
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

function ParseCommand( p_Command )
	local s_Command = split(p_Command, ":")
	local s_CommandName = s_Command[1]
	local s_CommandParams = s_Command[2]
	if(s_CommandName == nil) then
		print("nil command")
		return
	end
	return {name = s_CommandName, params = s_CommandParams}
end

function OnRecieveCommand( p_Id, p_Command )
	local s_CommandName = p_Command.name
	local s_CommandParams = p_Command.params

	monitor.write("[i]" .. s_CommandName .. ": " .. tostring(s_CommandParams))
end

function Start()
	monitor.clear()
	monitor.setCursorPos(1,1)
	monitor.write("Booting")
	newLine()
	while(true) do
		print("Waiting for signal...")
		local id, text = rednet.receive() -- need to capture the output from the receive in some vars
		monitor.write("[V] " .. id .. ": " .. text)
		newLine()
		local s_Command = ParseCommand(text)
		if(s_Command ~= nil) then
			OnRecieveCommand(id, s_Command)
		else
			print("error " .. id .. ": " .. text)
		end
	newLine()
	end
end
Start()