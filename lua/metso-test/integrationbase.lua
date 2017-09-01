-- The base class for database integration tests
local Promise = include("metso/promise.lua")

local Integration = {}
Integration.__index = Integration

function Integration:run(db)
	local function selectConst()
		return db:queryValue("SELECT 1+1"):next(function(val)
			assert(val == "2", "1+1 != '2'")
		end)
	end

	local function simpleTableOps()
		return db:query("CREATE TABLE metsotest(key VARCHAR(32), val VARCHAR(32))"):next(function()
			return db:query("INSERT INTO metsotest (key, val) VALUES (?, ?)", {"hello'", "'--world"})
		end):next(function()
			return db:query("SELECT * FROM metsotest")
		end):next(function(data)
			assert(#data == 1)

			local row = data[1]
			assert(row.key == "hello'")
			assert(row.val == "'--world")

			return db:query("DROP TABLE metsotest")
		end)
	end

	return Promise.all {
		selectConst(),
		simpleTableOps()
	}
end


return Integration