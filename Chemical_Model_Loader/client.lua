local extraIDs = {}
local extraModelIDs = {}
local modelElements = {} -- table of vehicles

addEvent("onClientModelAdd")
addEvent("onClientModelRemove")

addEvent("onClientRecieveModelElementIDs", true)
addEvent("onClientRecieveModelElementID", true)
addEvent("onClientRecieveModelElements", true)
addEvent("onClientRecieveModelElement", true)
addEvent("onClientRecieveVehicleHandling", true)


local _getElementModel, _setElementModel = getElementModel, setElementModel
addEventHandler("onClientElementDestroy", root, function()
    local element = source
    if modelElements[element] then
        local data = extraIDs[modelElements[element]]
        if data and data.elements then
            data.elements[element] = nil
        end
        modelElements[element] = nil
    end
end, true, "low")

function getExports()
    local list = {}
    for i, f in pairs(getResourceExportedFunctions()) do
        if _G[f] then
            list[#list+1] = f
        end
    end
    return list
end

function setElementExtraModel(element, model)
    local data = extraIDs[model]
    if data then
        if triggerEvent("onClientElementModelChange", element, modelElements[element] or _getElementModel(element), model) then
            local id = data.model_id or data.source_id or model
            if id~=data.model_id then outputDebugString("Unable to properly set element local model > Name:"..tostring(data.name)..' > Model:'..tostring(data.model)..' > Source Model:'..tostring(data.source_id)) end
            if modelElements[element] then
                local data = extraIDs[modelElements[element]]
                if data and data.elements then data.elements[element] = nil end
            end
            modelElements[element] = model
            data.elements[element] = true
            local eType = getElementType(element)=="vehicle"
            local h = eType and getVehicleHandling(element)
            local u = eType and getVehicleUpgrades(element)
            local o = eType and isElementLocal(element) and getVehicleOccupants(element)
            local set = _setElementModel(element, id)
            if h and set then for i, v in pairs(h) do setVehicleHandling(element, i, v) end end
            if u and set then for i, v in pairs(u) do addVehicleUpgrade(element, v) end end
            if o and set then for seat, ped in pairs(o) do if isElementLocal(ped) then warpPedIntoVehicle(ped, element, seat) end end end
            return set
        end
    elseif modelElements[element] then
        if triggerEvent("onClientElementModelChange", element, modelElements[element] or _getElementModel(element), model) then
            local data = extraIDs[modelElements[element]]
            if data and data.elements then data.elements[element] = nil end
            modelElements[element] = nil
            return _setElementModel(element, model)
        end
    else
        _setElementModel(element, model)
    end
    return false
end

addDebugHook("preEvent", function(rec, event, source, client, file, line, funcRes, funcFile, funcLine, old, new)
    local element = source 
    local model = modelElements[element]
    if rec~=resource and model then
        if new==nil then modelElements[element] = nil return end
        local valid = triggerEvent("onClientElementModelChange", element, model, new or old)
        if valid then
            modelElements[element] = nil
            _setElementModel(element, new or old)
        end
        return "skip"
    end
end, {"onClientElementModelChange"})
addDebugHook("preEventFunction", function(eventResource, eventName, eventSource, eventClient, eventFilename, eventLineNumber, functionResource, functionFilename, functionLineNumber, old, new)
    if eventResource==resource and not (extraIDs[old] or extraIDs[new]) then
        return "skip"
    end
end, {"onClientElementModelChange"})

local modelResources = {}
local loadModelID
local _setVehicleModelWheelSize = setVehicleModelWheelSize
function loadModelID(id, data)
    if data==false or extraIDs[id] then
        local ret = data==false
        local data = extraIDs[id]
        local resName = data.resource
        if resName then
            if modelResources[resName] then
                modelResources[resName][data] = nil
                if next(modelResources[resName])==nil then modelResources[resName] = nil end
            end
        end
        if data then
            triggerEvent("onClientModelRemove", root, data.model, data.model_type)
            for element in pairs(data.elements) do
                setElementExtraModel(element, data.source_id)
            end
            if data.model_id then engineFreeModel(data.model_id) end
            extraModelIDs[data.model_id] = nil
            extraIDs[id] = nil
            extraIDs[data.model] = nil
            extraIDs[data.name] = nil
        end
        if ret then return end
    end
    extraIDs[id] = data or nil
    if data and not data.model_id then
        data.elements = data.elements or {}
        local t = type(id)
        local name = t=="string" and id or data.name
        local model = t=="number" and id or data.model
        if id~=name and extraIDs[name]==nil then extraIDs[name] = data end
        if id~=model and extraIDs[model]==nil then extraIDs[model] = data end
        data.model_id = engineRequestModel(data.model_type, data.model_type=="object" and 1337 or data.source_id)
        if data.model_id then
            extraModelIDs[data.model_id] = data.model
            local backup = data.source_id
            addEventHandler("onClientResourceStop", resourceRoot, function()
                if extraModelIDs[data.model_id] == data.model then
                    if getElementModel(localPlayer)==data.model_id then
                        setElementModel(localPlayer, data.source_id or backup)
                    end
                    engineFreeModel(data.model_id)
                    extraModelIDs[data.model_id] = nil
                end
            end, false)
            if data.model_info then
                _setVehicleModelWheelSize(data.model_id, "front_axle", data.model_info.wheelSizeF)
                _setVehicleModelWheelSize(data.model_id, "rear_axle", data.model_info.wheelSizeR)
            end
            local resName = data.resource
            if resName then
                modelResources[resName] = modelResources[resName] or {}
                modelResources[resName][data] = true
            end
            if getResourceFromName(data.resource) or not data.resourceRoot then
                if data.model_col then
                    local model = engineLoadCOL(data.model_col)
                    if model then engineReplaceCOL(model, data.model_id) end
                end
                if data.model_txd then
                    local model = engineLoadTXD(data.model_txd)
                    if model then engineImportTXD(model, data.model_id) end
                end
                if data.model_dff then
                    local model = engineLoadDFF(data.model_dff)
                    if model then engineReplaceModel(model, data.model_id) end
                end
            end
            for element in pairs(data.elements) do
                setElementExtraModel(element, data.model)
            end
            local trig = triggerEvent("onClientModelAdd", root, data.model, data.model_type)
            return true
        end
    end
end
addEventHandler("onClientResourceStart", root, function(res)
    local made = {}
    local resName = getResourceName(res)
    local info = resName and modelResources[resName]
    if info then
        for data in pairs(info) do
            if data.model_col then
                local model = engineLoadCOL(data.model_col)
                if model then engineReplaceCOL(model, data.model_id) end
            end
            if data.model_txd then
                local model = engineLoadTXD(data.model_txd)
                if model then engineImportTXD(model, data.model_id) end
            end
            if data.model_dff then
                local model = engineLoadDFF(data.model_dff)
                if model then engineReplaceModel(model, data.model_id) end
            end
        end
    end
end)

addEventHandler("onClientRecieveModelElementID", root, loadModelID, false)
addEventHandler("onClientRecieveModelElementIDs", root, function(IDs)
    for id, data in pairs(IDs) do
        if type(id)=="number" then
            loadModelID(id, data)
        end
    end                  
end, false)

addEventHandler("onClientRecieveModelElements", root, function(elements)
    for element, model in pairs(elements) do
        setElementExtraModel(element, model)
    end
end, false)

addEventHandler("onClientRecieveModelElement", root, function(model)
    if extraIDs[model] then
        setElementExtraModel(source, model)
    end
end)

addEventHandler("onClientRecieveVehicleHandling", root, function(model, property, value)
    local data = extraIDs[model]
    if data then
        data.handling[property] = value
    end
end, false)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent("onPlayerRequestExtraModelsStart", localPlayer)
end, false)

