#!/bin/bash

CEPH=/usr/bin/ceph
AWK=/usr/bin/awk
SORT=/usr/bin/sort
HEAD=/usr/bin/head
DATE=/bin/date
SED=/bin/sed
GREP=/bin/grep
PYTHON=/usr/bin/python3

TIMENOW=$(date +"%s") ;
#Days to go back to scrub when it's healthy
TIMELIMIT=864000;
#Go back 10 days to scrub to be proactive
LIMIT_WHEN_HEALTH_OK=50;

#number of PG_NOT_DEEP_SCRUBBED
PG_NOT_DEEP_SCRUBBED="$($CEPH health detail|grep 'PG_NOT_DEEP_SCRUBBED'|egrep -oh '[0-9]+')";

#number of PG_NOT_SCRUBBED
PG_NOT_SCRUBBED="$($CEPH health detail|grep 'PG_NOT_SCRUBBED'|egrep -oh '[0-9]+')";

#If the cluster is behind
if [ ! -z "$PG_NOT_SCRUBBED" ] 
then
 $CEPH pg dump pgs 2>/dev/null | \
        $AWK '/^[0-9]+\.[0-9a-z]+/ { if($12 == "active+clean") {  print $1,$21 ; }; }' | \
        while read line; do set $line; echo $1 $($DATE -d "$2" +%s); done | \
        $SORT -n -k2 | \
        $HEAD -n $PG_NOT_SCRUBBED |awk {'print $1'}| while read pg; do ceph pg scrub $pg; sleep 3; done;

else

 $CEPH pg dump pgs 2>/dev/null | \
        $AWK '/^[0-9]+\.[0-9a-z]+/ { if($12 == "active+clean") {  print $1,$21 ; }; }' | \
        while read line; do set $line; time_stamp=$($DATE -d "$2" +%s); time_diff=$(($TIMENOW - $time_stamp - $TIMELIMIT)); echo "$1  $2  $time_stamp  $time_diff" ; done | \
        $SORT -n -k3 | $HEAD -n $LIMIT_WHEN_HEALTH_OK | \
        awk '{if($4 > 0){print $1}}'| $HEAD -n 30|while read pg; do ceph pg scrub $pg; sleep 3; done;



fi



if [ ! -z "$PG_NOT_DEEP_SCRUBBED" ]
then
 $CEPH pg dump pgs 2>/dev/null | \
        $AWK '/^[0-9]+\.[0-9a-z]+/ { if($12 == "active+clean") {  print $1,$23 ; }; }' | \
        while read line; do set $line; echo $1 $($DATE -d "$2" +%s); done | \
        $SORT -n -k2 | \
        $HEAD -n $PG_NOT_DEEP_SCRUBBED |awk {'print $1'}| while read pg; do ceph pg deep-scrub $pg; sleep 3; done;
else

 $CEPH pg dump pgs 2>/dev/null | \
        $AWK '/^[0-9]+\.[0-9a-z]+/ { if($12 == "active+clean") {  print $1,$23 ; }; }' | \
        while read line; do set $line; time_stamp=$($DATE -d "$2" +%s); time_diff=$(($TIMENOW - $time_stamp - $TIMELIMIT)); echo "$1  $2  $time_stamp  $time_diff" ; done | \
        $SORT -n -k3 | $HEAD -n $LIMIT_WHEN_HEALTH_OK | \
        awk '{if($4 > 0){print $1}}'| $HEAD -n 30|while read pg; do ceph pg deep-scrub $pg; sleep 3; done;

fi

