pcall(require, "mysqloo")
local Promise = include("promise.lua")

local MysqlOO = {}
MysqlOO.__index = MysqlOO

function MysqlOO:query(query)
	local promise = Promise.new()
	
	local queryObj = self.db:query(query)
	function queryObj:onSuccess(data)
		promise:resolve(data)
	end
	function queryObj:onError(err, sql)
		promise:reject(err)
	end
	queryObj:start()

	return promise
end

function MysqlOO.new(opts)
	local host, username, password, database, port, socket =
		opts.host, opts.username, opts.password, opts.database,
		opts.port, opts.socket
	local m = mysqloo.connect(host, username, password, database, port, socket)
	
	local connected, connectionMsg
	m.onConnected = function(db)
		connected = true
		connectionMsg = db
	end
	m.onConnectionFailed = function(db, err)
		connected = false
		connectionMsg = err
	end
	m:connect()
	m:wait()
	if not connected then
		error("[Metso] Connection failed: " .. tostring(connectionMsg))
	end
	return setmetatable({
		db = connectionMsg,
		username = username,
		password = password,
		database = database
	}, MysqlOO)
end

return MysqlOO