function getExtraModels()
    local models = {}
    for id, data in pairs(extraIDs) do
        if id==data.model then
            models[id] = data.model_type
        end
    end
    return models
end

function getModelGTAID(model)
    return extraIDs[model] and extraIDs[model].model_id or model
end

function getModelSourceID(model)
    return extraIDs[model] and extraIDs[model].source_id or model
end

local _cloneElement = cloneElement
function cloneElement(element)
    if modelElements[element] then
        local model = modelElements[element]
        local clone = _cloneElement(element)
        if clone then
            if sourceResourceRoot then
                setElementParent(clone, sourceResourceRoot)
                addEventHandler("onClientResourceStop", sourceResourceRoot, function() destroyElement(clone) end, false)
            end
            modelElements[clone] = model
            if getElementType(clone)=="vehicle" then
                for i, v in pairs(data.handling) do setVehicleHandling(clone, i, v) end
            end
            return clone
        end
        return false
    else
        return _cloneElement(element)
    end
end

local _getElementModel = getElementModel
function getElementModel(vehicle)
    return modelElements[vehicle] or _getElementModel(vehicle)
end

local _setElementModel = setElementModel
function setElementModel(element, model)
    if extraIDs[model] or modelElements[element] then
        return setElementExtraModel(element, model)
    else
        if triggerEvent("onClientElementModelChange", element, _getElementModel(element), model) then
            return _setElementModel(element, model)
        end
    end
end


