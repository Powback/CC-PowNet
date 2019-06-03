local m_Data = {}

function setData(p_Env, p_Key, p_Data)
    if(m_Data[p_Env] == nil) then
        error("Env not initialized")
        return false
    end
    m_Data[p_Env][p_Key] = p_Data
    return true
end
function getData(p_Env, p_Key)
    if(m_Data[p_Env] == nil) then
        error("Env not initialized")
        return false
    end
    if(m_Data[p_Env][p_Key] == nil) then
        error("Key not found")
        return false
    end
    return m_Data[p_Env][p_Key]
end

function saveData()
    if not fs.exists("data") then
        fs.makeDir("data")
        print("Data directory created")
        sleep(1)
    end

    for l_Env,l_EnvData in pairs(m_Data) do
        local file = fs.open("data/" + l_Env, "w")
        file.write(textutils.serialize(l_EnvData))
        file.close()
    end
    return true
end

function loadData(p_Env)
    if(not fs.exists("data/" + m_Env)) then
        error("No data of that type stored.")
        return false
    end
    local file = fs.open("data/" + m_Env,"r")
    local data = file.readAll()
    file.close()
    return textutils.unserialize(data)
end

function Init(p_Env)
    m_Data[p_Env] = {}
    if(fs.exists("data/" + p_Env)) then
        m_Data[p_Env] = loadData(p_Env)
    else
        saveData();
    end
    return m_Data[p_Env];
end
