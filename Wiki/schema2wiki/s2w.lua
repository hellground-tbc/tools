--------------------------------------------------------------------------------
-- schema2wiki by Siarkowy, 2014
-- Released under the terms of GNU GPL v3 license.
--------------------------------------------------------------------------------
-- Description:
--   This script will create files named `database.table.txt` in working directory,
--   each of which containing SQL schema information of a table in Wikimarkup.
--
-- Usage:
--   s2w <db_user> <db_pass> <core_revision> <database> [<database2> ...]
--
-- Example:
--   lua s2w.lua root pass 9999 characters realm world      -- interpreted
--   s2w root pass 9999 characters realm world              -- compiled
--------------------------------------------------------------------------------

require "luasql.mysql"

local user, pass, rev = ...     -- program args
local output = "%s.%s.txt"      -- output file name (db, table)

--- Executes specified SQL statement and returns an iterator on results.
-- This function comes from: http://keplerproject.org/luasql/examples.html
-- @param connection (userdata) Database connection.
-- @param sql_statement (string) SQL statement to execute.
-- @return function - Iterator on results.
function rows(connection, sql_statement)
    local cursor = assert(connection:execute(sql_statement))
    return function()
        return cursor:fetch()
    end
end

-- If less than 4 arguments, show usage and exit.
if select("#", ...) < 4 then
    print[[schema2wiki
    SQL table schema to Wikimarkup converter by Siarkowy, 2014
    This script will create files named `database.table.txt` in this directory,
    each of which containing SQL schema information of a table in Wikimarkup.

Usage:
    s2w <db_user> <db_pass> <core_revision> <database> [<database2> ...]

Example:
    s2w root pass 9999 characters realm world]]

    return
end

rev = tonumber(rev)

-- For every database name in arg list
for i = 4, select("#", ...) do
    local db = select(i, ...)
    local con = assert(luasql.mysql():connect(db, user, pass))

    for tbl in rows(con, ([[SELECT `table_name`
        FROM `information_schema`.`tables`
        WHERE `table_schema` = %q]]):format(db)) do
        local f = assert(io.open(string.format(output, db, tbl), "w"))

        f:write(("{| class=\"wikitable\"\n|+ `%s` table rev. %s\n" ..
            "! Field !! Type !! Null !! Key !! Default !! Extra\n"):format(tbl, rev))

        for field, type, null, key, def, extra
            in rows(con, ("SHOW COLUMNS FROM `%s`.`%s`"):format(db, tbl)) do

            local line = ("|-\n|[[#%s|%s]] || %s || %s || %s || %s || %s\n")
                :format(field, field, type, key, null, def or "", extra):gsub("% % ", " ") 

            f:write(line)
        end

        f:write("|}\n")
        f:close()
    end
end
