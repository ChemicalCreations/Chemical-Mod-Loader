do -- Import functions
    local r, f = getResourceFromName("Chemical_Model_Loader")
    function f()
        r = r or getResourceFromName("Chemical_Model_Loader")
        for i, v in pairs(call(r, "getExports")) do
            _G[v] = function(...) return call(r, v, ...) end
        end
    end
    if getResourceState(r)=="running" then
        f()
    else
        print("please set resource 'Chemical_Model_Loader' to run on server startup")
        setTimer(f, 1, 1)
    end
end

-- add to meta.xml
-- 
--	<include resource="Chemical_Model_Loader"/>
--	<script src="import_chemical_models.lua" type="shared" cache="false"/>