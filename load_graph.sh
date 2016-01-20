#!/bin/bash
# memory.sh - Memory usage stats
#

WORKDIR="/var/lib/rrd"
DB=$WORKDIR/load.rrd
WEBDIR=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"
CRONTAB="/var/spool/cron/crontabs/root"

one_load=$(uptime | awk '{print $10}' | cut -d , -f 1)
five_load=$(uptime | awk '{print $11}' | cut -d , -f 1)
fiveteen_load=$(uptime | awk '{print $12}')

if [ ! -e $DB ]
then 
	rrdtool create $DB \
	--step 60 \
	DS:five_load:GAUGE:120:0.00:50  \
	DS:one_load:GAUGE:120:0.00:50 \
	RRA:MAX:0.5:1:288 \
	RRA:AVERAGE:0.5:1:288 
fi


#update RRDB
rrdtool update $DB N:$one_load:$five_load

#creating graphs in periods: hour, day, week,month,year
for period in hour day week month year
do

	rrdtool graph $WEBDIR/load-$period.png -w 785 -h 120 -a PNG --slope-mode -s -1$period --end now \
	--vertical-label "CPU load" \
	DEF:one_load=$DB:one_load:AVERAGE \
	DEF:five_load=$DB:five_load:AVERAGE \
	AREA:one_load#f007:one_load \
	AREA:five_load#f005:five_load 
	 
done

#create cron task 
if grep $RUNDIR/load_graph.sh /var/spool/cron/crontabs/root;then
	echo "cron task already set"
else
echo "creating cron task..."
echo "  */5  *  *  *  *  $RUNDIR/load_graph.sh" >> $CRONTAB
fi