local _createObject = createObject
function createObject(model, ...)
    local data = extraIDs[model]
    if data then
        if type(model)~="number" then return false end
        local object = _createObject(data.source_id, ...)
        if not object then outputDebugString("Unable to create object > Name:"..tostring(data.name)..' > Model:'..tostring(data.model)..' > Source Model:'..tostring(data.source_id)) return false end
        if sourceResourceRoot then
            setElementParent(object, sourceResourceRoot)
            addEventHandler("onClientResourceStop", sourceResourceRoot, function() destroyElement(object) end, false)
        end
        modelElements[object] = model
        return object
    else
        return _createObject(model, ...)
    end
end

local _createPed = createPed
function createPed(model, ...)
    local data = extraIDs[model]
    if data then
        if type(model)~="number" then return false end
        local ped = _createPed(data.source_id, ...)
        if not ped then outputDebugString("Unable to create ped > Name:"..tostring(data.name)..' > Model:'..tostring(data.model)..' > Source Model:'..tostring(data.source_id)) return false end
        if sourceResourceRoot then
            setElementParent(ped, sourceResourceRoot)
            addEventHandler("onClientResourceStop", sourceResourceRoot, function() destroyElement(ped) end, false)
        end
        modelElements[ped] = model
        return ped
    else
        return _createPed(model, ...)
    end
end

local _createVehicle = createVehicle
function createVehicle(model, ...)
    local data = extraIDs[model]
    if data then
        if type(model)~="number" then return false end
        local vehicle = _createVehicle(data.source_id, ...)
        if not vehicle then outputDebugString("Unable to create client vehicle > Name:"..tostring(data.name)..' > Model:'..tostring(data.model)..' > Source Model:'..tostring(data.source_id)) return false end
        if sourceResourceRoot then
            setElementParent(vehicle, sourceResourceRoot)
            addEventHandler("onClientResourceStop", sourceResourceRoot, function() destroyElement(vehicle) end, false)
        end
        modelElements[vehicle] = model
        for i, v in pairs(data.handling) do setVehicleHandling(vehicle, i, v) end
        return vehicle
    else
        return _createVehicle(model, ...)
    end
end
Vehicle = createVehicle

local _getVehicleNameFromModel = getVehicleNameFromModel
function getVehicleNameFromModel(model)
    if extraIDs[model] then
        if extraIDs[model].model~=model then return false end
        return extraIDs[model].friendly_name or extraIDs[model].name
    else
        return _getVehicleNameFromModel(model)
    end
end

local _getOriginalHandling = getOriginalHandling
function getOriginalHandling(model)
    if extraIDs[model] then
        return extraIDs[model].original
    else
        return _getOriginalHandling(model)
    end
end

local _getVehicleModelFromName = getVehicleModelFromName
function getVehicleModelFromName(name)
    if extraIDs[name] then
        if extraIDs[name].name~=name then return false end
        return extraIDs[name].model
    else
        return _getVehicleModelFromName(name)
    end
end

local _getVehicleName = getVehicleName
function getVehicleName(vehicle)
    if not modelElements[vehicle] then return _getVehicleName(vehicle) end
    return (extraIDs[modelElements[vehicle]].name) or _getVehicleName(vehicle)
end

local _getVehicleNameFromModel = getVehicleNameFromModel
function getVehicleNameFromModel(model)
    if extraIDs[model] then
        if extraIDs[model].model~=model then return false end
        return extraIDs[model].friendly_name or extraIDs[model].name
    else
        return _getVehicleNameFromModel(model)
    end
end


local _getVehicleModelDummyDefaultPosition = getVehicleModelDummyDefaultPosition
function getVehicleModelDummyDefaultPosition(model, dummy)
    return _getVehicleModelDummyDefaultPosition(extraIDs[model] and extraIDs[model].model_id or model)
end

local _getVehicleModelDummyPosition = getVehicleModelDummyPosition
function getVehicleModelDummyPosition(model, dummy)
    return _getVehicleModelDummyPosition(extraIDs[model] and extraIDs[model].model_id or model, dummy)
end

local _setVehicleModelDummyPosition = setVehicleModelDummyPosition
function setVehicleModelDummyPosition(model, dummy, x, y, z)
    _setVehicleModelDummyPosition(extraIDs[model] and extraIDs[model].model_id or model, dummy, x, y, z)
end

local _getVehicleModelExhaustFumesPosition = getVehicleModelExhaustFumesPosition
function getVehicleModelExhaustFumesPosition(model)
    return _getVehicleModelExhaustFumesPosition(extraIDs[model] and extraIDs[model].model_id or model)
end

local _setVehicleModelExhaustFumesPosition = setVehicleModelExhaustFumesPosition
function setVehicleModelExhaustFumesPosition(model, x, y, z)
    return _setVehicleModelExhaustFumesPosition(extraIDs[model] and extraIDs[model].model_id or model, x, y, z)
