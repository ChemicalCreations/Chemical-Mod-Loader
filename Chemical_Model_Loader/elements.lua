local extraStartID = 100000
extraIDs = {}
modelElements = {} -- table of custom elements

local readyPlayers = {}
addEvent("onModelAdd")
addEvent("onModelRemove")
addEvent("onPlayerRequestExtraModelsStart", true)



do
    local idn = extraStartID
    function getExtraPotentialID()
        for i=idn, idn+100000 do 
            idn = idn+1
            if extraIDs[idn]==nil then
                return idn
            end
        end
    end
end

do
    local i = {}
    function getExtraPotentialName(data)
        local n = "cc_"
        i[data.source_id] = (i[data.source_id] or 0)+1
        n = n..tostring(data.source_id)
        n = n.."_model_"
        n = n..tostring(i[data.source_id])
        if extraIDs[n]==nil then return n end
    end
end

local indexProperties = {
    ["handlingX"] = {animGroup=true, monetary=true, headLight=true, tailLight=true, centerOfMassX=true, centerOfMassY=true, centerOfMassZ=true},
    ["handling"] = {"id", "mass", "turnMass", "dragCoeff", "centerOfMassX", "centerOfMassY", "centerOfMassZ", "percentSubmerged", "tractionMultiplier", "tractionLoss", "tractionBias", "numberOfGears", "maxVelocity", "engineAcceleration", "engineInertia", "driveType", "engineType", "brakeDeceleration", "brakeBias", "ABS", "steeringLock", "suspensionForceLevel", "suspensionDamping", "suspensionHighSpeedDamping", "suspensionUpperLimit", "suspensionLowerLimit", "suspensionFrontRearBias", "suspensionAntiDiveMultiplier", "seatOffsetDistance", "collisionDamageMultiplier", "monetary", "modelFlags", "handlingFlags", "headLight", "tailLight", "animGroup"},
    ["model"] = {"id", "dff", "txd", "category", "handlingID", "name", "animGroup", "class", "frequency", "flags", "comprules", "wheelModelID", "wheelSizeF", "wheelSizeR", "tuner"},
}
function getHandlingValue(value, index) -- roughly taken from hedit resource
    local property = indexProperties.handling[index]
    if type(value)~="string" or value=="" then return nil, false end
    if property==nil then
        return nil, false
    elseif property=="id" then
        if tonumber(value) then return nil, false end
        return value, property
    elseif property=="engineType" then
        value = string.lower(value)
        value = (value=="p" and "petrol") or (value=="d" and "diesel") or (value=="e" and "electric")
        return value or nil, value and property or false
    elseif property=="driveType" then
        value = string.lower(value)
        value = (value=="f" and "fwd") or (value=="r" and "rwd") or (value=="4" and "awd")
        return value or nil, value and property or false
    elseif property=="modelFlags" or property=="handlingFlags" then
        value = tonumber("0x"..value)
        return value or nil, value and property or false
    elseif property=="ABS" then
        return value=="1" and true or value=="0" and false,  (value=="0" or value=="1") and property or false
    elseif tonumber(value) then
        return tonumber(value), property
    end
    return nil, false
end

