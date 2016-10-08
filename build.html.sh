#!/bin/bash

for graph in `ls /var/www/html/stats | grep "hour"`;do
	service=$(echo $graph | awk -F "-" '{print $1}')
	echo "<a href="$service.html">" >> /var/www/html/stats/index.html
	echo "<img src="$graph">" >> /var/www/html/stats/index.html
	echo "</a>" >> /var/www/html/stats/index.html
 	for graphs in `ls /var/www/html/stats/ | grep "$service"`;do
		echo "<img src="$graphs">" >> /var/www/html/stats/$service.html
	done
done
