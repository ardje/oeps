#!/usr/bin/perl
use CGI qw/:standard/;
#use CGI::SpeedyCGI;
use Data::Dumper;
use DBI;

# backend config stuff
my $radius_acct_host='10,10.10.10';
my $radius_acct_pass='abcdefgh';
my $radius_acct_interval=555;
my $dsn="DBI:mysql:database=ap:host=localhost:port=";
my $dsu="dbuser";
my $dsp="dbpasssword";

my $dbh=DBI->connect($dsn,$dsu,$dsp) || die "Could not connect to DB";
my $sthmac=$dbh->prepare("SELECT * FROM ap WHERE mac=?");
my $sthname=$dbh->prepare("SELECT * FROM ap WHERE mac=?");
my $sthphy=$dbh->prepare("SELECT * FROM apwifi WHERE mac=? and phy=?");
my $sthnewphy=$dbh->prepare("INSERT INTO apwifi (mac,phy,channel,class) values(?,?,?,?)");
#my $sthnew=$dbh->prepare("REPLACE into ap (mac, name, state, adminstate, wan_ip, lastcontact) VALUES(?,?,?,'NEW',?,NOW())");
#my $sthupdate=$dbh->prepare("UPDATE ap set wan_ip=?, state=?, lastcontact=NOW() where mac=?");

main();
sub main {
	my $cgi= new CGI();
	print(header("text/plain"));
	my $mac=$cgi->param('mac');
	my $phy=$cgi->param('phy');
	if ($mac !~ m/^([0-9a-f][0-9a-f]:){5}[0-9a-f][0-9a-f]$/  || $phy !~ m/^[01]$/ ) {
		print "MEUH?";
		die("wrong params");
		exit 0;
	}
	$mac =~ s/^(.)2/${1}0/g;
	my ($class,$channel);
	$sthphy->execute($mac,$phy);
	while (my $ref = $sthphy->fetchrow_hashref()) {
		$class = $ref->{'class'};
		$channel = $ref->{'channel'};
	}
	$sthphy->finish();
	# print "class : $class\n";
	if($class eq '') {
		$sthmac->execute($mac);
		while (my $ref = $sthmac->fetchrow_hashref()) {
			$class = $ref->{'class'};
		}
		$sthmac->finish();
		# print " getting new class : $class\n";
		if($class eq '') {
			die("cannot find AP");
		}
		if($phy == 0) {
			$channel=1+int(rand(13));
		}
		if(1 == $phy) {
			$channel=36+4*int(rand(4));
		}
		$sthnewphy->execute($mac,$phy,$channel,$class);
		$sthnewphy->fetchrow_hashref();
		$sthnewphy->finish();
		# print "created new phy\n";
	}
	# channel 0 -> no wifi configured
	if($channel > 0 ) {
		for ($class) {
# classes
			m/noisolation/ && do {
				prologue($mac,$phy,$channel);
				noisolation($mac,$phy,$channel);
				last;
			};
			m/experiment1/ && do {
				prologue($mac,$phy,$channel);
				example_wifi($mac,$phy,$channel);
				last;
			};
			m/w3c/ && do {
				prologue($mac,$phy,$channel);
				w3cwifi($mac,$phy,$channel);
				last;
			};
			# Default..
			prologue($mac,$phy,$channel);
			example_wifi($mac,$phy,$channel);
			last;
		}
	}
}

