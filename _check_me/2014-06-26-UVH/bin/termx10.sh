#!/bin/bash
#
PWD1=`pwd`
gnome-terminal --geometry 100x10+50+0 --window-with-profile=jd1 --hide-menubar --working-directory=$PWD1&
gnome-terminal --geometry 100x10+50+180 --hide-menubar --working-directory=$PWD1 &
gnome-terminal --geometry 100x10+50+360  --hide-menubar --working-directory=$PWD1 &
gnome-terminal --geometry 100x10+50+540  --hide-menubar --working-directory=$PWD1 &
#gnome-terminal --geometry 100x10+50+720  --hide-menubar --working-directory=$PWD1 &
#gnome-terminal --geometry 100x10+50+900  --hide-menubar --working-directory=$PWD1 &
#
gnome-terminal --geometry 100x10+880+0  --hide-menubar --working-directory=$PWD1 &
gnome-terminal --geometry 100x10+880+180  --hide-menubar --working-directory=$PWD1 &
gnome-terminal --geometry 100x10+880+360  --hide-menubar --working-directory=$PWD1 &
#gnome-terminal --geometry 100x10+880+540  --hide-menubar --working-directory=$PWD1 &
#gnome-terminal --geometry 100x10+880+720  --hide-menubar --working-directory=$PWD1 &
#gnome-terminal --geometry 100x10+880+900  --hide-menubar --working-directory=$PWD1 &
