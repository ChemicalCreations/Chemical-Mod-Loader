--**Events**--
--onModelAdd - root, model_id, model_type 
--onModelRemove - root, model_id, model_type





newModels = { -- Add new models here

    [100001] = { -- an example vehicle model
        model_type = "vehicle", -- they type of model to load -- ped  vehicle  object
        model = 100001, -- custom model id 
        name = "ford_f350_md10", -- custom model name
        friendly_name = "Ford F350", -- Name returned as with getVehicleNameFromModel
        source_id = 554, -- the id of the original gta element to replicate
        model_col = nil, -- the collision file to load
        model_dff = "vehicles/yosemite.dff", -- the model file to load
        model_txd = "vehicles/yosemite.txd", -- the texture file to load
        handling = { -- use this to set vehicle default model handling
            engineAcceleration = 15, -- change the default acceleration
        },
        --model_id = nil, -- the model id recieved from engineRequestModel (do not change)
        --original = {}, -- table for original vehicle handling function call (do not change)
        --elements = {}, -- active elements of this model number
    } and nil, -- "and nil" used to prevent this example from being added to table (please remove)

}
