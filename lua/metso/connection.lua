local Connection = {}
Connection.__index = Connection

--- Escapes string so that it can be added into a SQL query without problems.
--- This method MUST ALWAYS add quotations around the string.
function Connection:_escapeString(str)
	-- TODO per-backend
	return sql.SQLStr(str)
end

--- Parses given SQL. In practice this consists of
--- 1. Replacing placeholders with values from params
--- 2. Escaping objects that need escaping in parameters
--- 3. Failing if met with unknown types (fail fast!)
function Connection:_parseQuery(sql, params)
	local i = 1
	return sql:gsub("%?", function()
		local param = params[i]

		i = i + 1

		if type(param) == "string" then
			return self:_escapeString(param)
		elseif type(param) == "number" then
			return tostring(param)
		elseif param == nil then
			return "NULL"
		else
			error("unknown type given to sql query: " .. type(param))
		end
	end)
end

--- Submits a query in non-blocking manner.
--- Returns a promise that contains the rows
function Connection:query(sql, params)
	assert(type(sql) == "string", "query sql must be a string")

	params = params or {}
	assert(type(params) == "table", "query params must be a table")

	local finalSql = self:_parseQuery(sql, params)

	return self._backend:query(finalSql)
end

function Connection:queryRow(sql, params)
	return self:query(sql, params):next(function(res)
		return res[1]
	end)
end
function Connection:queryValue(sql, params)
    return self:queryRow(sql, params):next(function(row)
        if not row then
            return nil
        end
        
        local firstKey = next(row)
        if firstKey then
            return row[firstKey]
        end
    end)
end

--- Equal to conn:query(), except the promise has the inserted ID
--- as the value
function Connection:insert(sql, params)
	return self:query(sql, params):next(function()
		return self._backend:queryLastInsertedId()
	end)
end

function Connection.new(backend)
	assert(not not backend, "backend required")
	return setmetatable({_backend = backend}, Connection)
end
return Connection
