-- Run this from addons/metso

-- TODO fetch these automatically
local sourceFiles = {
	"back_mysqloo.lua",
	"back_sqlite.lua",
	"connection.lua",
	"metso.lua",
	"promise.lua",
	"toml.lua",
}
local main = "metso.lua"

local package = {}

-- read source files
for _,srcmod in pairs(sourceFiles) do
	local srcpath = "lua/metso/" .. srcmod

	local f = io.open(srcpath, "rb")
	local code = f:read("*a")
	f:close()

	local deps = {}
	for dep in string.gmatch(code, "include%(\"([^\"]*)\"%)") do
		table.insert(deps, dep)

		print("Module ", srcmod, " has dependency on ", dep)
	end

	package[srcmod] = {code = code, deps = deps}
end

local outcode = {}
table.insert(outcode, [[
local __L_mods = {}
local function __L_define(name, init)
	__L_mods[name] = init
end
local function __L_load(name)
	return __L_mods[name]()
end
]])
for path,mod in pairs(package) do
	table.insert(outcode, "__L_define(\"" .. path .. "\", function()\n")

	local code = mod.code
	code = string.gsub(code, "\r\n", "\n")
	code = string.gsub(code, "include%(\"([^\"]*)\"%)", "__L_load(\"%1\")")
	table.insert(outcode, code)

	table.insert(outcode, " end)")
end

table.insert(outcode, "return __L_load(\"" .. main .. "\")")

local nf, e = io.open("metso.lua", "w")
nf:write(table.concat(outcode, ""))
nf:close()

print("Wrote metso.lua")