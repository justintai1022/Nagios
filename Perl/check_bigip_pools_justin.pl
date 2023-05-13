#!/usr/bin/perl
#	  __  _              _    
#	 / /_(_)_ _  ___    (_)__ 
#	/ __/ /  ' \/ _ \_ / / _ \
#	\__/_/_/_/_/\___(_)_/_//_/
#	
#	Description: 
#	Nagios-Check to monitor for pool member status and availability on Big IP appliances.
#	Tested on Big IP LTM (11.1)
#	
#	Version: 1.0
#	Date: 07-10-2013
#	
#	Author: Timo Schlueter
#	
#	Mail: nagios@timo.in
#	Twitter: twitter.com/tmuuh
#	ICQ: 108585887
#
#
# 	Licence : GNU General Public Licence (GPL) http://www.gnu.org/
# 	This program is free software; you can redistribute it and/or
# 	modify it under the terms of the GNU General Public License
# 	as published by the Free Software Foundation; either version 2
# 	of the License, or (at your option) any later version.
#
# 	This program is distributed in the hope that it will be useful,
# 	but WITHOUT ANY WARRANTY; without even the implied warranty of
# 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 	GNU General Public License for more details.
#
# 	You should have received a copy of the GNU General Public License
# 	along with this program; if not, write to the Free Software
# 	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 	02110-1301, USA.
#
######################################################################################
#	Modify author : Justin Tai                                                                                                                                                       #
#	Modify date : 20230118                                                                                                                                                         #
#	Version : 1.1                                                                                                                                                                             #
######################################################################################
#	Version1.1 :  Added to determine whether the pool name is consistent to insert the oid value into the variable
#
######################################################################################

# Modules
use Getopt::Long qw(:config no_ignore_case);;
use Net::SNMP;

# Environment
my $scriptName = "check_bigip_pools.pl";
my $activeMembers;
my $availableMembers;
my $poolStatus;

# Default Settings
my $snmpPort = 161;
my $snmpVersion = 2;
my $warningLimit = 1;
my $criticalLimit = 0;

# OIDs
my $activeMemberCountOid = "1.3.6.1.4.1.3375.2.2.5.1.2.1.8";
my $availableMemberCountOid = "1.3.6.1.4.1.3375.2.2.5.1.2.1.23";
my $poolAvailabilityCountOid = "1.3.6.1.4.1.3375.2.2.5.5.2.1.2";

sub show_help() {
        print "\n$scriptName plugin for Nagios to monitor the Pool-Status on Big-IP Appliances via SNMP\n";
        print "\nUsage:\n";
        print "   -H (--hostname)      IP or Hostname of the Big-IP\n";
        print "   -p (--poolname)      Name of the Pool\n";
        print "   -C (--community)     SNMP community (default is public)\n";
        print "\nOptional:\n";
        print "   -w (--warning)       Threshold for warning limit\n";
        print "   -c (--critical)      Threshold for critical limit\n";
        print "   -v (--snmpversion)   SNMP version 1 or 2 (default is 2)\n";
        print "   -p (--snmpport)      SNMP port (default is 161)\n";
        print "   -h (--help)          Show this message\n\n";
        print "Copyright (C) 2013 Timo Schlueter (nagios\@timo.in)\n";
        print "$scriptName comes with ABSOLUTELY NO WARRANTY\n";
}

