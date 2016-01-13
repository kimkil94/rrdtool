#!/bin/bash

IFCONFIG="/sbin/ifconfig"
INTERFACE="eth0"
WORKDIR="/root/rrd/TEST"
RRDDB="$WORKDIR/$INTERFACE'.rrd'"
HOST_IP=""
#in=$(ssh $HOST_IP $IFCONFIG $INTERFACE | grep bytes | awk '{print $2}' | cut -d : -f 2)
#out=$(ssh $HOST_IP $IFCONFIG $INTERFACE | grep bytes | awk '{print $6}' | cut -d : -f 2)
in=$($IFCONFIG $INTERFACE | grep bytes| awk '{print $2}' | cut -d : -f 2)
out=$($IFCONFIG $INTERFACE | grep bytes | awk '{print $6}' |  cut -d : -f 2)
#COLOR DEFINITIION
#RED='\033[0;31m'
GREEN='\033[0;32m'
COLOR_END='\033['
SWITCH="\033["
NORMAL='${SWITCH}0m'
YELLOW="${SWITCH}1;33m"
RED="${SWITCH}0;31m"
RESET="\x1B[0m"
echo $RRDDB

#check_interface=`$IFCONFIG $INTERFACE`
echo "checking interface: $INTERFACE"
if $IFCONFIG $INTERFACE &>> /dev/null; then
	echo "$INTERFACE exist"
	echo  -e "CHECK INTERFACE :" "$GREEN OK $RESET"
	echo "Checking Round Robin Database"

#reate RRD if doesnt exist
if [ -e $RRDDB ];then
        echo "Round Robin Database $RRDDB already exist"
else

        echo "Round Robin Database $RRDDB doesnt exist"
        echo "Creating DB..."
        rrdtool create $RRDDB \
        --step 60 \
        --step 60 \
        DS:$INTERFACE'_rx':COUNTER:120:0:U \
        DS:$INTERFACE'_tx':COUNTER:120:0:U \
        RRA:AVERAGE:0.5:1:3600 \
        RRA:MAX:0.5:1:3600
        if [ -a $RRDDB ];then
                echo "RRD database $RRDDB was created"
                echo "OK"
        fi
fi
echo $in $out
rrdupdate $RRDDB N:$in:$out

rrdtool graph $WORKDIR/$INTERFACE'_hourly.png' --start end-3600s   \
        -a PNG -t "Hourly - Network $HOST_IP Interface $INTERFACE" --vertical-label "bits/s" \
        -w 1260 -h 800 -r \
        DEF:$INTERFACE'_rx'=$RRDDB:$INTERFACE'_rx':AVERAGE \
        DEF:$INTERFACE'_tx'=$RRDDB:$INTERFACE'_tx':AVERAGE \
        CDEF:$INTERFACE'_rxb'=$INTERFACE'_rx',-8,\* \
        CDEF:$INTERFACE'_txb'=$INTERFACE'_tx',8,\* \
        AREA:$INTERFACE'_rxb'#EC9D48:_$INTERFACE'-RX' \
        AREA:$INTERFACE'_txb'#ECD748:_$INTERFACE'-TX' \
        LINE1:$INTERFACE'_rxb'#CC7016:_$INTERFACE'-RX' \
        LINE1:$INTERFACE'_txb'#C9B215:_$INTERFACE'-TX'

#daily
rrdtool graph $WORKDIR/$INTERFACE'_daily.png' --start end-86400s   \
        -a PNG -t "Daily - Network OpenWRT Interface $INTERFACE" --vertical-label "bits/s" \
        -w 1260 -h 800 -r \
        DEF:$INTERFACE'_rx'=$RRDDB:$INTERFACE'_rx':AVERAGE \
        DEF:$INTERFACE'_tx'=$RRDDB:$INTERFACE'_tx':AVERAGE \
        CDEF:$INTERFACE'_rxb'=$INTERFACE'_rx',-8,\* \
        CDEF:$INTERFACE'_txb'=$INTERFACE'_tx',8,\* \
        AREA:$INTERFACE'_rxb'#EC9D48:$INTERFACE'-RX' \
        AREA:$INTERFACE'_txb'#ECD748:$INTERFACE'-TX' \
        LINE1:$INTERFACE'_rxb'#CC7016:$INTERFACE'-RX' \
        LINE1:$INTERFACE'_txb'#C9B215:$INTERFACE'-TX'

#create weekly graph
rrdtool graph $WORKDIR/$INTERFACE'_weekly.png' --start end-604800s   \
        -a PNG -t "Weekly - Network OpenWRT Interface $INTERFACE" --vertical-label "bits/s" \
        -w 1260 -h 800 -r \
        DEF:$INTERFACE'_rx'=$RRDDB:$INTERFACE'_rx':AVERAGE \
        DEF:$INTERFACE'_tx'=$RRDDB:$INTERFACE'_tx':AVERAGE \
        CDEF:$INTERFACE'_rxb'=$INTERFACE'_rx',-8,\* \
        CDEF:$INTERFACE'_txb'=$INTERFACE'_tx',8,\* \
        AREA:$INTERFACE'_rxb'#D7CC00:$INTERFACE'-RX' \
        AREA:$INTERFACE'_txb'#D7CC00:$INTERFACE'-TX' \
        LINE2:$INTERFACE'_rxb'#0101D6:_$INTERFACE'-RX' \
        LINE2:$INTERFACE'_txb'#00D730:_$INTERFACE'-TX'



cp $WORKDIR/$INTERFACE'_hourly.png' /var/www/html/TEST/$INTERFACE'_hourly.png'
cp $WORKDIR/$INTERFACE'_daily.png' /var/www/html/TEST/$INTERFACE'_daily.png'
cp $WORKDIR/$INTERFACE'_weekly.png' /var/www/html/TEST/$INTERFACE'_weekly.png'

else

	echo -e "Interface $INTERFACE doesnt exist:$RED failed $RESET "
fi
	
