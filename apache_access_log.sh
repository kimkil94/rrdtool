#!/bin/bash
# memory.sh - Memory usage stats
#

WORKDIR="/var/lib/rrd"
LOGFILE=$1
NAME=$(echo $LOGFILE | awk -F ".log" '{print $2}' | awk -F "/" '{print $3}')
DB=$WORKDIR/apache_access_$NAME.rrd
WEBDIR=/var/www/html/stats
RUNDIR="/opt/rrd/rrdtool"
CRONTAB="/var/spool/cron/crontabs/root"
WIDTH="720"
HEIGHT="200"
VERTICAL_LABEL="Response per second"
RUNSCRIPT=$0
SCRIPT_NAME=$(echo $RUNSCRIPT | cut -d / -f 2)


echo $SCRIPT_NAME
echo $r200

r500=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "500" | /usr/bin/wc -l)
r502=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "502" | /usr/bin/wc -l)
r503=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "503" | /usr/bin/wc -l)
r504=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "504" | /usr/bin/wc -l)
r404=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "404" | /usr/bin/wc -l)
r302=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "302" | /usr/bin/wc -l)
r401=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "401" | /usr/bin/wc -l)
r200=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "200" | /usr/bin/wc -l)
r101=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "101" | /usr/bin/wc -l)
r202=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "202" | /usr/bin/wc -l)
r301=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "301" | /usr/bin/wc -l)
r307=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "307" | /usr/bin/wc -l)
r403=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "403" | /usr/bin/wc -l)
r408=$(/usr/bin/awk '{print $9}' $LOGFILE | /bin/grep "408" | /usr/bin/wc -l)
echo $r200

if [ ! -e $DB ]
then 
        rrdtool create $DB \
        --step 60 \
        DS:r500:COUNTER:120:0:50000  \
        DS:r502:COUNTER:120:0:50000  \
        DS:r503:COUNTER:120:0:50000  \
        DS:r504:COUNTER:120:0:50000  \
        DS:r404:COUNTER:120:0:50000  \
        DS:r302:COUNTER:120:0:50000  \
        DS:r401:COUNTER:120:0:50000  \
        DS:r200:COUNTER:120:0:50000  \
        DS:r101:COUNTER:120:0:50000  \
        DS:r202:COUNTER:120:0:50000  \
        DS:r301:COUNTER:120:0:50000  \
        DS:r307:COUNTER:120:0:50000  \
        DS:r403:COUNTER:120:0:50000  \
        DS:r408:COUNTER:120:0:50000  \
        RRA:MAX:0.5:1:60000 \
        RRA:AVERAGE:0.5:1:60000 
fi


#update RRDB
rrdtool update $DB N:$r500:$r502:$r503:$r504:$r404:$r302:$r401:$r200:$r101:$r202:$r301:$r307:$r403:$r408

#creating graphs in periods: hour, day, week,month,year
for period in hour day week month year
do

        rrdtool graph $WEBDIR/apache_access_$NAME-$period.png -w $WIDTH -h $HEIGHT -a PNG --slope-mode -s -1$period --end now \
        --vertical-label "$VERTICAL_LABEL" -X 0 \
        --title "Apache access $LOGFILE $period ($(uname -n))" \
          -c "BACK#000000" \
        -c "SHADEA#000000" \
        -c "SHADEB#000000" \
        -c "FONT#DDDDDD" \
        -c "CANVAS#202020" \
        -c "GRID#666666" \
        -c "MGRID#AAAAAA" \
        -c "FRAME#202020" \
        -c "ARROW#FFFFFF" \
        DEF:r500=$DB:r500:AVERAGE \
        DEF:r502=$DB:r502:AVERAGE \
        DEF:r503=$DB:r503:AVERAGE \
        DEF:r504=$DB:r504:AVERAGE \
        DEF:r404=$DB:r404:AVERAGE \
        DEF:r302=$DB:r302:AVERAGE \
        DEF:r401=$DB:r401:AVERAGE \
        DEF:r200=$DB:r200:AVERAGE \
        DEF:r101=$DB:r101:AVERAGE \
        DEF:r202=$DB:r202:AVERAGE \
        DEF:r301=$DB:r301:AVERAGE \
        DEF:r307=$DB:r307:AVERAGE \
        DEF:r403=$DB:r408:AVERAGE \
        LINE1:r500#B00008:r500 \
        LINE1:r502#060105:r502 \
        LINE1:r503#500040:r503 \
        LINE1:r504#C10113:r504 \
        LINE1:r404#FEBD01:r404 \
        LINE1:r302#77E602:r302 \
        LINE1:r401#9E4100:r401 \
        LINE1:r200#0098FA:r200 \
        LINE1:r101#50022A:r101 \
        LINE1:r202#8E3764:r301 \
        LINE1:r301#2400DA:r301 \
        LINE1:r307#6047E2:r307 \
        LINE1:r403#FFFF00:r403  
        #AREA:five_load#FA3C00:One_minute_load \
        #AREA:one_load#F99677:Last_Five_minute_load \
done

#create cron task 
if grep $RUNDIR/$SCRIPT_NAME $CRONTAB;then
        echo "cron task already set"
else
echo "creating cron task..."
echo "  *  *  *  *  *  $RUNDIR/$SCRIPT_NAME" >> $CRONTAB
fi
