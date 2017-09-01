## metso

Omni-database abstraction library for Garry's Mod.

### Features
- Easily embeddable. A one-file .lua file is enough for all metso features.
- Comes with built-in support for SQLite and MySQLOO.
- The preferred way of configuring metso is via `metsodb.toml` in garrysmod folder. This allows re-using database configuration between scripts.

### Installation
Copy `metso.lua` from root of this repository to a folder in your addon. Call `local metso = include("metso.lua")` somewhere in serverside code.
Metso should only be included once (or weird things may happen), so you might want to assign return value from `include("metso.lua")` to some variable eg. `myaddon.metso = include("metso.lua")`.

### Usage

#### Connection (preferred way)

Create a `metsodb.toml` file in your `garrysmod/` folder. (Why [TOML](https://github.com/toml-lang/toml) instead of JSON? Better error messages, cleaner configuration file)

Here's an example config file that contains two databases:

```toml
[darkrp]
driver = "mysqloo"
username = "mike"
password = "m1k3sdb"
database = "darkrpstuff"

[poker]
driver = "sqlite"
```

Now that the config is created you can use the databases ingame:
```lua
local metso = include("metso.lua")

local db = metso.get("darkrp")
db:query("SELECT * FROM players")

local db2 = metso.get("poker")
db2:query("INSERT INTO chips (ply, amount) VALUES (?, ?)", {"Mike", 1923})
```

If you use the `metsodb.toml` way of declaring databases the connections are automatically handled for you.
Namely, it is safe to call `metso.get` multiple times as the same connection is always returned.

It is very possible that you want to provide a fallback in case specific database configuration does not exist.
You can call `metso.provideFallback(name, opts)` to provide a fallback options table in case a named database config is not found.
Please note that this might cause hard to find bugs to happen if user typos the database name, and is wondering why is
the script not connecting to the correct database.

This way of configuration allows different scripts (if they both use metso) to share database configuration without
each script having to have its own configuration file.

#### Raw connection

If you wish you can also create connections directly.

```lua
local db = metso.create {
	driver = "mysqloo",
	username = "xx",
	password = "yy",
	database = "zz"
}
```

Syntax within the table is identical to the one in TOML databases.

#### Queries

All asynchronous methods return [promises](https://www.promisejs.org/).
The base Lua implementation currently used is [https://github.com/Billiam/promise.lua](https://github.com/Billiam/promise.lua).
The implementation used in metso includes additional `Promise:done()` method.

```lua
local db = ...

db:query("SELECT * FROM users"):next(function(users)
	PrintTable(users)
end, function(reason)
	print("Failed to get users because ", reason)
end)

-- You can use :done() to automatically throw errors on failure
db:query("SELECT age FROM uses"):done(function(users)
	PrintTable(users)
end)

-- String templating
db:query("SELECT * FROM users WHERE name = ?", {"Mike"}):done(function(mikes)
	PrintTable(mikes)
end)
```