#!/bin/bash

start_time=$(date +%s.%N)

# Transfer files in parallel using rsync (simple script)
# MAXCONN: maximum number "rsync" processes running at the same time:
MAXCONN=6

# Source and destination base paths. (not need to end with "/")
SRC_BASE=/home/user/public_html/images
DST_BASE=user@hostname.domain.local:/home/user/public_html/images
RSYNC_OPTS="-ah --partial"

# Main loop:
for FULLDIR in $SRC_BASE/*; do
    NUMRSYNC=`ps -Ao comm | grep '^'rsync'$' | wc -l `
    while [ $NUMRSYNC -ge $MAXCONN ]; do
        NUMRSYNC=`ps -Ao comm | grep '^'rsync'$' | wc -l `
        sleep 1
    done
    DIR=`basename $FULLDIR`
    echo "Start: " $DIR
    ionice -c2 -n5 rsync $RSYNC_OPTS $SRC_BASE/${DIR}/ $DST_BASE/${DIR}/ &
    # rsync $RSYNC_OPTS $SRC_BASE/${DIR}/ $DST_BASE/${DIR}/ &
    sleep 5
done

execution_time=$(echo "$(date +%s.%N) - $start" | bc)
printf "Done. Execution time: %.6f seconds\n" $execution_time


# The End!
