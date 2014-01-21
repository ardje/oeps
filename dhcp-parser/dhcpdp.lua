local m={}

--[[
use:
create a dhcp parser struct
poll -> check leases file for changes
lookups -> query current structs
close -> stop it.
]]
function m.new(filename,time)
	local parser={}
	parser.filename=filename
	parser.time=time or os.time
	parser.ip={} -- ip -> lease
	parser.mac={} -- mac -> ip
	setmetatable(parser,{ __index=m })
	local err
	parser.f, err=io.open(filename,"rb")
	parser.offset=0
	if parser.f ~= nil then
		return parser
	else
		return nil,err
	end
		
end
--[[
function m:printlease(lease)
	(lease.ip,lease.mac,lease.state)
end
-- ]]
function m:poll()
	self.f:seek("set",self.offset);
	while 1==1 do
		self.offset=self.f:seek();
		line= self.f:read("*l")
		if line==nil then break end
		if line:match("^#")
		then
			print("comment:",line)
			goto nextlease
		end
		local ip=line:match("lease (%d+%.%d+%.%d+%.%d+) {")
		if ip ~= nil
		then
			local lease,mac,state={}
			lease.ip=ip
			while 1==1 do
				local mac,state
				line=self.f:read("*l")
				if line==nil then print "EOF" break end
				if line:match("^}$") ~= nil then break end
				mac=line:match("^  hardware ethernet ([a-z0-9:]+);")
				if mac
				then
					lease.mac=mac
					goto nextleaseline
				end
				state=line:match("^  binding state ([a-z]+);")
				if state
				then
					lease.state=state
					goto nextleaseline
				end
				ends=line:match("^  ends (never);")
				if ends
				then
					-- BOOTP lease. You don't want that
					lease.ends=ends
					goto nextleaseline
				end
				year,month,day,hour,minute,sec=line:match("^  ends %d (%d%d%d%d)/(%d%d)/(%d%d) (%d%d):(%d%d):(%d%d);")
				if year and month and day and hour and minute and sec
				then
					-- Normal ends
					lease.ends=os.time{year=year,month=month,day=day,hour=hour,minute=minute,sec=sec}
					if lease.ends < self.time()
					then
						-- expired leases, skip check
						-- print ("expired lease", lease.ends,self.time())
						--print ("lease", year,month,day,hour,minute,sec)
						lease.ends=nil
					end
					--print ("lease ends:",lease.ends)
					goto nextleaseline
				end
				::nextleaseline::
			end
			if lease.ip and lease.mac and lease.state and lease.ends
			then
				local byip,bymac
				byip=self:lookupbyip(lease.ip)
				bymac=self:lookupbymac(lease.mac)
				if byip and bymac and bymac[lease.ip]==1
				then
					print ("Updating existing lease",lease.ip,lease.mac,lease.state)
					if byip.state ~= lease.state
					then
						if lease.state=="active"
						then
							-- perform callbacks here
							print("starting lease:",lease.ip,lease.mac,lease.state)
						else
							-- perform callbacks here
							print("ending lease:",lease.ip,lease.mac,lease.state)
						end
					end
				elseif byip == nil and bymac == nil
				then
					if lease.state=="active"
					then
						-- perform callbacks here
						print("starting lease:",lease.ip,lease.mac,lease.state)
					end
				elseif bymac
				then
					-- Mac get's a second or third ip
					-- By spec a mac can have multiple ip addresses assigned
					-- We don't want that, but we have to cope with it :-(
					print "Mac already got an ip assigned"
					print("New lease:",lease.ip,lease.mac,lease.state)
					for k,v in pairs(bymac) do
						print("ip: ",k)
					end
				elseif byip and bymac==nil
				then
					print "IP handed out to other mac"
				end
				::leasecallbacksdone::
				self:updatelease(lease)
			end
		end
		::nextlease::
	end	
end

function m:lookupbyip(ip)
	return self.ip[ip]
end
function m:checkmacip(mac,ip)
	return self.mac[mac] and self.mac[mac][ip]
end
function m:lookupbymac(mac)
	local ip=self.mac[mac]
	return ip
end
function m:updatelease(lease)
	local ip=lease.ip
	local olease=self.ip[ip]
	if olease ~= nil
	then
		if olease.mac ~= lease.mac
		then
			-- Remove old mac entry
			self.mac[olease.mac][ip]=nil
		end
		for k,v in pairs(lease)	do
			olease[k]=v
		end
	else
		self.ip[ip]=lease
	end
	if self.mac[lease.mac]
	then
		self.mac[lease.mac][ip]=1
	else
		self.mac[lease.mac]={ [ip]=1 }
	end
end
function m:close()
	parser.offset=0
	return self.f:close()
end

return m
