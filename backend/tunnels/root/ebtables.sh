#!/bin/bash
### BEGIN INIT INFO
# Provides:          ebtables
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Should-Start:      $all
# Should-Stop:       $all
# Default-Start:     S
# Default-Stop:      
# Short-Description: Start ebtables
# Description:       Start ebtables
### END INIT INFO
. /root/config
ebt() {
	/sbin/ebtables -t filter -A FORWARD --logical-in ${BRIDGE} "$@"
}
ebti() {
	/sbin/ebtables -t filter -A INPUT --logical-in ${BRIDGE} "$@"
}
ebtclear() {
	/sbin/ebtables --flush
}
enableptmp() {
	LISTA="$1";shift
	LISTB="$@"
	for grea in $LISTA
	do
		for greb in $LISTB
		do
			if ! [ "$grea" = "$greb" ]
			then	
				ebt -i gre-${grea}.2 -o gre-${greb}.2 -j ACCEPT
				ebt -o gre-${grea}.2 -i gre-${greb}.2 -j ACCEPT
			fi
		done
	done
}
enablecross() {
	LISTA="$@"
	LISTB="$@"
	for grea in $LISTA
	do
		for greb in $LISTB
		do
			if ! [ "$grea" = "$greb" ]
			then	
				ebt -i gre-${grea}.2 -o gre-${greb}.2 -j ACCEPT
			fi
		done
	done
}
#enablecross blurr brawn ratchet snarler
#exit
setuprules() {
	#eerste keer voor VLANCRYPTED
	BRIDGE=br-vlan${VLANCRYPTED}
	# Everything firewall is accepted
	for theMac in ${ALLOWEDMACS}
	do
		ebt -s ${theMac} -i vlan${VLANCRYPTED} -j ACCEPT
	done
	# Other traffic from the switch to the accesspoints: drop it!
	ebt -i vlan${VLANCRYPTED} -o gre-+ -j DROP 
	# Traffic from the DHCP server
	ebt -i v${VLANCRYPTED}-host -j ACCEPT 

	# LOG and DROP packets directed at BGA
	ebti -i gre-+ -d 01:80:c2:00:00:00 --log --log-prefix "BGA: " -j DROP
	ebt -i gre-+ -d 01:80:c2:00:00:00 -j DROP

	# Specific interapp traffic allowed
	#enableptmp blurr brawn ratchet snarler
	# Wireless <-> TV @ frank volmer
	enablecross hardtop rodimus
	# Inter AP traffic DROP
	ebt -i gre-+ -o gre-+ -j DROP 

	# Generic traffic to DHCP and such allowed
	ebt -i vlan${VLANCRYPTED} -j ACCEPT 

	#nu voor ${VLANUNENCRYPTED}
	BRIDGE=br-vlan${VLANUNENCRYPTED}
	# Everything firewall is accepted
	for theMac in 0:11:43:e1:99:36 0:11:43:e1:99:37 0:11:43:e2:1:2e 0:0:5e:0:1:16
	do
		ebt -s ${theMac} -i vlan${VLANUNENCRYPTED} -j ACCEPT
	done
	# Other traffic from the switch to the accesspoints: drop it!
	ebt -i vlan${VLANUNENCRYPTED} -o gre-+ -j DROP 
	# Traffic from the DHCP server
	ebt -i v${VLANUNENCRYPTED}-host -j ACCEPT 
	# LOG and DROP packets directed at BGA
	#ebt -i gre-+ -d 01:80:c2:00:00:00 -j LOG
	ebti -i gre-+ -d 01:80:c2:00:00:00 --log --log-prefix "BGA: " -j DROP
	ebt -i gre-+ -d 01:80:c2:00:00:00 -j DROP
	#ebt -i gre-+ -d 01:80:c2:00:00:00 -j DROP

	# Specific interapp traffic allowed
	#enableptmp blurr brawn ratchet snarler
	# Wireless <-> TV @ frank volmer
	#enablecross hardtop cyclonus
	# Inter AP traffic DROP
	ebt -i gre-+ -o gre-+ -j DROP 

	# Generic traffic to DHCP and such allowed
	ebt -i vlan${VLANUNENCRYPTED} -j ACCEPT 
}

case "$1" in
  start)
	ebtclear
	setuprules
	/etc/init.d/ebtables save
	;;
  *)
	;;
esac
