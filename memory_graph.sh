#!/bin/bash
# memory.sh - Memory usage stats


WORKDIR="/var/lib/rrd"
DB=$WORKDIR/memory_usage.rrd
img=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"

if [ ! -e $DB ]
then 
	rrdtool create $DB \
	--step 60 \
	--step 60 \
	DS:usage:GAUGE:600:0:50000000000  \
	DS:total:GAUGE:600:0:50000000000 \
	RRA:AVERAGE:0.5:1:576d \
	RRA:AVERAGE:0.5:6:672d \
	RRA:AVERAGE:0.5:24:732d \
	RRA:AVERAGE:0.5:144:1460d 
fi

rrdtool update $DB N:`free -b |grep cache:|cut -d":" -f2|awk '{print $1}'`:`free -b | grep Mem | awk '{print $2}'`

for period in hour day week month year
do
	rrdtool graph $img/memory_usage-$period.png -s -1$period \
	-t "Memory usage the last $period" -z \
	-c "BACK#616066" -c "SHADEA#FFFFFF" -c "SHADEB#FFFFFF" \
	-c "MGRID#AAAAAA" -c "GRID#CCCCCC" -c "ARROW#333333" \
	-c "FONT#333333" -c "AXIS#333333" -c "FRAME#333333" \
        -h 134 -w 543 -l 0 -a PNG -v "B" \
	DEF:total=$DB:total:AVERAGE \
	DEF:usage=$DB:usage:AVERAGE\
	VDEF:min_total=total,MINIMUM \
        VDEF:max_total=total,MAXIMUM \
        VDEF:avg_total=total,AVERAGE \
        VDEF:lst_total=total,LAST \
	VDEF:min_usage=usage,MINIMUM \
        VDEF:max_usage=usage,MAXIMUM \
        VDEF:avg_usage=usage,AVERAGE \
        VDEF:lst_usage=usage,LAST \
	"COMMENT:    \l" \
	"COMMENT: " \
	"GPRINT:max_total:%6.1lf %sB   " \
	"COMMENT:           " \
	"COMMENT:Minimum    " \
	"COMMENT:Maximum    " \
	"COMMENT:Average    " \
	"COMMENT:Current    \l" \
	"COMMENT:   " \
	"AREA:total#00FF00:Total  " \
	"LINE1:total#F47200" \
	"AREA:usage#E04000:Usage  " \
        "LINE1:usage#F47200" \
	"GPRINT:min_usage:%5.1lf %sB   " \
	"GPRINT:max_usage:%5.1lf %sB   " \
	"GPRINT:avg_usage:%5.1lf %sB   " \
	"GPRINT:lst_usage:%5.1lf %sB   \l" 
done

if grep $RUNDIR/memory_graph.sh /var/spool/cron/crontabs/root;then
	echo "cron task already set"
else
echo "creating cron task..."
echo "  */5  *  *  *  *  $RUNDIR/memory_graph.sh" >> /var/spool/cron/crontabs/root
fi
