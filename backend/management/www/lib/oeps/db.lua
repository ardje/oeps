require "DBI"
oeps = oeps or {}
if oeps.config == nil
then
        local c=require "oeps.config"
        oeps.config= c.getconfig()
end
oeps.dbh=function ()
	return DBI.Connect('MySQL', oeps.config.DBNAME, oeps.config.DBUSER, oeps.config.DBPASSWORD,'127.0.0.1', '3306')
end
oeps.dbhr=function ()
	return DBI.Connect('MySQL', oeps.config.DBRADIUSNAME, oeps.config.DBRADIUSUSER, oeps.config.DBRADIUSPASSWORD,'127.0.0.1', '3306')
end
return oeps
