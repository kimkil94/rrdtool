#!/bin/bash
# memory.sh - Memory usage stats
#

WORKDIR="/var/lib/rrd"
DB=$WORKDIR/load.rrd
WEBDIR=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"
CRONTAB="/var/spool/cron/crontabs/root"
WIDTH="785"
HEIGHT="120"
VERTICAL_LABEL="CPU load "
RUNSCRIPT=$0
SCRIPT_NAME=$(echo $RUNSCRIPT | cut -d / -f 2)


echo $SCRIPT_NAME


one_load=$(uptime | awk '{print $10}' | cut -d , -f 1)
five_load=$(uptime | awk '{print $11}' | cut -d , -f 1)
fiveteen_load=$(uptime | awk '{print $12}')

if [ ! -e $DB ]
then 
	rrdtool create $DB \
	--step 60 \
	DS:five_load:GAUGE:120:0.00:50  \
	DS:one_load:GAUGE:120:0.00:50 \
	RRA:MAX:0.5:1:600d \
	RRA:AVERAGE:0.5:1:600d 
fi


#update RRDB
rrdtool update $DB N:$one_load:$five_load

#creating graphs in periods: hour, day, week,month,year
for period in hour day week month year
do

	rrdtool graph $WEBDIR/load-$period.png -w $WIDTH -h $HEIGHT -a PNG --slope-mode -s -1$period --end now \
	--vertical-label "$VERTICAL_LABEL" \
	--title "CPU load by $period ($(uname -n))" \
	DEF:one_load=$DB:one_load:AVERAGE \
	DEF:five_load=$DB:five_load:AVERAGE \
	VDEF:min_five_load=five_load,MINIMUM \
        VDEF:max_five_load=five_load,MAXIMUM \
        VDEF:avg_five_load=five_load,AVERAGE \
        VDEF:lst_five_load=five_load,LAST \
        VDEF:min_one_load=one_load,MINIMUM \
        VDEF:max_one_load=one_load,MAXIMUM \
        VDEF:avg_one_load=one_load,AVERAGE \
        VDEF:lst_one_load=one_load,LAST \
	AREA:five_load#FA3C00:One_minute_load \
	AREA:one_load#F99677:Last_Five_minute_load \
	"COMMENT:    \l" \
	"COMMENT:             " \
	"COMMENT:             " \
	"COMMENT:               " \
        "COMMENT:Last one_load    " \
        "COMMENT:Last five_load   \l" \
	"COMMENT:                       "\
	"COMMENT:                       "\
        "GPRINT:lst_one_load:%5.1lf" \
	"COMMENT:            "\
        "GPRINT:lst_five_load:%5.1lf \l" 
	 
done

#create cron task 
if grep $RUNDIR/$SCRIPT_NAME $CRONTAB;then
	echo "cron task already set"
else
echo "creating cron task..."
echo "  *  *  *  *  *  $RUNDIR/$SCRIPT_NAME" >> $CRONTAB
fi
