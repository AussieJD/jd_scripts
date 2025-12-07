#!/bin/bash
HOME1=$HOME
dropboxes=".dropbox .dropbox-alt-sarah .dropbox-alt-pickthree .dropbox-alt-christine"
for dropbox in $dropboxes
 do
        if ! [ -d "$HOME1/$dropbox" ]
         then
                mkdir "$HOME1/$dropbox" 2> /dev/null
        fi
echo "Just finished $dropbox"
#HOME=$HOME1/$dropbox /Applications/Dropbox.app/Contents/MacOS/Dropbox &
done
