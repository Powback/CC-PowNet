--[[

Task System
Dispatch system

The general idea here is that we can create a task
name: RemoveHill
task : dig
taskParams: min, max
priority: last by default

Idle drones will be dispatched to that task, which is split up into several tasks for each of the drones.

name: RemoveHill
task : dig
taskParams: min, max
priority: last by default
workers = [DroneId {
    task: dig
    taskParams: (adjusted) min, max
    taskProgress: progress vars
    taskVars: exact vars used in the program when updated
}]

The workers themselves will be responsible for executing the tasks, and report back how far they are along, and the saved vars for the program.
Once started again, the worker will make sure to match the previous state by navigating to the same position and direction.

Tasks can be modified on the fly. This triggers all relevant workers to store their work, get the updated data, and resume as good as possible

Vars: MaxCooperativeProjects
    -- 3 by default
        each task will get 33% of the drones.
        This is because they are slow, and would rather work at one spot.

Pri: 1,2,3,4,5
If I create a priority 2 task, it should push down the rest. 2 becomes 3, which becomes 4 etc.

Tell the drones working on a job that gets pushed out of queue or becomes completed to report status.
They should then either be dispatched to a new task or told to dock if there are none.

Before the drone does any task, it needs to consider how long it takes to move to the new position, and arox.
how much fuel is going to be used getting it done.

If the drone can get both that task done and get home safely, it will do the task before refueling.
This should also apply to resources for building drones.

The turtles should be as dumb as possible!!!

--]]