local metso = include("metso/metso.lua")
local Integration = include("integrationbase.lua")

local function testSQLite()
	local SQLite = setmetatable({}, {__index = Integration})
	SQLite.__index = SQLite

	return SQLite:run(metso.create {
		driver = "sqlite"
	})
end

local function testMysqlOO()
	local MysqlOO = setmetatable({}, {__index = Integration})
	MysqlOO.__index = MysqlOO

	return MysqlOO:run()
end

local Promise = include("metso/promise.lua")

print("Running DB integration tests")
Promise.all({
	testSQLite(),
	--testMysqlOO()
}):next(function()
	print("Database integration tests completed succesfully.")
end, function(e)
	print("Database integration tests failed!")
	PrintTable(e)
end)