#!/bin/bash
# connections_graph.sh - Connections statistics
#

WORKDIR="/var/lib/rrd"
DB=$WORKDIR/connections.rrd
WEBDIR=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"
CRONTAB="/var/spool/cron/crontabs/root"
WIDTH="720"
HEIGHT="200"
established_conn=$(netstat -an | grep ":80 " | grep ESTABLISHED | wc -l)
timewait_conn=$(netstat -an | grep ":80 " | grep TIME| wc -l)
echo $established_conn
echo $timewait_conn

if [ ! -e $DB ]
then 
	rrdtool create $DB \
	--step 60 \
	DS:established:GAUGE:120:0:5000  \
	DS:timewait:GAUGE:120:0:50000 \
	RRA:MAX:0.5:1:600000 \
	RRA:AVERAGE:0.5:1:600000 
fi


#update RRDB
rrdtool update $DB N:$established_conn:$timewait_conn

#creating graphs in periods: hour, day, week,month,year
for period in hour day week month year
do

	rrdtool graph $WEBDIR/connections-$period.png -w $WIDTH -h $HEIGHT -a PNG --slope-mode -s -1$period --end now \
	--vertical-label "Active HTTP connections"  \
	--title "HTTP Connections by $period ($(uname -n))"\
	  -c "BACK#000000" \
        -c "SHADEA#000000" \
        -c "SHADEB#000000" \
        -c "FONT#DDDDDD" \
        -c "CANVAS#202020" \
        -c "GRID#666666" \
        -c "MGRID#AAAAAA" \
        -c "FRAME#202020" \
        -c "ARROW#FFFFFF" \
	DEF:established=$DB:established:AVERAGE \
	DEF:timewait=$DB:timewait:AVERAGE \
	AREA:established#f007:established_conn \
	AREA:timewait#f015:timewait_conn 
	 
done

#create cron task 
if grep $RUNDIR/connections_graph.sh /var/spool/cron/crontabs/root;then
	echo "cron task already set"
else
echo "creating cron task..."
echo "  *  *  *  *  *  $RUNDIR/connections_graph.sh" >> $CRONTAB
fi
