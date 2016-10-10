#!/bin/bash
# memory.sh - Memory usage stats
#

WORKDIR="/var/lib/rrd"
DB=$WORKDIR/sockets.rrd
WEBDIR=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"
CRONTAB="/var/spool/cron/crontabs/root"
WIDTH="720"
HEIGHT="190"
VERTICAL_LABEL="Sockets "
RUNSCRIPT=$0
SCRIPT_NAME=$(echo $RUNSCRIPT | cut -d / -f 2)


echo $SCRIPT_NAME

all_sockets=$(/bin/netstat -anp | wc -l)
tcp_sockets=$(/bin/cat /proc/net/protocols | /bin/grep "^TCP "| awk '{print $3}')
udp_sockets=$(/bin/cat /proc/net/protocols | /bin/grep "^UDP "| awk '{print $3}')
unix_sockets=$(/bin/cat /proc/net/protocols | /bin/grep "^UNIX "| awk '{print $3}')

if [ ! -e $DB ]
then 
	rrdtool create $DB \
	--step 60 \
	DS:all_sockets:GAUGE:120:0:500000\
	DS:tcp_sockets:GAUGE:120:0:500000  \
	DS:udp_sockets:GAUGE:120:0:500000 \
	DS:unix_sockets:GAUGE:120:0:50000 \
	RRA:LAST:0.5:1:600d  \
	RRA:AVERAGE:0.5:1:600d  
fi


#update RRDB
rrdtool update $DB N:$all_sockets:$tcp_sockets:$udp_sockets:$unix_sockets

#creating graphs in periods: hour, day, week,month,year
for period in hour day week month year
do

	rrdtool graph $WEBDIR/sockets-$period.png -w $WIDTH -h $HEIGHT -a PNG --slope-mode -s -1$period --end now \
	--vertical-label "$VERTICAL_LABEL" \
	--title "Number of sockets by $period ($(uname -n))" \
	-c "BACK#000000" \
        -c "SHADEA#000000" \
        -c "SHADEB#000000" \
        -c "FONT#DDDDDD" \
        -c "CANVAS#202020" \
        -c "GRID#666666" \
        -c "MGRID#AAAAAA" \
        -c "FRAME#202020" \
        -c "ARROW#FFFFFF" \
	DEF:tcp_sockets=$DB:tcp_sockets:LAST \
	DEF:udp_sockets=$DB:udp_sockets:LAST \
	DEF:unix_sockets=$DB:unix_sockets:LAST \
	DEF:all_sockets=$DB:all_sockets:LAST\
	VDEF:min_tcp_sockets=tcp_sockets,MINIMUM \
        VDEF:max_tcp_sockets=tcp_sockets,MAXIMUM \
        VDEF:lst_tcp_sockets=tcp_sockets,LAST \
        VDEF:min_udp_sockets=udp_sockets,MINIMUM \
        VDEF:max_udp_sockets=udp_sockets,MAXIMUM \
	VDEF:lst_udp_sockets=udp_sockets,LAST \
	VDEF:min_unix_sockets=unix_sockets,MINIMUM \
        VDEF:max_unix_sockets=unix_sockets,MAXIMUM \
        VDEF:lst_unix_sockets=unix_sockets,LAST \
	AREA:all_sockets#54EC48:"Allsockets" \
	LINE1:udp_sockets#CC3118:"UDP sockets" \
	LINE1:tcp_sockets#C9B215:"TCP sockets" \
	AREA:tcp_sockets#ECD748: \
	LINE1:unix_sockets#24BC14:"UNIX sockets"\
	"COMMENT:    \l" \
	"COMMENT:             " \
	"COMMENT:             " \
	"COMMENT:               " \
        "COMMENT:TCP sockets (Last)    " \
        "COMMENT:UDP sockets (Last)   \l" \
	"COMMENT:                       "\
	"COMMENT:                       "\
	"COMMENT:            " \
        "GPRINT:lst_tcp_sockets:%5.1lf %sB   "\
        "GPRINT:lst_udp_sockets:%5.1lf %sB   \l" 
	 
done

#create cron task 
if grep $RUNDIR/$SCRIPT_NAME $CRONTAB;then
	echo "cron task already set"
else
echo "creating cron task..."
echo "  *  *  *  *  *  $RUNDIR/$SCRIPT_NAME" >> $CRONTAB
fi
