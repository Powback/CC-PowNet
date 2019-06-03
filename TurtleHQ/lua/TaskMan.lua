local m_Tasks = {}
local m_LastTask = 0
-- Tasks
-- TaskId // Incrementing ID of the task
-- TaskName
-- TaskParams
-- TaskProgress
-- TaskWorkers

--Drones
-- Tasks[] // List of tasks, incrementing


function OnTaskProgress( p_Command )

end


-- workerId
-- taskId
function OnTaskDone( p_Command )
	-- Await instructions. After X time, make bot return to docking

end

function OnSetTask( p_Command )
	m_LastTask = m_LastTask + 1
	local s_Task = {
		taskId = m_LastTask,
		taskName = p_Command.task.name, --Dock
		taskPrams = p_Command.task.params, -- Position, Id
		taskProgress = 0,
		taskWorkers = p_Command.task.workers -- 1,2,3,4,5,6,7,8,9
	}
	for _,l_DroneId in pairs(p_Command.task.workers) do
		-- Send task to all specified workers
	end
end