# Generic hostapd config stuff
sub prologue {
	my ($mac,$phy,$channel)=@_;
print "
ctrl_interface=/var/run/hostapd-phy$phy
driver=nl80211
wmm_ac_bk_cwmin=4
wmm_ac_bk_cwmax=10
wmm_ac_bk_aifs=7
wmm_ac_bk_txop_limit=0
wmm_ac_bk_acm=0
wmm_ac_be_aifs=3
wmm_ac_be_cwmin=4
wmm_ac_be_cwmax=10
wmm_ac_be_txop_limit=0
wmm_ac_be_acm=0
wmm_ac_vi_aifs=2
wmm_ac_vi_cwmin=3
wmm_ac_vi_cwmax=4
wmm_ac_vi_txop_limit=94
wmm_ac_vi_acm=0
wmm_ac_vo_aifs=2
wmm_ac_vo_cwmin=2
wmm_ac_vo_cwmax=3
wmm_ac_vo_txop_limit=47
wmm_ac_vo_acm=0
tx_queue_data3_aifs=7
tx_queue_data3_cwmin=15
tx_queue_data3_cwmax=1023
tx_queue_data3_burst=0
tx_queue_data2_aifs=3
tx_queue_data2_cwmin=15
tx_queue_data2_cwmax=63
tx_queue_data2_burst=0
tx_queue_data1_aifs=1
tx_queue_data1_cwmin=7
tx_queue_data1_cwmax=15
tx_queue_data1_burst=3.0
tx_queue_data0_aifs=1
tx_queue_data0_cwmin=3
tx_queue_data0_cwmax=7
tx_queue_data0_burst=1.5
channel=$channel
country_code=NL
logger_syslog=127
logger_syslog_level=2
logger_stdout=127
logger_stdout_level=2
ieee80211n=1
ht_capab=[SHORT-GI-40][TX-STBC][RX-STBC1][DSSS_CCK-40]
#ht_capab=[SHORT-GI-20][TX-STBC][RX-STBC1]
ieee80211d=1
ctrl_interface=/var/run/hostapd-phy$phy
";
	print "hw_mode=g\n" if(!$phy);
	print "hw_mode=a\n" if($phy);
}

sub radius {
	my ($mac,$phy,$channel)=@_;
print "
acct_server_addr=$radius_acct_host
acct_server_shared_secret=$radius_acct_password
radius_acct_interim_interval=$radius_acct_interval
";
}

# Sample config with isolation disabled
sub noisolation {
	my ($mac,$phy,$channel)=@_;
print "
interface=wlan$phy
ap_isolate=0
wpa_passphrase=verysecure
auth_algs=1
wpa=2
wpa_pairwise=CCMP
ssid=MySecureSSIDNoIso
bridge=br-swifi
wmm_enabled=1
bssid=\@_BSSID1_\@
ignore_broadcast_ssid=0
";
	radius($mac,$phy,$channel);
print "
bss=wlan$phy-1
ctrl_interface=/var/run/hostapd-phy$phy
ap_isolate=0
acct_server_addr=$radius_acct_server
acct_server_shared_secret=$radius_acct_password
auth_algs=1
wpa=0
ssid=MyPublicSSID
bridge=br-wifi
wmm_enabled=1
bssid=\@_BSSID2_\@
ignore_broadcast_ssid=0
";
	radius($mac,$phy,$channel);
}


# Another example
sub example_wifi {
	my ($mac,$phy,$channel)=@_;
print "
interface=wlan$phy
ap_isolate=1
wpa_passphrase=verysecret
auth_algs=1
wpa=2
wpa_pairwise=CCMP
ssid=MyEncryptedSSID
bridge=br-swifi
wmm_enabled=1
bssid=\@_BSSID1_\@
ignore_broadcast_ssid=0
";
	radius($mac,$phy,$channel);
print "
bss=wlan$phy-1
ctrl_interface=/var/run/hostapd-phy$phy
ap_isolate=1
acct_server_addr=$radius_acct_server
acct_server_shared_secret=$radius_acct_password
auth_algs=1
wpa=0
ssid=TMG-gastgebruik
bridge=br-wifi
wmm_enabled=1
bssid=\@_BSSID2_\@
ignore_broadcast_ssid=0
";
	radius($mac,$phy,$channel);
}

# This config was actually used at a W3C meeting @amsterdam The W3C members
# were actually surprised at how good it works...
sub w3cwifi {
	my ($mac,$phy,$channel)=@_;
print "
interface=wlan$phy
ap_isolate=1
wpa_passphrase=cookiemonster
auth_algs=1
wpa=2
wpa_pairwise=CCMP
ssid=W3C
bridge=br-swifi
wmm_enabled=1
bssid=\@_BSSID1_\@
ignore_broadcast_ssid=0
";
	radius($mac,$phy,$channel);
}
