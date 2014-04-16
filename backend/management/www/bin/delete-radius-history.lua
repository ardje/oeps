#!/usr/bin/lua

require "luasql.mysql"
local c=require("oeps.config")
local co=c.getconfig()
local dbi=luasql.mysql()
local dbh=dbi:connect(co.DBRADIUS,co.DBRADIUSUSER,co.DBRADIUSPASSWORD)
local res=dbh:execute([[
DELETE FROM radacct WHERE acctstoptime IS NOT NULL AND TIMESTAMPDIFF(day, acctstoptime,NOW())>30;
]])
row=res:fetch({},"a")
res:close()
dbh:close()
dbi:close()
