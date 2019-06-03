#PowNet

PowNet is a Computercraft management system created to automate and manage turtles.

##PathFinding
https://github.com/blunty666/CC-Pathfinding-and-Mapping

#Modules
##Server
The server is responsible for data storage, module interaction and module updating.
All the scripts should be hosted on a disk here.

When the server reboots, it will automatically tell all the modules to restart, which will trigger their update system.
The modules will then transmit their saved data to the server, which in turn will return it back to the module once powered back on.

## NetMap
Networked pathfinding using A*

##TaskMan
TaskMan is a task manager. It's responsible for managing tasks sent to drones, as well as their progress and updates.
All tasks sent to drones should (obviously) be sent through here.

##PositionMan
Turtles mostly handle themselves just fine when it comes to positions, but sometimes they need a little encouragement.

#Commands
Commands are simple instructions that each module 