function patchExtraModelData(id)
    local data = extraIDs[id]
    assert(data)
    assert(data.source_id)
    local name, model
    local t = type(id)
    name = t=="string" and id or data.name or getExtraPotentialName(data)
    model = t=="number" and id or data.model or getExtraPotentialID()
    if name and model then
        if extraIDs[name] and extraIDs[name]~=data then outputDebugString("Conflicting data entry with id name: "..tostring(name), 2) end
        if extraIDs[model] and extraIDs[model]~=data then outputDebugString("Conflicting data entry with id model: "..tostring(model), 2) end
        extraIDs[name] = data
        extraIDs[model] = data
        data.resourceRoot = sourceResourceRoot
        if sourceResourceRoot then
            local name = getResourceName(sourceResource)
            data.resource = name
            if name then
                data.model_dff = ":"..name.."/"..data.model_dff
                data.model_txd = ":"..name.."/"..data.model_txd
            end
        end
        data.model_id = nil
        data.elements = data.elements or {}
        data.original = data.original or {}
        if data.model_type=="vehicle" then
            if not data.handling then data.handling = {} end
            if type(data.handling)=="string" then
                local handling, index = {}, 1
                for value in string.gmatch(data.handling, "[^%s]+") do
                    local value, property = getHandlingValue(value, index)
                    if property then
                        handling[property] = value
                        index = index+1
                    else
                        index = false
                        break
                    end
                end
                if index==36 then
                    handling.centerOfMass = {
                        data.centerOfMassX,
                        data.centerOfMassY,
                        data.centerOfMassZ,
                    }
                    data.handling = handling
                else
                    data.handling = {}
                    outputDebugString(inspect{"Invalid Handling String Import:", id}, 2)
                end
            end
            local h = getModelHandling(data.source_id)
            for i, v in pairs(h) do
                if data.original[i]==nil then data.original[i] = data.handling[i] or v end
                if data.handling[i]==nil then
                    data.handling[i] = v
                end
            end
        end
    else
        outputDebugString("Unable to load model >>> Name:"..tostring(name)..' Model:'..tostring(model))
        return false
    end
    data.name, data.model = name, model
    return model, name
end

function removeModelID(id)
    if type(id)~="number" and type(id)~="string" then return false end
    if id~=id or id==1/0 then return false end
    local data = extraIDs[id]
    if data then
        local name = data.name
        local id = data.model
        if extraIDs[name]==data then
            triggerEvent("onModelRemove", root, id, data.model_type)
            for player in pairs(readyPlayers) do
                triggerClientEvent(player, "onClientRecieveModelElementID", root, id, false)
            end
            extraIDs[id] = nil
            extraIDs[name] = nil
            for element in pairs(data.elements) do
                modelElements[element] = nil
                triggerEvent("onElementModelChange", element, id, data.source_id)
            end
            return true
        end
    end
end
function addModelID(id, data)
    assert(type(id)=="number" or type(id)=="string")
    assert(id==id and id~=1/0)
    assert(type(data)=="table")
    local name = type(id)=="string" and id or data.name
    local model = type(id)=="number" and id or data.model
    local announce = false
    if sourceResourceRoot and extraIDs[id] then
        local name = getResourceName(sourceResource)
        if name and type(extraIDs[id].model_dff)=="string" and string.find(extraIDs[id].model_dff, "^%:"..name.."/") then
            announce = false
        end
    end
    if extraIDs[name] and not model then
        if announce then print("Overwriting existing model:", id, extraIDs[name].model, extraIDs[name].name) end
        data.model = extraIDs[name].model
        data.elements = extraIDs[name].elements
        extraIDs[name] = nil
        extraIDs[data.model] = nil
    elseif extraIDs[model] and not name then
        if announce then print("Overwriting existing model:", id, extraIDs[model].model, extraIDs[model].name) end
        data.name = extraIDs[model].name
        data.elements = extraIDs[model].elements
        extraIDs[model] = nil
        extraIDs[data.name] = nil
    elseif model and name and extraIDs[model]==extraIDs[name] then
        if announce then print("Overwriting existing model:", id, extraIDs[model].model, extraIDs[model].name) end
        data.name = name
        data.model = model
        extraIDs[model] = data
        extraIDs[name] = data
    end
    if extraIDs[model] and name and name~=extraIDs[model].name then
        print("New Model (", model, ") Add Model 'Model Number' Conflict - Removing model:", extraIDs[model].model, extraIDs[model].name)
        removeModelID(extraIDs[model].model)
    end
    if extraIDs[name] and model and model~=extraIDs[name].model then
        print("New Model (", name, ") Add Model 'Name' Conflict - Removing model:", extraIDs[name].model, extraIDs[name].name)
        removeModelID(extraIDs[name].model)
    end
    extraIDs[id] = data
    local id, name = patchExtraModelData(id)
    if id and name then
        for player in pairs(readyPlayers) do
            triggerClientEvent(player, "onClientRecieveModelElementID", root, id, data)
        end
        triggerEvent("onModelAdd", root, id, data.model_type)
    end
    return id, name
