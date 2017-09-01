local MysqlOO = {}
MysqlOO.__index = MysqlOO

function MysqlOO.new(opts)
	return setmetatable({}, MysqlOO)
end

return MysqlOO