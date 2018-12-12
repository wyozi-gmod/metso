local TOML = include("toml.lua")
local Connection = include("connection.lua")

local metso = {}

metso._backends = {
	mysqloo = include("back_mysqloo.lua"),
	pg = include("back_pg.lua"),
	sqlite = include("back_sqlite.lua"),
}

-- Creates a database from table that contains connection data (credentials, dbtype) 
function metso.create(opts)
	local driver = opts.driver or "sqlite"

	local driverClass = metso._backends[driver]
	assert(not not driverClass, "driver '" .. driver .. "' not implemented.")

	local driverObj = driverClass.new(opts)

	return Connection.new(driverObj)
end

function metso._onConfigUpdate()
end

metso._config = {}

function metso._reloadConfig()
	local cfg = file.Read("metsodb.toml", "GAME")
	if not cfg then
		-- cfg not found, this is ok
		return
	end

	local b, parsed = pcall(TOML.parse, cfg)
	if not b then
		-- we want to extend default error message with a bit more information
		error("Parsing metsodb.toml failed: " .. parsed)
	end

	metso._config = parsed
	metso._onConfigUpdate()
end
metso._reloadConfig()

-- The fallback configurations in case named database is not found
metso._fallbacks = {}

function metso.provideFallback(name, opts)
	assert(type(name) == "string", "fallback database name must be a string")
	assert(type(opts) == "table", "fallback opts must be a table")

	metso._fallbacks[name] = opts
end

--- Map of connections already established to specific db names
metso._connCache = {}

--- Gets (or creates) a database connection to given database name.
--- The name comes from the table name of a database specified in metsodb.toml
function metso.get(dbname)
	assert(type(dbname) == "string", "dbname must be a string")

	local cachedConnection = metso._connCache[dbname]
	if cachedConnection then
		return cachedConnection
	end

	-- Search first from configurations, then from fallbacks
	local dbconfig = metso._config[dbname] or metso._fallbacks[dbname]
	assert(not not dbconfig, "attempted to get inexistent database '" .. dbname .. "'. Make sure it is properly configured in metsodb.toml")

	local conn = metso.create(dbconfig)
	metso._connCache[dbname] = conn
	return conn
end

return metso