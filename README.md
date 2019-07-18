# PowNet
PowNet is a ComputerCraft Turtle management & task system.

Turtles will be referenced to as drones when they are using PowNet.

## Description 
PowNet uses multiple servers/modules that communicate with eachother in order to efficiently automate large parts of your base. 
Drones are doing as little logic as possible in order to centralize and conserve processing. The servers will give the drone a spesific set of instructions. If the drone fails to accomplish said instructions, it will report back why it failed, and the server will provide new instructions that takes the failure into account. 


## Disclaimer
This project is only intended for my personal use. No support will be given.

## Features:
- GUI for all modules w/ information about the state of said module.
- Networked GPS and pathfinding using A*
- Docking-station w/ configurable scale & automatic slot assignment
- Automatic drone & module updating from the MainFrame
- Priority-based tasks w/ dynamic assignment count
- Task collaboration between multiple drones
- Role-based task assignments. (Scanner-drone, worker-drone, manager-drone, assistant-drone, harvester-drone, collector-drone, etc)
- Task progress
- Task pausing/resuming/cancelling
- Remote-control software w/ GPS integration for PowNet management on the fly.
- Wizard for advanced tasks (configurable based on task)
- Task repetition and scheduling based on time, resource status or events.
- Automatic resource storage & management
- Drone task assignments based on distance to task to save fuel & transport time.

### Tasks:
- Explore
    * Assigns scanner drones to explore the specified area in order to update the MapServer for future pathfinding.
- Dig
    * Excavates a defined area. 
- Build
    * Builds a shape on the defined position
- Quarry
    * Creates tunnels around the specified area, which is then scanned for ores which are later harvested by a collector-drone.
- Farm
    * Creates a farm using the specified material (seeds, cactus, trees). The farmer will monitor the crop status and harvest & replant when the crop is ready.
- Turret
    * Drone will stand on a certain position and kill mobs that enter it's radius
- Patrol
    * Drone will follow a path and kill any mobs it encounter.
- Script
    * Drone will follow a script that's created using the remote control GUI. For example "Move to X, rightclick, collect inventory, place in chest, repeat"
- Follow
    * Drone will follow the player as long as the Remote Controll is connected and have GPS coverage.
    * Should the player/drone lose GPS coverage, a task will be dispatched to a drone that will build an other GPS station to cover the area.
- Craft
    * The drone will craft the specified item based on the current resource status. 
- Storage
    * The drone will create storage for the different materials needed to complete tasks.
- Clicker
    * Will simply click a button or lever when promted. Can be used to turn on/off machines to save resources or power. 
    
### Planned:
- Automatic resuce missions for drones that lose connection.
   * A scout will visit the last known location of the drone, search the area, find the missing drone and create a new task to recover said drone.
- GUI for structure/shape drawing 
   * Draw the foundation of your structure and have the turtles build it.
- Dynamic GPS station building based on travel paths, working area and coverage
- Dynamic chunk-loading based on travel paths and working areas.
