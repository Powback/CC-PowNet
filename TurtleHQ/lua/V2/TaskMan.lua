--DroneMan
--Goal: Handle drones and their status

local m_Monitor = peripheral.wrap("left")

Log("Starting...")

function Init()
    if DATA["tasks"] == nil then
        DATA["tasks"] = {}
    end
    if DATA["lastTask"] == nil then
        DATA["lastTask"] = 1
    end
end






function OnAbort()
    if(not executing) then
        return false
    end
    print("Aborting...")
    pgps.BreakExec()
    return true, "Aborted"
end

function OnAddTask(p_ID, p_Message)
    local s_TaskID = DATA["lastTask"]
    DATA["lastTask"] = DATA["lastTask"] + 1

    local s_Task = {
        id = s_TaskID,
        name = p_Message.data.name,
        priority = p_Message.data.priority or -1
    }

    local s_Work = p_Message.data.work

    local s_Task = {
        name = s_Task.name,
        id = s_Task.id,
        work = s_Work,
        progress = 0,
        enabled = true,
        paused = false
    }

    DATA["tasks"][s_Task.id] = s_Task
    return true, {id = s_Task.id}
end


function OnStartTask(p_ID, p_Message)

end
function OnPauseTask(p_ID, p_Message)

end
function OnAbortTask(p_ID, p_Message)

end



local m_DroneEvents = {
    Reboot = {
        func = OnReboot,
    },
    GoTo = {
        func = OnGoTo,
    }
}


local m_ServerEvents = { -- Runs on a different thread so that we can interrupt drones while they execute work on the Drone message thread.
    Abort = {
        callable = true,
        params = {
            name = {
            },
            id = {
            }
        },
        func = OnAbort,
    },
    Add = {
        callable = true,
        installer = true,
        params = {
            message = "Which task would you like to add?:",
            type = "list",
            name = {
                optional = false,
                description = true,
                type = "string"
            },
            priority = {
                optional = true,
                description = true,
                type = "int"
            },
            work = {
                optional = false,
                type = "option", -- single decision
                dig = {
                    type = "list",
                    min = {
                        type = "vec3",
                        optional = false
                    },
                    max = {
                        type = "vec3",
                        optional = false
                    }
                }
            },
        },
        func = OnAddTask
    },
    Start = {
        callable = true,
        params = {
            name = {
            },
            id = {
            }
        },
        func = OnStartTask
    },
    Pause = {
        callable = true,
        params = {
            name = {
            },
            id = {
            }
        },
        func = OnPauseTask
    },
    Abort = {
        callable = true,
        params = {
            name = {
            },
            id = {
            }
        },
        func = OnAbortTask
    },
}


function Render()
    print("Render!")
    m_Monitor.clear()
    m_Monitor.setCursorPos(1,1)
    m_Monitor.setTextScale(0.5)
    -- Header
    m_Monitor.write("TaskMan!")
    local i = 1
    for k,v in pairs(DATA["tasks"]) do
        i = i + 1
        m_Monitor.setCursorPos(1,i)
        m_Monitor.write(v.id .. "| " .. v.name)
    end
end


Init()
PowNet.RegisterEvents(m_ServerEvents, m_DroneEvents, Render)
SetStatus("Connected!", colors.green)
Render()


parallel.waitForAny(PowNet.main, PowNet.droneMain, PowNet.control)

print("Unhosting")
rednet.unhost(PowNet.SERVER_PROTOCOL)
