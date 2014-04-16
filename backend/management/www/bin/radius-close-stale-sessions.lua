#!/usr/bin/lua
require "oeps.db"
local dbh=assert(oeps.dbhr())
-- Set stoptime on all radius sessions which haven't got for the last 30 minutes
local sth=assert(dbh:prepare[[
	update radacct set acctstoptime=TIMESTAMPADD( SECOND,acctsessiontime,acctstarttime)
	where acctstoptime is NULL and TIMESTAMPDIFF(SECOND,acctstarttime,NOW()) > acctsessiontime+1800
]])
sth:execute()
sth:close()
dbh:close()