end

function getExtraModels()
    local models = {}
    for id, data in pairs(extraIDs) do
        if id==data.model then
            models[id] = data.model_type
        end
    end
    return models
end

function getExtraModelsData()
    local models = {}
    for id, data in pairs(extraIDs) do
        if id==data.model then
            models[id] = {
                model = data.model,
                name = data.name,
                type = data.model_type,
                dff = data.model_dff,
                txd = data.model_txd,
            }
        end
    end
    return models
end

addEventHandler("onResourceStart", resourceRoot, function()
    local list = {}
    for id, data in pairs(newModels) do
        local model = addModelID(id, data)
        if not model then outputDebugString("Loading Vehicle Error: "..tostring(id), 2) end
    end
end)

addEventHandler("onPlayerRequestExtraModelsStart", root, function()
    local player = client
    if readyPlayers[player] then return kickPlayer(player) end
    readyPlayers[player] = true
    triggerClientEvent(player, "onClientRecieveModelElementIDs", root, extraIDs)
    triggerClientEvent(player, "onClientRecieveModelElements", root, modelElements)
end)

addEventHandler("onPlayerQuit", root, function()
    local player = source
    if readyPlayers[player] then readyPlayers[player] = nil end
end)

local _getElementModel, _setElementModel = getElementModel, setElementModel
addEventHandler("onElementDestroy", root, function()
    local element = source
    if modelElements[element] then
        local data = extraIDs[modelElements[element]]
        if data and data.elements then
            data.elements[element] = nil
        end
        modelElements[element] = nil
    end
end, true, "low")


function setElementExtraModel(element, model)
    local data = extraIDs[model]
    if data then
        if triggerEvent("onElementModelChange", element, modelElements[element] or _getElementModel(element), model) then
            local id = data.source_id or model
            if id~=data.source_id then outputDebugString("Unable to properly set element model > Name:"..tostring(data.name)..' > Model:'..tostring(data.model)..' > Source Model:'..tostring(data.source_id)) end
            local res = true
            if modelElements[element] then
                local data = extraIDs[modelElements[element]]
                if data and data.elements then
                    res = data.elements[element] or res
                    data.elements[element] = nil
                end
            end
            modelElements[element] = model
            data.elements[element] = res
            local eType = getElementType(element)
            local set = id==_getElementModel(element) or _setElementModel(element, id)
            if set and eType=="vehicle" then -- set correct handling
                for i, v in pairs(data.handling) do setVehicleHandling(element, i, v) end
            end
            triggerClientEvent("onClientRecieveModelElement", element, model)
            return set
        end
    elseif modelElements[element] then
        if triggerEvent("onElementModelChange", element, modelElements[element] or _getElementModel(element), model) then
            local data = extraIDs[modelElements[element]]
            if data and data.elements then data.elements[element] = nil end
            modelElements[element] = nil
            triggerClientEvent("onClientRecieveModelElement", element, model)
            return _setElementModel(element, model)
        end
    else
        if triggerEvent("onElementModelChange", element, _getElementModel(element), model) then
            return _setElementModel(element, model)
        end
    end
    return false
end

addDebugHook("preEvent", function(rec, event, source, client, file, line, funcRes, funcFile, funcLine, old, new)
    local element = source 
    local model = modelElements[element]
    if rec~=resource and model then
        local valid = triggerEvent("onElementModelChange", element, model, new)
        if valid then
            modelElements[element] = nil
            _setElementModel(model, new)
        end
        return "skip"
    end
end, {"onElementModelChange"})
addDebugHook("preEventFunction", function(eventResource, eventName, eventSource, eventClient, eventFilename, eventLineNumber, functionResource, functionFilename, functionLineNumber, old, new)
    if eventResource==resource and not (extraIDs[old] or extraIDs[new]) then
        return "skip"
    end
end, {"onElementModelChange"})
