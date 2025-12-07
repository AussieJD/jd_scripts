#!/bin/bash
HOME1=$HOME
HOME2=$HOME1/Dropbox-Others
#dropboxes=".dropbox-alt-sarah .dropbox-alt-pickthree .dropbox-alt-christine .dropbox-alt-adelaidebiomedical"
dropboxes=".dropbox-alt-sarah .dropbox-alt-pickthree .dropbox-alt-christine"
for dropbox in $dropboxes
 do
        if ! [ -d "$HOME2/$dropbox" ]
         then
                mkdir "$HOME2$dropbox" 2> /dev/null
        fi
#HOME=$HOME1/$dropbox /Applications/Dropbox.app/Contents/MacOS/Dropbox&
#HOME=$HOME1/$dropbox $HOME1/Applications/Dropbox.app/Contents/MacOS/Dropbox&

HOME=$HOME2/$dropbox /Applications/Dropbox.app/Contents/MacOS/Dropbox&

sleep 10
done
