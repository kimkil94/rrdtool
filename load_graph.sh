#!/bin/bash
# memory.sh - Memory usage stats


WORKDIR="/var/lib/rrd"
DB=$WORKDIR/load.rrd
img=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"

one_load=$(uptime | awk '{print $10}' | cut -d , -f 1)
five_load=$(uptime | awk '{print $11}' | cut -d , -f 1)
fiveteen_load=$(uptime | awk '{print $12}')

if [ ! -e $DB ]
then 
	rrdtool create $DB \
	--step 60 \
	-b 123456789 \
	DS:five_load:GAUGE:120:0:50  \
	DS:one_load:GAUGE:120:0:50 \
	RRA:MAX:0.5:1:288 
fi


#total - one_load ; usage : five_load
rrdtool update $DB N:$five_load:$one_load

for period in hour day week month year
do

	rrdtool graph $img/load-$period.png \
	-w 785 -h 120 -a PNG \
	--slope-mode \
	 -s -1$period --end now \
	--vertical-label "CPU load" \
	DEF:one_load=$DB:one_load:MAX \
	DEF:five_load=$DB:five_load:MAX \
	LINE1:one_load#ff0000:"One Minute CPU load" \
	LINE1:five_load#0000ff:"Five Minute CPU load"

#	rrdtool graph $img/load-$period.png -s -1$period \
#	-t "Memory usage the last $period" -z \
#	-c "BACK#616066" -c "SHADEA#FFFFFF" -c "SHADEB#FFFFFF" \
#	-c "MGRID#AAAAAA" -c "GRID#CCCCCC" -c "ARROW#333333" \
#	-c "FONT#333333" -c "AXIS#333333" -c "FRAME#333333" \
#        -h 134 -w 543 -l 0 -a PNG \
#	DEF:five_load=$DB:five_load:AVERAGE\
#	VDEF:min_five_load=five_load,MINIMUM \
#        VDEF:max_five_load=five_load,MAXIMUM \
#        VDEF:avg_five_load=five_load,AVERAGE \
#        VDEF:lst_five_load=five_load,LAST \
#	"AREA:five_load#E04000:Five" "LINE1:five_load#F47200" \
#	"GPRINT:min_five_load:%5.1lf %sB   " \
#	"GPRINT:max_five_load:%5.1lf %sB   " \
##	"GPRINT:avg_five_load:%5.1lf %sB   " \
#	"GPRINT:lst_five_load:%5.1lf %sB   \l" 
done

if grep $RUNDIR/load_graph.sh /var/spool/cron/crontabs/root;then
	echo "cron task already set"
else
echo "creating cron task..."
echo "  */5  *  *  *  *  $RUNDIR/load_graph.sh" >> /var/spool/cron/crontabs/root
fi
