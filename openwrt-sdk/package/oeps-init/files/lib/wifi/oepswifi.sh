#!/bin/sh
append DRIVERS "oepswifi"

# Prevent mac80211 from destroying the wireless config
unset detect_mac80211

scan_oepswifi() {
	return
}

detect_oepswifi() {
	return
}



disable_oepswifi() (
	local device="$1"

	set_wifi_down "$device"
	# kill all running hostapd and wpa_supplicant processes that
	# are running on atheros/mac80211 vifs
	for pid in `pidof hostapd`; do
		grep -E "$phy" /proc/$pid/cmdline >/dev/null && \
			kill $pid
	done

	for phy in 0 1
	do
		[ -d /sys/class/ieee80211/phy${phy}/device/net/wlan${phy} ] &&
		iw dev "wlan$phy" del
	done
	return 0
)

enable_oepswifi() {
	local device="$1"
	iw reg set US
	if ! ip ro get 10.54.21.11 > /dev/null 
	then
		echo "backbone not reachable"
		# Kludge: we are here because we are booting. Load Fixed world regulatory
		echo 255 > /sys/class/leds/wndr3700:orange:wps/brightness
		return 0
	else
		# Kludge: we are here because we are started for operations
		# "Downgrade" world regulatory to NL
		echo 0 > /sys/class/leds/wndr3700:orange:wps/brightness
	fi
	succeeded=1
	for phy in phy0 phy1
	do	
		local i=0
		local macidx=0
		local apidx=0
		fixed=""
		local hostapd_ctrl=""

		cfgfile="/var/run/hostapd-$phy.conf"
		macaddr="$(cat /sys/class/ieee80211/$phy/macaddress)"
		BSSID1="$(mac80211_generate_mac $macidx $macaddr)";macidx="$(($macidx + 1))"
		BSSID2="$(mac80211_generate_mac $macidx $macaddr)";macidx="$(($macidx + 1))"
		BSSID3="$(mac80211_generate_mac $macidx $macaddr)";macidx="$(($macidx + 1))"
		echo $BSSID1 - $BSSID2 - $BSSID3
		provisionmac="$(cat /sys/class/ieee80211/phy0/macaddress)"
		wget -O - "http://10.54.21.11/cgi-bin/hostapd-config.cgi?mac=$provisionmac&phy=${phy/phy/}" 2> /dev/null > ${cfgfile}.raw || succeeded=0
		sed "s!@_BSSID1_@!$BSSID1!;s!@_BSSID2_@!$BSSID2!;s!@_BSSID3_@!$BSSID3!" < ${cfgfile}.raw > $cfgfile
		rm ${cfgfile}.raw
		if [ -s $cfgfile ]	
		then
			iw reg set NL
			if [ "$phy" = "phy1"  ] && [ ! -f /tmp/wifikludged ];
			then
				touch /tmp/wifikludged
				# We need some kludging to get to the max power.
				iw phy "$phy" interface add wlan${phy#phy} type managed
				iw dev wlan"${phy#phy}" set txpower limit 2000
				ip link set up dev wlan${phy#phy}	
				ip link set down dev wlan${phy#phy}	
				iw dev wlan${phy#phy} del
			fi
			iw phy "$phy" set txpower limit 2000
			iw phy "$phy" interface add wlan${phy#phy} type managed
			iw dev wlan"${phy#phy}" set txpower limit 2000
			hostapd -P /var/run/wifi-$phy.pid -B /var/run/hostapd-$phy.conf || {
				echo "Failed to start hostapd for $phy"
				succeeded=0
			}
		fi
	done
	if [ "$succeeded" -gt 0 ]
	then
		echo 255 > /sys/class/leds/wndr3700:green:wps/brightness
	else
		echo 0 > /sys/class/leds/wndr3700:green:wps/brightness
	fi
}


# External api:
# detect_<drivername>
# enable_<drivername>
