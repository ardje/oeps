local m={}
function m.configload(file,env)
        local code
        if _G._VERSION == "Lua 5.1"
        then
		-- Lua 5.1:
                code=assert(loadfile(file,"t"))
                if code then setfenv(code,env) end
        else
		-- Assuming Lua 5.2
                print("Q" .. _G._VERSION .. "Q")
                code=assert(loadfile(file,"t",env))
        end
        return code
end

function m.getconfig()
	local c={}
	local code=m.configload("/etc/oeps/config",c)
	code()
	return c
end
return m
