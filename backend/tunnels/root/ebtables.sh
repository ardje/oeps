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
	#eerste keer voor 2928
	BRIDGE=br-vlan2928
	# Everything firewall is accepted
	for theMac in 0:11:43:e1:99:36 0:11:43:e1:99:37 0:11:43:e2:1:2e 0:0:5e:0:1:16
	do
		ebt -s ${theMac} -i vlan2928 -j ACCEPT
	done
	# Other traffic from the switch to the accesspoints: drop it!
	ebt -i vlan2928 -o gre-+ -j DROP 
	# Traffic from the DHCP server
	ebt -i v2928-host -j ACCEPT 

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
	ebt -i vlan2928 -j ACCEPT 

	#nu voor 2929
	BRIDGE=br-vlan2929
	# Everything firewall is accepted
	for theMac in 0:11:43:e1:99:36 0:11:43:e1:99:37 0:11:43:e2:1:2e 0:0:5e:0:1:16
	do
		ebt -s ${theMac} -i vlan2929 -j ACCEPT
	done
	# Other traffic from the switch to the accesspoints: drop it!
	ebt -i vlan2929 -o gre-+ -j DROP 
	# Traffic from the DHCP server
	ebt -i v2929-host -j ACCEPT 
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
	ebt -i vlan2929 -j ACCEPT 
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
