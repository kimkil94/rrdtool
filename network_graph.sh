#!/bin/bash
#===KimkIL=== 2016(c)

IFCONFIG="/sbin/ifconfig"
INTERFACE="eth0"
WORKDIR="/var/lib/rrd"
WEBDIR="/var/www/html/stats"
ACTUALDIR=$(pwd)
RUNDIR="/opt/rrd/rrdtool"
RRDDB="$WORKDIR/$INTERFACE'.rrd'"
HOST_IP=""
in=`$IFCONFIG $INTERFACE | grep bytes| awk '{print $2}' | cut -d : -f 2`
out=`$IFCONFIG $INTERFACE | grep bytes | awk '{print $6}' |  cut -d : -f 2`
WIDTH="720"
HEIGHT="220"

#COLOR DEFINITIION
GREEN='\033[0;32m'
COLOR_END='\033['
SWITCH="\033["
NORMAL='${SWITCH}0m'
YELLOW="${SWITCH}1;33m"
RED="${SWITCH}0;31m"
RESET="\x1B[0m"


#Prechecks functions

#checking if is RRDTOOL installed on system
#return codes: 1 error ; 0 ok ; 3 UNKNOWN
function check_rrdtool {
	os=$(lsb_release -si)
	if [ $os == "Debian" ]; then
		if  dpkg -s rrdtool &>/dev/null; then
			return 0
		else
			apt-get update && apt-get -y install rrdtool
			if dpkg -s rrdtool &> /dev/null;then
				return 0
			else
				return 1
			fi
		fi
	fi
return 3
}
check_rrdtool
result_check_rrdtool=$?


function check_interface {
	if $IFCONFIG $INTERFACE &>/dev/null ; then
		if [ -z $out ] && [ -z $in ];then #check if variable out and in are empty
			return 1
		else
			return 0	
		fi
	else
		return 1

	fi
return 3
}
check_interface
result_check_interface=$?

#checking if paths exist
#WORKDIR and WEBDIR
function check_paths {
	if [ -d $WORKDIR ] && [ -d $WEBDIR ];then
		return 0
	else
		if [ ! -d $WORKDIR ];then
			mkdir -p $WORKDIR
		fi
		if [ ! -d $WEBDIR ];then
			mkdir -p $WEBDIR
		fi
		
		if [ -d $WORKDIR ] && [ -d $WEBDIR ];then
			return 0
		else
			return 1
		fi
		
	fi
}
check_paths
result_check_paths=$?



