addEvent("onPlayerRequestReplacementModels", true)

addEventHandler("onResourceStart", resourceRoot, function()
    local list = {}
    for id, data in pairs(newModels) do
        local model = addModelID(id, data)
        if not model then outputDebugString("Loading Vehicle Error: "..tostring(id), 2) end
    end
end)

local indexProperties = {
    ["handlingX"] = {animGroup=true, monetary=true, headLight=true, tailLight=true, centerOfMassX=true, centerOfMassY=true, centerOfMassZ=true},
    ["handling"] = {"id", "mass", "turnMass", "dragCoeff", "centerOfMassX", "centerOfMassY", "centerOfMassZ", "percentSubmerged", "tractionMultiplier", "tractionLoss", "tractionBias", "numberOfGears", "maxVelocity", "engineAcceleration", "engineInertia", "driveType", "engineType", "brakeDeceleration", "brakeBias", "ABS", "steeringLock", "suspensionForceLevel", "suspensionDamping", "suspensionHighSpeedDamping", "suspensionUpperLimit", "suspensionLowerLimit", "suspensionFrontRearBias", "suspensionAntiDiveMultiplier", "seatOffsetDistance", "collisionDamageMultiplier", "monetary", "modelFlags", "handlingFlags", "headLight", "tailLight", "animGroup"},
    ["model"] = {"id", "dff", "txd", "category", "handlingID", "name", "animGroup", "class", "frequency", "flags", "comprules", "wheelModelID", "wheelSizeF", "wheelSizeR", "tuner"},
}


function getHandlingValue(value, index) -- basically taken from hedit resource
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

