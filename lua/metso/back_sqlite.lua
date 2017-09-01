local Promise = include("promise.lua")

local SQLite = {}
SQLite.__index = SQLite

function SQLite:query(query)
	local data = sql.Query(query)
	local promise = Promise.new()

	if data == false then -- error!
		local err = sql.LastError()
		promise:reject(err)
	elseif data == nil then -- no data
		promise:resolve({})
	else
		promise:resolve(data)
	end

	return promise
end

function SQLite:queryLastInsertedId()
	return tonumber(sql.Query("SELECT last_insert_rowid() id")[1].id)
end

function SQLite.new(opts)
	local username, password, database = opts.username, opts.password, opts.database
	if username or password or database then
		ErrorNoHalt("Warning: username/password/database specified when using sqlite as the driver")
	end
	return setmetatable({}, SQLite)
end

return SQLite