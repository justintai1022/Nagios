#!/bin/sh

###############################################################
#    File name: Check_HP_Swich_5140.sh                       														 #
#    Author: Justin Tai                                       																		 #
#    Date created: 2022/11/23       																	                     #
#    Date last modified: 2022/11/29                           															 #
#    Version : 1.1                    								  											                         #
#    SAN Switch : for HP switch 5140																		             #
###############################################################
#    Version 1.0 : Check Fan and Power status
#    Version 1.1 : Modify  fan and power status judge logic.
###############################################################

# Nagios return codes
STATE_OK=0
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin variable description
PROGNAME=$(basename $0)
RELEASE="Revision 1.0"
AUTHOR="(c) 2022 Justin Tai (Jp10220821@pic.net.tw)"

#OID
FAN_OID=.1.3.6.1.4.1.25506.8.35.9.1.1.1.2
Power_OID=.1.3.6.1.4.1.25506.8.35.9.1.2.1.2


print_release() {
    echo "$RELEASE $AUTHOR"
}

print_usage() {
    echo ""
    echo "$PROGNAME $RELEASE - HP  switch (5140)"
    echo ""
    echo "Usage: $PROGNAME [-H | --hostname HOSTNAME] | [-c | --community COMMUNITY ] | [-h | --help] | [-v | --version] | [-t | --type] "
    echo ""
    echo "    -h  Show this page"
    echo "    -v  Plugin Version"
    echo "    -H  IP or Hostname of HP switch"
    echo "    -c  SNMP Community"
    echo "    -t  Check type"
    echo "        fan   -Fan status"
    echo "        power   -Power status"
    echo ""
}


print_help() {
		print_usage
        echo ""
        print_release $PROGNAME $RELEASE
        echo ""
        echo ""
        exit 0
}

# Make sure the correct number of command line arguments have been supplied
if [ $# -lt 3 ]; then
    print_usage
    exit $STATE_UNKNOWN
fi

# Grab the command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit $STATE_OK
            ;;
        -v | --version)
                print_release
                exit $STATE_OK
                ;;
        -H | --hostname)
                shift
                HOSTNAME=$1
                ;;
        -c | --community)
               shift
               COMMUNITY=$1
               ;;
        -t | --type)
               shift
               Check_type=$1
               ;;
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

#Check if the host is alive?
TYPE=$(snmpwalk -v 1 -c $COMMUNITY $HOSTNAME SNMPv2-SMI::mib-2.47.1.1.1.1.2.1)
if [ $? == 1 ]; then
    echo "UNKNOWN - Could not connect to SNMP server $HOSTNAME ."
    exit $STATE_UNKNOWN;
fi

#Check whether there is a type to be retrieved. If not, give a default type
if [[ -z "$Check_type" ]]; then
	Check_type=fan
fi

#Judging the type is that kind
if [ $Check_type = fan ]; then
	status=( $( snmpwalk -v2c -OEqv -c $COMMUNITY $HOSTNAME $FAN_OID 2>/dev/null) )
	if [ $? -ne 0 ]; then
	echo "UNKNOWN: SNMP timeout"
	exit $STATE_UNKNOWN
	fi
elif [ $Check_type = power ]; then
	status=( $( snmpwalk -v2c -OEqv -c $COMMUNITY $HOSTNAME $Power_OID 2>/dev/null) )
	if [ $? -ne 0 ]; then
	echo "UNKNOWN: SNMP timeout"
	exit $STATE_UNKNOWN
	fi
else
echo "Plese input current type"
exit $STATE_UNKNOWN
fi

#Judging current fan and power status
errors=0
for(( i = 0; i < ${#status[@]} ; i++ )) do
	if [ ${status[$i]} -eq 2 ]; then
	    echo "CRITICAL:$Check_type is down"
		errors=1
	fi
done

#Show result
if [ $errors -gt 0 ]; then
	exit $STATE_CRITICAL;
else
	echo "OK: $Check_type up"
	exit $STATE_OK;
fi


