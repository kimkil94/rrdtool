#!/bin/bash

WORKDIR="/root/rrd/TEST"
DB="$WORKDIR/memory.rrd"

mem_total=$(grep MemTotal /proc/meminfo  | awk '{print $2}')
mem_free=$(grep MemFree /proc/meminfo  | awk '{print $2}')
mem_used=$(( mem_total - mem_free))

echo "Total Memory : $mem_total"
echo "Free Memory : $mem_free"
echo "Used Memory : $mem_used"


if [ -e $DB ];then 
	echo "$DB already exist.."

else
	rrdtool create $DB \
        	--start 1023654125 \
        	--step 120 \
        	DS:mem_total:GAUGE:600:0:671744 \
		DS:mem_used:GAUGE:600:0:671744 \
        	RRA:AVERAGE:0.5:12:24 \
        	RRA:AVERAGE:0.5:288:31
fi

rrdupdate $DB N:$mem_total:$mem_used



#rx = total ; tx : used
#rrdtool graph $WORKDIR/mem_hourly.png --start end-3600s   \
#                -a PNG -t "Memory usage" --vertical-label "bits/s" \
#                -w 1260 -h 800 -r \
#                DEF:mem_total=$DB:mem_total:AVERAGE \
#                DEF:mem_used=$DB:mem_used:AVERAGE \
#                CDEF:mem_totalb=mem_total,0,671744,LIMIT,UN,0,mem_total,IF,1024,/ \
#                CDEF:mem_usedb=mem_used,8,\* \
#                AREA:mem_totalb#EC9D48:Memory_total \
#                AREA:mem_usedb#ECD748:Memory_used \
#                LINE1:mem_totalb#CC7016:Memory_total \
#                LINE1:mem_usedb#C9B215:Memory_used

rrdtool graph $WORKDIR/mem_hourly.png --start end-3600s \
	-t "Memory usage the last hour" -z \
	-c "BACK#FFFFFF" -c "SHADEA#FFFFFF" -c "SHADEB#FFFFFF" \
	-c "MGRID#AAAAAA" -c "GRID#CCCCCC" -c "ARROW#333333" \
	-c "FONT#333333" -c "AXIS#333333" -c "FRAME#333333" \
        -h 134 -w 543 -l 0 -a PNG -v "B" \
	DEF:mem_used=$DB:mem_used:AVERAGE \
	VDEF:min=mem_used,MINIMUM \
        VDEF:max=mem_used,MAXIMUM \
        VDEF:avg=mem_used,AVERAGE \
        VDEF:lst=mem_used,LAST \
	"COMMENT: \l" \
	"COMMENT:               " \
	"COMMENT:Minimum    " \
	"COMMENT:Maximum    " \
	"COMMENT:Average    " \
	"COMMENT:Current    \l" \
	"COMMENT:   " \
	"AREA:mem_used#EDA362:Usage  " \
	"LINE1:mem_used#F47200" \
	"GPRINT:min:%5.1lf %sB   " \
	"GPRINT:max:%5.1lf %sB   " \
	"GPRINT:avg:%5.1lf %sB   " \
	"GPRINT:lst:%5.1lf %sB   \l" > /dev/null


cp $WORKDIR/mem_hourly.png /var/www/html/
