addEvent("onClientRecieveReplacementModels", true)

local mods = {} 

addEventHandler("onClientRecieveReplacementModels", root, function(replacements)
    for id, data in pairs(replacements) do -- add
        local mod = mods[id] or {}
        if data.col then
            local model = engineLoadCOL(data.col)
            if model then engineReplaceCOL(model, _id) end
        elseif mod.col then
            engineRestoreCOL(id)
        end
        if data.txd then
            local model = engineLoadTXD(data.txd)
            if model then engineImportTXD(model, id) end
        elseif data.dff then
            -- load internal txd
        end
        if data.dff then
            local model = engineLoadDFF(data.dff)
            if model then engineReplaceModel(model, id) end
        elseif mod.dff then
            engineRestoreModel(id)
        end
        if data.model_info then
            data.wheelSize = {getVehicleModelWheelSize(id, "front_axle"), getVehicleModelWheelSize(id, "rear_axle")}
            setVehicleModelWheelSize(id, "front_axle", data.model_info.wheelSizeF)
            setVehicleModelWheelSize(id, "rear_axle", data.model_info.wheelSizeR)
        end
    end
    for id, data in pairs(mods) do -- remove
        if data and not replacements[id] then
            if data.col then
                engineRestoreCOL(id)
            end
            if data.dff then
                engineRestoreModel(id)
            end
            if data.wheelSize then
                setVehicleModelWheelSize(id, "front_axle", wheelSize[1])
                setVehicleModelWheelSize(id, "rear_axle", wheelSize[2])
            end
        end
    end
    mods = replacements
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent("onPlayerRequestReplacementModels", localPlayer)
end)