end

local _getVehicleModelWheelSize = getVehicleModelWheelSize
function getVehicleModelWheelSize(model, wheel)
    return _getVehicleModelWheelSize(extraIDs[model] and extraIDs[model].model_id or model, wheel)
end

local _setVehicleModelWheelSize = setVehicleModelWheelSize
function setVehicleModelWheelSize(model, wheel, size)
    return _setVehicleModelWheelSize(extraIDs[model] and extraIDs[model].model_id or model, wheel, size)
end


local _engineGetModelFlags = engineGetModelFlags
function engineGetModelFlags(model)
    return _engineGetModelFlags(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineResetModelFlags = engineResetModelFlags
function engineResetModelFlags(model)
    return _engineResetModelFlags(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineSetModelFlags = engineSetModelFlags
function engineSetModelFlags(model, flags, v)
    return _engineSetModelFlags(extraIDs[model] and extraIDs[model].model_id or model, flags, v)
end

--local _engineGetModelFlag = engineGetModelFlag
--function engineGetModelFlag(model, flag)
--    return _engineGetModelFlag(extraIDs[model] and extraIDs[model].model_id or model, flag)
--end

local _engineSetModelFlag = engineSetModelFlag
function engineSetModelFlag(model, flag, v)
    return _engineSetModelFlag(extraIDs[model] and extraIDs[model].model_id or model, flag, v)
end

local _engineGetModelIDFromName = engineGetModelIDFromName
function engineGetModelIDFromName(name)
    if extraIDs[name] then
        if extraIDs[name].name~=name then return false end
        return extraIDs[name].model
    else
        return _engineGetModelIDFromName(name)
    end
end

local _engineGetModelLODDistance = engineGetModelLODDistance
function engineGetModelLODDistance(model)
    return _engineGetModelLODDistance(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineResetModelLODDistance = engineResetModelLODDistance
function engineResetModelLODDistance(model)
    return _engineResetModelLODDistance(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineSetModelLODDistance = engineSetModelLODDistance
function engineSetModelLODDistance(model, distance)
    return _engineSetModelLODDistance(extraIDs[model] and extraIDs[model].model_id or model, distance)
end

local _engineGetModelNameFromID = engineGetModelNameFromID
function engineGetModelNameFromID(model)
    if extraIDs[model] then
        if extraIDs[model].model~=model then return false end
        return extraIDs[model].name
    else
        return _engineGetModelNameFromID(model)
    end
end

local _engineGetModelPhysicalPropertiesGroup = engineGetModelPhysicalPropertiesGroup
function engineGetModelPhysicalPropertiesGroup(model)
    return _engineGetModelPhysicalPropertiesGroup(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineResetModelPhysicalPropertiesGroup = engineResetModelPhysicalPropertiesGroup
function engineResetModelPhysicalPropertiesGroup(model)
    return _engineResetModelPhysicalPropertiesGroup(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineSetModelPhysicalPropertiesGroup = engineSetModelPhysicalPropertiesGroup
function engineSetModelPhysicalPropertiesGroup(model, group)
    return _engineSetModelPhysicalPropertiesGroup(extraIDs[model] and extraIDs[model].model_id or model, group)
end

local _engineGetModelTextureNames = engineGetModelTextureNames
function engineGetModelTextureNames(model)
    return _engineGetModelTextureNames(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineGetModelTextures = engineGetModelTextures
function engineGetModelTextures(model, filter)
    return _engineGetModelTextures(extraIDs[model] and extraIDs[model].model_id or model, filter)
end

local _engineGetModelTXDID = engineGetModelTXDID
function engineGetModelTXDID(model)
    return _engineGetModelTXDID(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineResetModelTXDID = engineResetModelTXDID
function engineResetModelTXDID(model)
    return _engineResetModelTXDID(extraIDs[model] and extraIDs[model].model_id or model)
end

local _engineSetModelTXDID = engineSetModelTXDID
function engineSetModelTXDID(model, txdID)
    return _engineSetModelTXDID(extraIDs[model] and extraIDs[model].model_id or model, txdID)
end

local _engineGetModelVisibleTime = engineGetModelVisibleTime
function engineGetModelVisibleTime(model)
    return _engineGetModelVisibleTime(extraIDs[model] and extraIDs[model].model_id or model, txdID)
end

local _engineSetModelVisibleTime = engineSetModelVisibleTime
function engineSetModelVisibleTime(model, timeOn, timeOff)
    return _engineSetModelVisibleTime(extraIDs[model] and extraIDs[model].model_id or model, timeOn, timeOff)
end