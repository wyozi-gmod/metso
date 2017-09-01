local metso = include("../metso/metso.lua")
metso.provideFallback("poker", {
	driver = "sqlite"
})

local conn = metso.get("poker")

conn:query("CREATE TABLE metsotest(key VARCHAR(32), val VARCHAR(32))"):next(function()
	return conn:query("INSERT INTO metsotest (key, val) VALUES (?, ?)", {"hello'", "'--world"})
end):next(function()
	return conn:query("SELECT * FROM metsotest")
end):done(function(data)
	print("brilliant:")
	PrintTable(data)

	conn:query("DROP TABLE metsotest")
end)