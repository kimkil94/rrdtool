#!/bin/bash
# memory.sh - Memory usage stats
#

WORKDIR="/var/lib/rrd"
DB=$WORKDIR/test_load.rrd
WEBDIR=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"
CRONTAB="/var/spool/cron/crontabs/root"
WIDTH="720"
HEIGHT="200"
VERTICAL_LABEL="CPU Utilization "
RUNSCRIPT=$0
SCRIPT_NAME=$(echo $RUNSCRIPT | cut -d / -f 2)


echo $SCRIPT_NAME
utilization=$(/usr/bin/head -n 1 /proc/stat | /bin/sed "s/^cpu\ \+\([0-9]*\)\ \([0-9]*\)\ \([0-9]*\).*/\1:\2:\3/")


if [ ! -e $DB ]
then 
        rrdtool create $DB \
        --step 60 \
        DS:cpuuser:COUNTER:180:0:100 \
	DS:cpunice:COUNTER:180:0:100 \
	DS:cpusys:COUNTER:180:0:100 \
	RRA:AVERAGE:0.5:1:60000 \
        RRA:AVERAGE:0.5:60000:1 \
	RRA:MIN:0.5:60000:1 \
	RRA:MAX:0.5:60000:1 
fi


#update RRDB
rrdtool update $DB N:$utilization
#creating graphs in periods: hour, day, week,month,year
for period in hour day week month year
do

        rrdtool graph $WEBDIR/cpu_utilization-$period.png -w $WIDTH -h $HEIGHT -a PNG --slope-mode -s -1$period --end now \
        --vertical-label "$VERTICAL_LABEL" \
        --title "CPU load by $period ($(uname -n))" \
          -c "BACK#000000" \
        -c "SHADEA#000000" \
        -c "SHADEB#000000" \
        -c "FONT#DDDDDD" \
        -c "CANVAS#202020" \
        -c "GRID#666666" \
        -c "MGRID#AAAAAA" \
        -c "FRAME#202020" \
        -c "ARROW#FFFFFF" \
        DEF:user=$DB:cpuuser:AVERAGE \
        DEF:nices=$DB:cpunice:AVERAGE \
        DEF:sys=$DB:cpusys:AVERAGE \
	CDEF:idle=100,user,nices,sys,+,+,-\
	COMMENT:"	" \
	AREA:user#0039e6:user \
	STACK:nices#b30000:nice \
	STACK:sys#00e600:system \
        STACK:idle#ccff66:idlei \
	COMMENT:"       \j" >/dev/null
done

#create cron task 
if grep $RUNDIR/$SCRIPT_NAME $CRONTAB;then
        echo "cron task already set"
else
echo "creating cron task..."
echo "  *  *  *  *  *  $RUNDIR/$SCRIPT_NAME" >> $CRONTAB
fi
