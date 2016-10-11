#!/bin/bash
# memory.sh - Memory usage stats
#

WORKDIR="/var/lib/rrd"
DB=$WORKDIR/cpu_util.rrd
WEBDIR=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"
CRONTAB="/var/spool/cron/crontabs/root"
WIDTH="720"
HEIGHT="200"
VERTICAL_LABEL="CPU Utilization "
RUNSCRIPT=$0
SCRIPT_NAME=$(echo $RUNSCRIPT | cut -d / -f 2)


echo $SCRIPT_NAME

cpu_util=$(top -bn1 | sed -n '/Cpu/p')

user=$(echo $cpu_util | awk '{print $2}' | sed 's/..,//')
system=$(echo $cpu_util | awk '{print $4}' | sed 's/..,//')
nices=$(echo $cpu_util | awk '{print $6}' | sed 's/..,//')
idle=$(echo $cpu_util | awk '{print $8}' | sed 's/..,//')
iowait=$(echo $cpu_util| awk '{print $10}' | sed 's/..,//')
hirq=$(echo $cpu_util | awk '{print $12}' | sed 's/..,//')
sirq=$(echo $cpu_util | awk '{print $14}' | sed 's/..,//')
steal=$(echo $cpu_util | awk '{print $16}' | sed 's/..,//')



if [ ! -e $DB ]
then 
        rrdtool create $DB \
        --step 60 \
        DS:user:GAUGE:120:0.00:100  \
        DS:system:GAUGE:120:0.00:100 \
        DS:nices:GAUGE:120:0.00:100 \
        DS:idle:GAUGE:120:0.00:100 \
        DS:iowait:GAUGE:120:0.00:100 \
        DS:hirq:GAUGE:120:0.00:100 \
        DS:sirq:GAUGE:120:0.00:100 \
        DS:steal:GAUGE:120:0.00:100 \
        RRA:MAX:0.5:1:600d \
        RRA:AVERAGE:0.5:1:600d 
fi


#update RRDB
rrdtool update $DB N:$user:$system:$nices:$idle:$iowait:$hirq:$sirq:$steal

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
        DEF:user=$DB:user:AVERAGE \
        DEF:system=$DB:system:AVERAGE \
        DEF:nices=$DB:nices:AVERAGE \
        DEF:idle=$DB:idle:AVERAGE \
        DEF:iowait=$DB:iowait:AVERAGE \
        DEF:hirq=$DB:hirq:AVERAGE \
        DEF:sirq=$DB:sirq:AVERAGE \
        DEF:steal=$DB:steal:AVERAGE \
        AREA:user#0039e6:user \
        AREA:system#00e600:system \
        AREA:nices#b30000:nice \
        AREA:idle#ccff66:idle \
        AREA:hirq#e600e6:hirq \
        AREA:sirq#cc6699:sirq \
        AREA:steal#994d00:steal  
done

#create cron task 
if grep $RUNDIR/$SCRIPT_NAME $CRONTAB;then
        echo "cron task already set"
else
echo "creating cron task..."
echo "  *  *  *  *  *  $RUNDIR/$SCRIPT_NAME" >> $CRONTAB
fi
