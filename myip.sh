#!/bin/bash 

CDIR=$( dirname $0 )
[ ! -f $CDIR/myip.conf ] && {
	echo "Please set vars in $CDIR/myip.conf"
	exit 1
}
source $CDIR/myip.conf
[ ! -f $CDIR/.myip.secret ] && {
	echo "Please set credentials in $CDIR/.myip.secret"
	exit 1
}
CREDENTIALS=$( cat $CDIR/.myip.secret )

HOSTNAME=$1
MEMFILE="$TMP/curip.$HOSTNAME"

function register_ip () {
	D=$HOSTNAME
	T="https://www.ovh.com/nic/update?system=dyndns&hostname=$D&myip=$MYIP"
	st=$( curl -s -u $CREDENTIALS $T )
        echo "-- register new ip, status =  $st" >> "$LOG"
}

OLDIP=$( cat $MEMFILE 2>/dev/null )
CURIP=$( curl -s http://whatismyip.akamai.com/ && echo )
DNSIP=$( host $HOSTNAME | grep -v NXDOMAIN | awk '{print $4}' )

[ "$DNSIP" == "" ] && {
        /usr/sbin/sendmail $TO <<EOM
subject: $HOSTNAME : not found
to: $TO 

-- date    = `date`
-- stored  = $OLDIP
-- current = $CURIP
-- dns     = --none--
EOM
	exit
}

[ "$DNSIP" != "$CURIP" ] && {
	echo "subject: IP changed : $DNSIP --> $CURIP" > $LOG
	echo "to: $TO " >> $LOG
 	echo "" >> $LOG
	echo "-- date      = `date`" >> $LOG
	echo "-- dns ip    = $DNSIP" >> $LOG
	echo "-- new ip    = $CURIP" >> $LOG
	echo "-- stored ip = $OLDIP" >> $LOG
 	register_ip $CURIP >> $LOG
	echo "$CURIP" > $MEMFILE
 	echo "-- store new ip" >> "$LOG"
	/usr/sbin/sendmail $TO < "$LOG"
        rm -f "$LOG"
}
[ "$2" == "mail" ] && {
  	ST="KO"
	[ "$DNSIP" == "$CURIP" ] &&  ST="OK"
        /usr/sbin/sendmail $TO <<EOM
subject: $HOSTNAME : $ST [ Current=$CURIP :  DNS=$DNSIP ]
to: $TO

-- date    = `date`
-- stored  = $OLDIP
-- current = $CURIP
-- dns     = $DNSIP
EOM
}
exit
