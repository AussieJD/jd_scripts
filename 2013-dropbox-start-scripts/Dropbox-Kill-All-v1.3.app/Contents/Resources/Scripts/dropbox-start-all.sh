#!/bin/bash
HOME1=$HOME
dropboxes=".dropbox-alt-sarah .dropbox-alt-pickthree .dropbox-alt-christine"
for dropbox in $dropboxes
 do
        if ! [ -d "$HOME1/$dropbox" ]
         then
                mkdir "$HOME1/$dropbox" 2> /dev/null
        fi
HOME=$HOME1/$dropbox /Applications/Dropbox.app/Contents/MacOS/Dropbox&
sleep 10
done
