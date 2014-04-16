#!/usr/bin/lua
require "oeps.db"
local dbh=assert(oeps.dbhr())
local sth=assert(dbh:prepare[[
	DELETE FROM radacct WHERE acctstoptime IS NOT NULL AND TIMESTAMPDIFF(day, acctstoptime,NOW())>7;
]])
sth:execute()
sth:close()
dbh:close()
