pcall(require, "mysqloo")
if not mysqloo then return end

local Promise = include("promise.lua")

local MysqlOO = {}
MysqlOO.__index = MysqlOO

function MysqlOO:query(query)
	local promise = Promise.new()
	
	local queryObj = self.db:query(query)
	function queryObj:onSuccess(data)
		self.lastInsertID = queryObj:lastInsert()
		self.lastAffectedRows = queryObj:affectedRows()
		
		promise:resolve(data)
	end
	function queryObj:onError(err, sql)
		promise:reject(err)
	end
	queryObj:start()

	return promise
end

function MysqlOO:queryLastInsertedId()
	return self.lastInsertID
end

function MysqlOO.new(opts)
	
	local host, username, password, database, port, socket =
		opts.host, opts.username, opts.password, opts.database,
		opts.port, opts.socket
	
	if not host then error("Error: host must be specified when using MysqlOO as the driver") end
	if not username then error("Error: username must be specified when using MysqlOO as the driver") end
	if not password then error("Error: password must be specified when using MysqlOO as the driver") end
		
	local db = mysqloo.connect(host, username, password, database, port, socket)
	
	local connected, connectionMsg
	db.onConnected = function(db)
		connected = true
		connectionMsg = db
	end
	db.onConnectionFailed = function(db, err)
		connected = false
		connectionMsg = err
	end
	db:connect()
	db:wait()
	if not connected then
		error("[Metso] Connection failed: " .. tostring(connectionMsg))
	end
	
	db:query("SET NAMES utf8mb4")
	
	return setmetatable({
		db = db,
		username = username,
		password = password,
		database = database
	}, MysqlOO)
end

return MysqlOO