#!/bin/sh
#sed -e "/Australia\/South/ s//Australia\/Adelaide/"
cat $*|awk -F: '{
	if ($1 ~ "SEQUENCE") {
		printf($0"\nCLASS:CONFIDENTIAL\
		getline
	}
		print($0)
     }'	