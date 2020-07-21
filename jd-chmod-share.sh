#!/bin/bash
#
# Usage:	recursively change permissions and group ownership
#		of all files OWNED by user to predefined values
#
# Variables
USER_ID=jd51229
MODE=770
GROUP=2011
#
# Script
find . -user $USER_ID -type f -exec chmod $MODE {} \;
find . -user $USER_ID -type d -exec chmod $MODE {} \;
find . -user $USER_ID -type d -exec chgrp $GROUP {} \;
find . -user $USER_ID -type f -exec chgrp $GROUP {} \;


# The End!
