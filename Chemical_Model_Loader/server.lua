
function getExports()
    local list = {}
    for i, f in pairs(getResourceExportedFunctions()) do
        if _G[f] then
            list[#list+1] = f
        end
    end
    return list
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
                addEventHandler("onResourceStop", sourceResourceRoot, function() destroyElement(clone) end, false)
            end
            modelElements[clone] = model
            if getElementType(clone)=="vehicle" then
                for i, v in pairs(data.handling) do setVehicleHandling(clone, i, v) end
            end
            triggerClientEvent("onClientRecieveModelElement", clone, model)
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
        if triggerEvent("onElementModelChange", element, _getElementModel(element), model) then
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
        data.elements[object] = sourceResourceRoot or resourceRoot
        if sourceResourceRoot then
            setElementParent(object, sourceResourceRoot)
            local f = function() destroyElement(object) end
            addEventHandler("onResourceStop", sourceResourceRoot, f, false)
            addEventHandler("onElementDestroy", object, function() removeEventHandler("onResourceStop", sourceResourceRoot, f) end, false)
        end
        modelElements[object] = model
        triggerClientEvent("onClientRecieveModelElement", object, model)
        return object
    else
        local object = _createObject(model, ...)
        if sourceResourceRoot then
            setElementParent(object, sourceResourceRoot)
            local f = function() destroyElement(object) end
            addEventHandler("onResourceStop", sourceResourceRoot, f, false)
            addEventHandler("onElementDestroy", object, function() removeEventHandler("onResourceStop", sourceResourceRoot, f) end, false)
        end
        return object
    end
end

local _createPed = createPed
function createPed(model, ...)
    local data = extraIDs[model]
    if data then
        if type(model)~="number" then return false end
        local ped = _createPed(data.source_id, ...)
        if not ped then outputDebugString("Unable to create ped > Name:"..tostring(data.name)..' > Model:'..tostring(data.model)..' > Source Model:'..tostring(data.source_id)) return false end
        data.elements[ped] = sourceResourceRoot or resourceRoot
        if sourceResourceRoot then
            setElementParent(ped, sourceResourceRoot)
            local f = function() destroyElement(ped) end
            addEventHandler("onResourceStop", sourceResourceRoot, f, false)
            addEventHandler("onElementDestroy", ped, function() removeEventHandler("onResourceStop", sourceResourceRoot, f) end, false)
        end
        modelElements[ped] = model
        triggerClientEvent("onClientRecieveModelElement", ped, model)
        return ped
    else
        local ped = _createPed(model, ...)
        if sourceResourceRoot then
            setElementParent(ped, sourceResourceRoot)
            local f = function() destroyElement(ped) end
            addEventHandler("onResourceStop", sourceResourceRoot, f, false)
            addEventHandler("onElementDestroy", ped, function() removeEventHandler("onResourceStop", sourceResourceRoot, f) end, false)
        end
        return ped
    end
end

local _createVehicle = createVehicle
function createVehicle(model, ...)
    local data = extraIDs[model]
    if data then
        if type(model)~="number" then return false end
        local vehicle = _createVehicle(data.source_id, ...)
        if not vehicle then outputDebugString("Unable to create vehicle > Name:"..tostring(data.name)..' > Model:'..tostring(data.model)..' > Source Model:'..tostring(data.source_id)) return false end
        data.elements[vehicle] = sourceResourceRoot or resourceRoot
        if sourceResourceRoot then
            setElementParent(vehicle, sourceResourceRoot)
            local f = function() destroyElement(vehicle) end
            addEventHandler("onResourceStop", sourceResourceRoot, f, false)
            addEventHandler("onElementDestroy", vehicle, function() removeEventHandler("onResourceStop", sourceResourceRoot, f) end, false)
        end
        modelElements[vehicle] = model
        for i, v in pairs(data.handling) do setVehicleHandling(vehicle, i, v) end
        if data.colors then
            local colors = data.colors[math.random(1, #data.colors)]
            local a, b, c, d = unpack(colors)
            setVehicleColor(vehicle, a or 1, b or 1, c or 1, d or 1)
        end
        triggerClientEvent("onClientRecieveModelElement", vehicle, model)
        return vehicle
    else
        local vehicle = _createVehicle(model, ...)
        if sourceResourceRoot then
            setElementParent(vehicle, sourceResourceRoot)
            local f = function() destroyElement(vehicle) end
            addEventHandler("onResourceStop", sourceResourceRoot, f, false)
            addEventHandler("onElementDestroy", vehicle, function() removeEventHandler("onResourceStop", sourceResourceRoot, f) end, false)
        end
        return vehicle
    end
end
Vehicle = createVehicle

local _getModelHandling = getModelHandling
function getModelHandling(model)
    return extraIDs[model] and extraIDs[model].handling or _getModelHandling(model)
end

local _setModelHandling = setModelHandling
function setModelHandling(model, property, value)
    if extraIDs[model] then
        local source = extraIDs[model].source_id
        local g = _getModelHandling(source, property)
        local valid = _setModelHandling(source, property, value)
        _setModelHandling(source, property, g)
        if valid then
            extraIDs[model].handling[property] = value
            triggerClientEvent("onClientRecieveVehicleHandling", root, model, property, value)
            return true
        end
        return false
    else
        return _setModelHandling(model, property, value)
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