#Create RRD if doesnt exist
if [ $result_check_rrdtool == "0" ] && [ $result_check_interface == "0" ] && [ $result_check_paths == "0" ]; then
  


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
        	RRA:AVERAGE:0.5:1:600d \
        	RRA:MAX:0.5:1:600d
        	if [ -a $RRDDB ];then
                	echo "RRD database $RRDDB was created"
                	echo "OK"
        	fi
	fi

	rrdupdate $RRDDB N:$in:$out

	rrdtool graph $WORKDIR/$INTERFACE'_hourly.png' --start end-3600s   \
        	-a PNG -t "Hourly - Network $HOST_IP Interface $INTERFACE" --vertical-label "bits/s" \
        	-w $WIDTH -h $HEIGHT -r \
		-c "BACK#000000" \
	        -c "SHADEA#000000" \
	        -c "SHADEB#000000" \
        	-c "FONT#DDDDDD" \
	        -c "CANVAS#202020" \
	        -c "GRID#666666" \
	        -c "MGRID#AAAAAA" \
	        -c "FRAME#202020" \
	        -c "ARROW#FFFFFF" \
        	DEF:$INTERFACE'_rx'=$RRDDB:$INTERFACE'_rx':AVERAGE \
        	DEF:$INTERFACE'_tx'=$RRDDB:$INTERFACE'_tx':AVERAGE \
        	CDEF:$INTERFACE'_rxb'=$INTERFACE'_rx',-8,\* \
        	CDEF:$INTERFACE'_txb'=$INTERFACE'_tx',8,\* \
        	AREA:$INTERFACE'_rxb'#EC9D48:_$INTERFACE'-RX' \
        	AREA:$INTERFACE'_txb'#ECD748:_$INTERFACE'-TX' \
        	LINE1:$INTERFACE'_rxb'#CC7016:_$INTERFACE'-RX' \
        	LINE1:$INTERFACE'_txb'#C9B215:_$INTERFACE'-TX'

	#daily
	rrdtool graph $WORKDIR/$INTERFACE'_daily.png' --start -1day   \
        	-a PNG -t "Daily - Network OpenWRT Interface $INTERFACE" --vertical-label "bits/s" \
        	-w $WIDTH -h $HEIGHT -r \
		-c "BACK#000000" \
                -c "SHADEA#000000" \
                -c "SHADEB#000000" \
                -c "FONT#DDDDDD" \
                -c "CANVAS#202020" \
                -c "GRID#666666" \
                -c "MGRID#AAAAAA" \
                -c "FRAME#202020" \
                -c "ARROW#FFFFFF" \
        	DEF:$INTERFACE'_rx'=$RRDDB:$INTERFACE'_rx':AVERAGE \
        	DEF:$INTERFACE'_tx'=$RRDDB:$INTERFACE'_tx':AVERAGE \
        	CDEF:$INTERFACE'_rxb'=$INTERFACE'_rx',-8,\* \
        	CDEF:$INTERFACE'_txb'=$INTERFACE'_tx',8,\* \
        	AREA:$INTERFACE'_rxb'#EC9D48:$INTERFACE'-RX' \
        	AREA:$INTERFACE'_txb'#ECD748:$INTERFACE'-TX' \
        	LINE1:$INTERFACE'_rxb'#CC7016:$INTERFACE'-RX' \
        	LINE1:$INTERFACE'_txb'#C9B215:$INTERFACE'-TX'

	#create weekly graph
	rrdtool graph $WORKDIR/$INTERFACE'_weekly.png' --start -1week   \
        	-a PNG -t "Weekly - Network OpenWRT Interface $INTERFACE" --vertical-label "bits/s" \
        	-w $WIDTH -h $HEIGHT -r \
		-c "BACK#000000" \
                -c "SHADEA#000000" \
                -c "SHADEB#000000" \
                -c "FONT#DDDDDD" \
                -c "CANVAS#202020" \
                -c "GRID#666666" \
                -c "MGRID#AAAAAA" \
                -c "FRAME#202020" \
                -c "ARROW#FFFFFF" \
        	DEF:$INTERFACE'_rx'=$RRDDB:$INTERFACE'_rx':AVERAGE \
        	DEF:$INTERFACE'_tx'=$RRDDB:$INTERFACE'_tx':AVERAGE \
        	CDEF:$INTERFACE'_rxb'=$INTERFACE'_rx',-8,\* \
        	CDEF:$INTERFACE'_txb'=$INTERFACE'_tx',8,\* \
        	AREA:$INTERFACE'_rxb'#D7CC00:$INTERFACE'-RX' \
        	AREA:$INTERFACE'_txb'#D7CC00:$INTERFACE'-TX' \
        	LINE2:$INTERFACE'_rxb'#0101D6:_$INTERFACE'-RX' \
        	LINE2:$INTERFACE'_txb'#00D730:_$INTERFACE'-TX'



	cp $WORKDIR/$INTERFACE'_hourly.png' $WEBDIR/$INTERFACE'_hourly.png'
	cp $WORKDIR/$INTERFACE'_daily.png' $WEBDIR/$INTERFACE'_daily.png'
	cp $WORKDIR/$INTERFACE'_weekly.png' $WEBDIR/$INTERFACE'_weekly.png'
	
if grep $RUNDIR/network_graph.sh /var/spool/cron/crontabs/root;then
	echo "Crontab is set"
else
	echo "Setting crontab.."
	echo "  * * * * * $RUNDIR/network_graph.sh" >> /var/spool/cron/crontabs/root
fi


else
	if [ $result_check_interface == "1" ];then
		echo -e "Interface $RED $INTERFACE $RESET doesnt exist : $RED FAILED $RESET "
	fi
	if [ $result_check_paths == "1" ];then
		echo -e "Paths $WEBDIR and $WORKDIR doesnt exist and cannot be created: $RED FAILED $RESET"
	fi
	if [ $result_check_rrdtool == "1" ];then
		echo -e "RRDTOOL is not installed and try to install $RED FAILED $RESET"
	fi
fi
	
