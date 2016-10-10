#!/bin/bash

for graph in `ls /var/www/html/stats | grep "hour"`;do
	service=$(echo $graph | awk -F "-" '{print $1}')
	echo "<body bgcolor="#708090"> </body>" >> /var/www/html/stats/index.html
	echo "<div align="center">" >> /var/www/html/stats/index.html
	echo "<a href="$service.html">" >> /var/www/html/stats/index.html
	echo "<img src="$graph">" >> /var/www/html/stats/index.html
	echo "</a>" >> /var/www/html/stats/index.html
	echo "<br>" >> /var/www/html/stats/index.html
 	for graphs in `ls /var/www/html/stats/ | grep "$service"`;do
		echo "<img src="$graphs">" >> /var/www/html/stats/$service.html
		#echo "<br>" >> /var/www/html/stats/index.html
	done
	echo "</div>" >> /var/www/html/stats/index.html
done
