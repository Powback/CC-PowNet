function Login()
    local s_Label = os.getComputerLabel()
    if(s_Label == nil) then
        error("Label not set. Modules:")
        print("Server -- Main")
        print("TaskMan -- TaskManager")
        print("DockingMan -- DockingManager")
        return false
    end


end