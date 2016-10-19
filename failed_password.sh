#!/bin/bash
# memory.sh - Memory usage stats
#

WORKDIR="/var/lib/rrd"
DB=$WORKDIR/failed_password.rrd
LOGFILE=$1
WEBDIR=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"
CRONTAB="/var/spool/cron/crontabs/root"
WIDTH="720"
HEIGHT="200"
VERTICAL_LABEL="Response per second"
RUNSCRIPT=$0
SCRIPT_NAME=$(echo $RUNSCRIPT | cut -d / -f 2)


failed=$(/bin/grep "Failed password for" $LOGFILE | wc -l)
if [ ! -e $DB ]
then 
        rrdtool create $DB \
        --step 60 \
        DS:failed:COUNTER:120:0:50000  \
        RRA:MAX:0.5:1:60000 \
        RRA:AVERAGE:0.5:1:60000 
fi


#update RRDB
rrdtool update $DB N:$failed

#creating graphs in periods: hour, day, week,month,year
for period in hour day week month year
do

        rrdtool graph $WEBDIR/failed_password-$period.png -w $WIDTH -h $HEIGHT -a PNG --slope-mode -s -1$period --end now \
        --vertical-label "$VERTICAL_LABEL" -X 0 \
        --title "Failed password $LOGFILE $period ($(uname -n))" \
          -c "BACK#000000" \
        -c "SHADEA#000000" \
        -c "SHADEB#000000" \
        -c "FONT#DDDDDD" \
        -c "CANVAS#202020" \
        -c "GRID#666666" \
        -c "MGRID#AAAAAA" \
        -c "FRAME#202020" \
	DEF:failed=$DB:failed:AVERAGE \
        AREA:failed#6600cc:"Failed login attempts"
done

#create cron task 
if grep $RUNDIR/$SCRIPT_NAME $CRONTAB;then
        echo "cron task already set"
else
echo "creating cron task..."
echo "  *  *  *  *  *  $RUNDIR/$SCRIPT_NAME $LOGFILE" >> $CRONTAB
fi
