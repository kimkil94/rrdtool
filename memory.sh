#!/bin/bash
# memory.sh - Memory usage stats
#
# Copyright 2010 Frode Petterson. All rights reserved.
# See README.rdoc for license. 

rrdtool=/usr/bin/rrdtool
db=/var/lib/rrd/MEM.rrd
img=/var/www/html/monitoring

if [ ! -e $db ]
then 
	rrdtool create $db \
	--step 60 \
	--step 60 \
	DS:usage:GAUGE:600:0:50000000000  \
	DS:total:GAUGE:600:0:50000000000 \
	RRA:AVERAGE:0.5:1:576 \
	RRA:AVERAGE:0.5:6:672 \
	RRA:AVERAGE:0.5:24:732 \
	RRA:AVERAGE:0.5:144:1460 
fi

rrdtool update $db N:`free -b |grep cache:|cut -d":" -f2|awk '{print $1}'`:`free -b | grep Mem | awk '{print $2}'`

for period in day week month year
do
	rrdtool graph $img/MEM-$period.png -s -1$period \
	-t "Memory usage the last $period" -z \
	-c "BACK#FFFFFF" -c "SHADEA#FFFFFF" -c "SHADEB#FFFFFF" \
	-c "MGRID#AAAAAA" -c "GRID#CCCCCC" -c "ARROW#333333" \
	-c "FONT#333333" -c "AXIS#333333" -c "FRAME#333333" \
        -h 134 -w 543 -l 0 -a PNG -v "B" \
	DEF:usage=$db:usage:AVERAGE \
	DEF:total=$db:total:AVERAGE\
	VDEF:min_usage=usage,MINIMUM \
        VDEF:max_usage=usage,MAXIMUM \
        VDEF:avg_usage=usage,AVERAGE \
        VDEF:lst_usage=usage,LAST \
	VDEF:min_total=total,MINIMUM \
        VDEF:max_total=total,MAXIMUM \
        VDEF:avg_total=total,AVERAGE \
        VDEF:lst_total=total,LAST \
	"COMMENT: \l" \
	"COMMENT:               " \
	"COMMENT:Minimum    " \
	"COMMENT:Maximum    " \
	"COMMENT:Average    " \
	"COMMENT:Current    \l" \
	"COMMENT:   " \
	"AREA:usage#EDA362:Usage  " \
	"LINE1:usage#F47200" \
	"AREA:total#00FF00:Total  " \
        "LINE1:total#00FF00" \
	"GPRINT:min_usage:%5.1lf %sB   " \
	"GPRINT:max_usage:%5.1lf %sB   " \
	"GPRINT:avg_usage:%5.1lf %sB   " \
	"GPRINT:lst_usage:%5.1lf %sB   \l" 
done

