#!/usr/bin/lua
require "oeps.db"
local dbh=assert(oeps.dbh())
local sth=assert(dbh:prepare[[
	select name,state from ap where state != "UP" and adminstate = "PRODUCTION" and TIMESTAMPDIFF(DAY,lastcontact,NOW())<7
]])

sth:execute()

local exitcode=0
local status="OK"
local message=""
for row in sth:rows(true) do
	exitcode=1 -- just let it warn on accesspoints that are down
	message=message .. " " .. row.name .. ":" ..row.state
	status="CRITICAL:"
	row=res:fetch({},"a")
end
sth:close()
dbh:close()
io.write(status, message,"\n")
os.exit(exitcode)