function translateDataText(text, translation, source)
    --print(translation, text)
    if translation=="handling" then
        local data, list, i = {}, {}, 0
        for value in string.gmatch (text, "[^%s,]+") do
            i = i + 1
            list[i] = value
        end
        if i<36 then return false end
        i = 36
        for n=#list, 1, -1 do
            value = list[n]
            if i<1 then break end
            local value, property = getHandlingValue(value, i)
            if property then
                data[property] = value
                i = i-1
            else
                return false
            end
        end
        data.centerOfMass = {
            data.centerOfMassX,
            data.centerOfMassY,
            data.centerOfMassZ,
        }
        for i in pairs(indexProperties.handlingX) do
            data[i] = nil
        end
        if i==0 then
            --iprint("handling!", text, data)
            return data
        end
    elseif translation=="vehicles" then
        local data, list, i = {}, {}, 0
        for value in string.gmatch(text, "[_%w-%.]+") do
            i = i + 1
            list[i] = value
        end
        if i<15 then return false end
        i = 15
        for n=#list, 1, -1 do
            value = list[n]
            if i<1 then break end
            local property = indexProperties.model[i]
            if i>8 then
                value = tonumber(value)
            elseif i==1 then
                value = tonumber(value) or value
            elseif tonumber(value) then
                return false
            end
            if property and value then
                data[property] = value
                i = i-1
            elseif property then
                return false
            end
        end
        if i==0 then
            --iprint("Model!", i, text, data)
            return data
        end
    elseif translation=="carcols" then
        local data = {}
        data.id = true
        for value in string.gmatch(string.reverse(text), "[^%s]+") do
            value = string.reverse(value)
            local info = {}
            for value in string.gmatch(value, "[_%w]+") do
                info[#info+1] = tonumber(value)
                if not info[#info] then info[#info] = nil break end
            end
            if info[1]==nil then
                if not tonumber(value) and #data>0 then
                    _, _, data.id = string.find(value, "([_%w]+)")
                    if not data.id then return false end
                    --iprint("Colors!", data)
                    return data
                end
            end
            if #info<2 then return false end
            table.insert(data, 1, info)
        end
        if #data>0 then
            --iprint("Colors!", data)
            return data
        end
    elseif translation=="carmods" then
        --addVehicleUpgrade(getPedOccupiedVehicle(localPlayer or getRandomPlayer()), 1015)
        local data, i = {}, 0
        text = string.reverse(text)
        for value in string.gmatch(text, "[^%s]+") do
            value = string.reverse(value)
            i = i + 1
            if string.sub(value, #value, #value)~="," and data.id then
                break
            elseif data.id then
                table.insert(data, 1, data.id)
            end
            data.id = string.gsub(value, "[%s,]", "")
            if tonumber(data.id) then return false end
            if string.find(value, "" or "bnt_bntl_exh_nto_rf_spl_wg_fbmp_rbmp_misc_bbb_fbb_wheel_") then
                --table.insert(data, 1, value)
            else
                break
            end
        end
        if #data>0 and data.id then
            --iprint("CarMods!", data)
            return data
        end
    end
end

do -- autoLoad
    local loaded = {} or {
        [item] = {
            [loader] = {}, -- .ide, .txt, .dff, true (true = loaded from table)
            txd = {},
            dff = {},
            txt = filePath,
        }
    }
    local getFileType = function(text)
        local s, e = string.find(text, "/[^/]*$")
        if s then
            text = string.sub(text, s+1, e)
        end
        local s, e = string.find(text, ".[^.]*$")
        if s then
            local fileName = string.sub(text, 1, s-1)
            local fileType = string.sub(text, s+1)
            if fileName and fileType then return string.lower(fileType), fileName end
            return false
        end
        return false
    end
    local checkFiles
    function checkFiles(dir, subfolders, types, loaded)
        loaded = loaded or {}
        local files = pathListDir(dir)
        for i, path in pairs(files) do
            path = string.lower(path)
            local item = dir.."/"..path
            local isFolder = pathIsDirectory(item)
            if isFolder and subfolders then
                checkFiles(item, subfolders, types, loaded)
            else
                local fileType, fileName = getFileType(item)
                local itemEntry = fileType and dir--.."/"..fileName
                local file = fileOpen(item)
                local fileSize = fileGetSize(file)
                local fileText = string.lower(fileRead(file, fileSize))
                fileClose(file)
                local folder
                do
                    local s, e = string.find(dir, "/[^/]*$")
                    folder = s and string.sub(dir, s+1, e) or nil
                    if folder then folder = string.gsub(folder, " ", "") end
                end
                if fileType=="txt" or fileType=="dat" or fileType=="ide" or fileType=="cfg" then
                    local lines = {}
                    local prog = 1
                    while prog<fileSize do
                        local i, j = string.find(fileText, "\n", prog)
                        if i then
                            local s = string.sub(fileText, prog, i-1)
                            if string.find(s, "%S") then
                                lines[#lines+1] = s
                            end
                            prog = i+1
                        else
                            break
                        end
                    end
                    --iprint("WA MI GET?", fileType, fileName, itemEntry, #lines, lines)
                    local infoGroup = false
                    for i=1, #lines do
                        local data
                        local text = lines[i]
                        local s, e = string.find(text, "#")
                        if s then text = string.sub(text, 1, s-1) end
                        local groups = {"vehicles", "handling", "carcols", "carmods"}--, "gtasa_vehicleAudioSettings", "model_special_features"}
                        for i=1, #groups do
                            local check = groups[i]
                            local s, e = string.find(text, check)
                            if s then
                                infoGroup = check
                                data = translateDataText(string.sub(text, 1, s), infoGroup, item) or translateDataText(string.sub(text, e, -1), infoGroup, item)
                                break
                            end
                        end
                        local data = translateDataText(text, "vehicles", item)
                        if data then
                            if loaded[itemEntry]==nil then loaded[itemEntry] = {folder = folder} end
                            if loaded[itemEntry].models==nil then loaded[itemEntry].models = {} end
                            local info = loaded[itemEntry].models
                            if info[data.dff] then
                                outputDebugString(inspect{"duplicate vehicle.ide data", data.dff, itemEntry}, 2)
                            else
                                info[data.dff] = data
                            end
                        end
                        local data = translateDataText(text, "handling", item)
                        if data then
                            if loaded[itemEntry]==nil then loaded[itemEntry] = {folder = folder} end
                            if loaded[itemEntry].handling==nil then loaded[itemEntry].handling = {} end
                            local info = loaded[itemEntry].handling
                            if info[data.id] then
                                outputDebugString(inspect{"duplicate handling.cfg data", data.id, itemEntry}, 2)
                            else
                                info[data.id] = data
                            end
                        end
                        local data = translateDataText(text, "carcols", item)
                        if data then
                            if loaded[itemEntry]==nil then loaded[itemEntry] = {folder = folder} end
                            if loaded[itemEntry].colors==nil then loaded[itemEntry].colors = {} end
                            local info = loaded[itemEntry].colors
                            if info[data.id] then
                                if data.id~=true then outputDebugString(inspect{"multiple colors.dat data entry... extending list", data.id, itemEntry, data}, 3) end
                                for i=1, #data do
                                    info[data.id][#info[data.id]+1] = data[i]
                                end
                            else
                                info[data.id] = data
                            end
                        end
                        local data = translateDataText(text, "carmods", item)
                        if data then
                            if loaded[itemEntry]==nil then loaded[itemEntry] = {folder = folder} end
                            if loaded[itemEntry].carmods==nil then loaded[itemEntry].carmods = {} end
                            local info = loaded[itemEntry].carmods
                            if info[data.id] then
                                outputDebugString(inspect{"multiple carmods.dat data entry... extending list", data.id, itemEntry, data}, 3)
                                for i=1, #data do info[data.id][data[i]] = true end
                            else
                                info[data.id] = {}
                                for i=1, #data do info[data.id][data[i]] = true end
                            end
                        end
                    end
                elseif fileType=="txd" or fileType=="dff" or fileType=="col" then
                    loaded[itemEntry] = loaded[itemEntry] or {folder = folder}
                    loaded[itemEntry][fileType] = loaded[itemEntry][fileType] or {}
                    if loaded[itemEntry][fileType][fileName]==nil then
                        loaded[itemEntry][fileType][fileName] = item
                    else
                        outputDebugString(inspect{"Overlapping New Model Entry", item, loaded[itemEntry][fileType][fileName]}, 2)
                    end
                end
            end
        end
        return files, loaded
    end

    local checkList
    local replacements = {}
    local categoryBase = {car=550, mtruck=444, heli=417, boat=430, bike=448, train=449, trailer=450, plane=460, quad=471, bmx=481}
    local typeBase = {vehicle=550, ped=1, object=1337}
    local listPed, listVehicle, listObject, arrayObject = _G["models - ped"], _G["models - vehicle"], _G["models - object"], _G["textures - object"]
    function checkList(refresh)
        list = "New IDs"
        local files, loaded = checkFiles(list, true, {[".txt"]=true,[".dff"]=true,[".txd"]=true,[".col"]=true,})
        --outputServerLog(inspect(loaded))
        local resName = getResourceName(getThisResource())
        local mods = {}
        for id, data in pairs(getExtraModelsData()) do
            if data.dff and string.find(data.dff, "^%:"..resName.."/") then
                mods[data.dff] = data
            end
        end
        local newMods = {}
        for path, info in pairs(loaded) do
            for id, id_dff in pairs(info.dff or {}) do
                local data = {}
                local idn = tonumber(id)
                local source_id
                data.source_id = nil
                for value in string.gmatch(path, "/[^/]+")  do
                    local s, e = string.find(value, "%([%w_]*%)$")
                    local base = s and string.sub(value, s+1, e-1)
                    local basen = tonumber(base)
                    --print("G:", value, base)
                    if basen then
                        source_id = (listVehicle[basen] and basen) or (listPed[basen] and basen) or (listObject[basen] and basen)
                    elseif base=="" then
                        source_id = nil
                    elseif base then
                        source_id = listVehicle[base] or listPed[base] or listObject[base]
                    end
                end
                local _path = string.lower(path)
                if string.find(_path, "^new ids/_peds/") or _path=="new ids/_peds" then
                    data.model_type = "ped"
                    if not listPed[source_id] then source_id = nil end
                elseif string.find(_path, "^new ids/_objects/") or _path=="new ids/_objects" then
                    data.model_type = "object"
                    if not listObject[source_id] then source_id = nil end
                elseif string.find(_path, "^new ids/_vehicles/") or _path=="new ids/_vehicles" then
                    data.model_type = "vehicle"
                    if not listVehicle[source_id] then source_id = nil end
                else
                    --print("CHECKER TIME", path, id)
                    local eType = source_id or idn or id
                    if listPed[eType] then
                        data.model_type = "ped"
                    elseif listVehicle[eType] then
                        data.model_type = "vehicle"
                    elseif info.handling and info.handling[id] then
                        data.model_type = "vehicle"
                    elseif info.models and info.models[id] then
                        data.model_type = "vehicle"
                    elseif listObject[eType] then
                        data.model_type = "object"
                    else
                        data.model_type = "object"
                    end
                end
                data.name = nil
                data.friendly_name = nil
                local eType = data.model_type
                --print("eType", eType, id, idn, _path)
                if eType=="vehicle" then
                    data.source_id = (listVehicle[idn] and idn) or listVehicle[id]
                    data.handling = info.handling and info.handling[id]
                    data.colors = info.colors and (info.colors[id] or info.colors[true])
                    data.carmods = info.carmods and info.carmods[id]
                    data.model_info = info.models and info.models[id]
                    if data.model_info then
                        local category = data.model_info.category
                        data.source_id = data.source_id or categoryBase[category]
                        if data.model_info.txd then
                            if info.txd and info.txd[data.model_info.txd] then
                                data.model_txd = info.txd[data.model_info.txd] or data.model_txd
                            end
                        end
                    end
                    data.source_id = data.source_id or typeBase[eType]
                elseif eType=="ped" then
                    data.source_id = (listPed[idn] and idn) or listPed[id] or typeBase[eType]
                elseif eType=="object" then
                    data.source_id = (listObject[idn] and idn) or listObject[id] or typeBase[eType]
                end
                data.model_dff = data.model_dff or id_dff
                data.model_txd = data.model_txd or (info.txd and info.txd[id])
                data.model_col = data.model_col or (info.col and info.col[id])
                -- make propper id
                local idName = (idn and (listVehicle[idn] or listPed[idn] or listObject[idn])) or id
                local usedName = getVehicleModelFromName(idName) or listVehicle[idName] or listPed[idName] or listObject[idName]
                local dff = ":"..resName.."/"..data.model_dff
                if usedName and mods[dff] and data.model_txd then
                    if mods[dff].txd==":"..resName.."/"..data.model_txd and mods[dff].name==idName then
                        data.model_id = mods[dff].model
                        usedName = false
                    end
                end
                if usedName then
                    local bigName = string.upper(string.sub(idName, 1, 1))..string.sub(idName, 2, -1)
                    local folder = info.folder and string.gsub(info.folder, "%s*%([%w_]*%)$", "")
                    data.friendly_name = folder and folder.." ("..bigName..")" or bigName
                    idName = folder and (string.gsub(folder, "[^%w]", "_").."_"..idName) or idName
                    usedName = getVehicleModelFromName(idName) or listVehicle[idName] or listPed[idName] or listObject[idName]
                    if usedName and mods[dff] and data.model_txd then
                        if mods[dff].txd==":"..resName.."/"..data.model_txd and mods[dff].name==idName then
                            data.model_id = mods[dff].model
                            usedName = false
                        end
                    end
                    if usedName then
                        idName = idName.."_"
                        for i=1, 10000 do
                            local name = idName..tostring(i)
                            usedName = getVehicleModelFromName(name) or listVehicle[name] or listPed[name] or listObject[name]
                            if usedName and mods[dff] and data.model_txd then
                                if mods[dff].txd==":"..resName.."/"..data.model_txd and mods[dff].name==name then
                                    data.model_id = mods[dff].model
                                    usedName = false
                                end
                            end
                            if not usedName then
                                data.friendly_name = data.friendly_name.." ("..tostring(i)..")"
                                idName = name
                                break
                            end
                        end
                    end
                end
                data.name = idName
                data.friendly_name = data.friendly_name or idName
                data.friendly_name = string.upper(string.sub(data.friendly_name, 1, 1))..string.sub(data.friendly_name, 2, -1)
                data.source_id = source_id or data.source_id or typeBase[eType]
                if data.model_txd and data.source_id then
                    --print("LOADING:", eType, id, data.friendly_name, idName)
                    newMods[dff] = true
                    mods[dff] = mods[dff] or {
                        dff = data.model_dff,
                        txd = data.model_txd,
                    }
                    newModels[idName] = data
                end
            end
        end
        -- remove
        for dff, data in pairs(mods) do
            if newMods[dff]==nil then
                removeModelID(data.model)
            end
        end
        do -- replace
            local files, loaded = checkFiles("Replace IDs", true, {[".txt"]=true,[".dff"]=true,[".txd"]=true,[".col"]=true,})
            for path, info in pairs(loaded) do
                for id, id_dff in pairs(info.dff or {}) do
                    local dff = id_dff
                    local txd = (info.txd and info.txd[id])
                    local col = (info.col and info.col[id])
                    -- make propper id
                    local idn = tonumber(id) or id
                    local model = listVehicle[idn] or listPed[idn] or listObject[idn]
                    if model then
                        model = tonumber(model) or idn
                        --print("REPLACE:", model, listVehicle[model] or listPed[model] or listObject[model])
                        replacements[model] = {
                            txd = txd,
                            dff = dff,
                            col = col,
                        }   
                        if listVehicle[model] then
                            replacements[model].handling = info.handling and info.handling[id]
                            replacements[model].colors = info.colors and (info.colors[id] or info.colors[true])
                            replacements[model].carmods = info.carmods and info.carmods[id]
                            replacements[model].model_info = info.models and info.models[id]
                        end
                    end
                end
            end
            for id, data in pairs(replacements) do
                for property, value in pairs(data.handling or {}) do if property~="id" then setModelHandling(id, property, value) end end
            end
            if refresh==true then triggerClientEvent("onClientRecieveReplacementModels", root, replacements) end
        end
    end

    addEventHandler("onPlayerRequestReplacementModels", root, function()
        triggerClientEvent(client, "onClientRecieveReplacementModels", root, replacements)
    end)

    do
        addDebugHook("postFunction", function(res, func, _, file, line, id, pos, rot, vehicle)
            local data = replacements[id]
            if data then
                if data.colors then
                    local colors = data.colors[math.random(1, #data.colors)]
                    local a, b, c, d = unpack(colors)
                    setVehicleColor(vehicle, a or 1, b or 1, c or 1, d or 1)
                end
            end
            return vehicle
        end, {"createVehicle"})
    end

    checkList()
end