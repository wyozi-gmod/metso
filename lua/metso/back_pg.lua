pcall(require, "pg")
if not pg then return end

local Promise = include("promise.lua")

local Postgres = {}
Postgres.__index = Postgres

function Postgres:query(query)
	local promise = Promise.new()
	
	local queryObj = self.db:query(query)
	queryObj:on("success", function(data, size)
		-- self.lastInsertID = ??? TODO
		self.lastAffectedRows = size
		
		promise:resolve(data)
	end)
	queryObj:on("error", function(err)
		promise:reject(err)
	end)
	queryObj:run()

	return promise
end

function Postgres:queryLastInsertedId()
	return self.lastInsertID
end

function Postgres.new(opts)
	
	local host, username, password, database, port =
		opts.host, opts.username, opts.password, opts.database,
		opts.port
	
	if not host then error("Error: host must be specified when using Postgres as the driver") end
	if not username then error("Error: username must be specified when using Postgres as the driver") end
	if not password then error("Error: password must be specified when using Postgres as the driver") end
		
    local db = pg.new_connection()
    local status, err = db:connect(host, username, password, database, port)

    if not status then
        error("[Metso] Connection failed: " .. tostring(err))
    end
	
	return setmetatable({
		db = db,
		username = username,
		password = password,
		database = database
	}, Postgres)
end

return Postgres