sub main() {
	my $parameters = GetOptions(
		'hostname|H=s' => \$host,
		'poolname|P=s' => \$poolName,
		'community|C=s' => \$community,
		'snmpversion|v=i' => \$snmpVersion,
		'snmpport|p=i' => \$snmpPort,
		'warning|w=i' => \$warningLimit,
		'critical|c=i' => \$criticalLimit,
		'help|h' => \$help
	);

	if ($parameters == 0 || $help){
		show_help;
		exit 3;
	} else {
		if (!$host || !$poolName || !$community) {
			show_help;
		} else {
			$poolOid = $poolName;
			#print "pooloid1: $poolOid\n";
			$poolOid =~ s/(.)/sprintf('.%u', ord($1))/eg;
			#print "pooloid2: $poolOid\n";
			$session = Net::SNMP->session(
				-hostname => $host, 
				-port => $snmpPort, 
				-version => $snmpVersion,
				-community => $community,
				-timeout => 10
			);
			if (!defined($session)) {
				print "Can't connect to Host (" . $host . "). SNMP related problem.";
				exit 3;
			} else {
				$activeMemberList = $session->get_table($activeMemberCountOid);
				$availableMemberList = $session->get_table($availableMemberCountOid);
				$poolStatusList = $session->get_table($poolAvailabilityCountOid);

				if (!defined($activeMemberList) || !defined($availableMemberList) || !defined($poolStatusList)) {
					print "Can't get status information. SNMP related problem.";
					exit 3;
				} else {
					my $error = 1;
					foreach my $key (keys %$activeMemberList) {
						#print "key : $key\n"; #for debug
						$activeOid = $key; #Justin_20230117
						my @activeOid = split('\.', $activeOid); #Justin_20230117：用點來切割字元並放到陣列中
						for(my $i =23; $i < scalar(@activeOid); $i++){ #Justin_20230117：從陣列[23]的字元開始抓取到最後並將點加回去並放到變數中
							$activeResult .= "\.$activeOid[$i]"; #Justin_20230117：#所有的字串用append的方式添加到變數中
						}
						#print "test : $activeResult\n"; #for debug
						$activeMember = $activeResult; #Justin_20230117
						$activeResult =(); #Justin_20230117
						if (index($key, $poolOid) ne -1) {
							if ($poolOid =~ $activeMember){ #Justin_20230117：比對OID是否一致，一致才是同一個Pool_Name並把OID裡面存放的值放到activeMembers變數中
								$activeMembers = $activeMemberList->{$key};
								#print "activeMembers : $activeMembers\n";
								$error = 0;
							}
						}
					}
					
					foreach my $key (keys %$availableMemberList) {
                                                #print "key2 : $key\n"; #for debug
                                                $availableOid = $key; #Justin_20230117
                                                my @availableOid = split('\.', $availableOid); #Justin_20230117：用點來切割字元並放到陣列中
                                                for(my $i =23; $i < scalar(@availableOid); $i++){ #Justin_20230117：從陣列[23]的字元開始抓取到最後並將點加回去並放到變數中
                                                        $availableResult .= "\.$availableOid[$i]"; #Justin_20230117：#所有的字串用append的方式添加到變數中
                                                }
                                                #print "test : $availableResult\n"; #for debug
                                                $availableMember = $availableResult; #Justin_20230117
                                                $availableResult =(); #Justin_20230117
                                                if (index($key, $poolOid) ne -1) {
                                                        if ($poolOid =~ $availableMember){ #Justin_20230117：比對OID是否一致，一致才是同一個Pool_Name並把OID裡面存放的值放到availableMembers變數中
                                                                $availableMembers = $availableMemberList->{$key};
                                                                #print "availableMembers  : $availableMembers \n"; #for debug
                                                                $error = 0;
                                                        }
                                                }
                                        }					

					foreach my $key (keys %$poolStatusList) {
                                                #print "key3 : $key\n"; #for debug
                                                $statusOid = $key; #Justin_20230117
                                                my @statusOid = split('\.', $statusOid); #Justin_20230117：用點來切割字元並放到陣列中
                                                for(my $i =23; $i < scalar(@statusOid); $i++){ #Justin_20230117：從陣列[23]的字元開始抓取到最後並將點加回去並放到變數中
                                                        $statusResult .= "\.$statusOid[$i]"; #Justin_20230117：#所有的字串用append的方式添加到變數中
                                                }
                                                #print "test : $statusResult\n"; #for debug
                                                $status = $statusResult; #Justin_20230117
                                                $statusResult =(); #Justin_20230117
                                                if (index($key, $poolOid) ne -1) {
                                                        if ($poolOid =~ $status){ #Justin_20230117：比對OID是否一致，一致才是同一個Pool_Name並把OID裡面存放的值放到poolStatus變數中
                                                                $poolStatus = $poolStatusList->{$key};
								#print "poolStatus : $poolStatus\n"; #for debug
                                                                $error = 0;
                                                        }
                                                }
                                        }

					if ($error eq 1) {
						print "Can't find information for specified pool (" . $poolName . "). Please check poolname.";
						exit 3;
					} else {
						if ($poolStatus eq 1) {
							$poolStatus = "available";
						} else {
							$poolStatus = "unknown";
						}

						if ($criticalLimit gt $warningLimit) {
							print "Critical value can't be higher than warning value.";
							exit 3;
						} else {
							my $outputString = " - Pool: " . $poolName . " / Status: ".  $poolStatus . " / Members active: " . $activeMembers . " out of " . "$availableMembers\n";
							if ($activeMembers eq $availableMembers) {
								print "OK" . $outputString;
								exit 0;
							} elsif ($activeMembers le $criticalLimit) {
								print "CRITICAL" . $outputString;
								exit 2;
							} elsif ($activeMembers le $warningLimit) {
								print "WARNING" . $outputString;
								exit 1;
							} else {
								print "OK" . $outputString;
								exit 0;
							}
						}
					}
				}
			}
		}
	}
}

main();
