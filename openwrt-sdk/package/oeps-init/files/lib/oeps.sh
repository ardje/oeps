oepsGetID() {
	local OEPSID
	OEPSID="$(uci -q get oeps.provision.oepsid)"
	if [ -z "$OEPSID" ]
	then
		OEPSID="$(ip li show dev eth0|
				awk 'BEGIN { a['0']='0';a['2']='0';a['4']='4';a['6']='4';a['8']='8';a['a']='8';a['c']='c';a['e']='c'; }
				/ether/ { print substr($2,1,1) a[substr($2,2,1)] substr($2,3) }'
			)"
	fi
	echo $OEPSID
}

oepsGetVersion() {
	local VERSION
	VERSION="$(opkg list_installed|awk '/^oeps-init/ { print $3 }')"
	echo $VERSION
}

