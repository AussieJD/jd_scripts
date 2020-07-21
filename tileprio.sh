#!/bin/bash
# initially by zhocchao http://ubuntuforums.org/member.php?u=707997
# revision april 7th 2010 by CBC http://ubuntuforums.org/member.php?u=852454
# allow to perform "tiling" of the not hiddent windows

# usage :
# -------
# tileprio.sh # let the "active" windows get two-third of the width of the screen

# tileprio.sh 1 # keep the width of the "active" windows and set other windows width accordingly

# screen size should be put down there
S_w=1440 # screen width
S_h=900  # screen height
let main_w=2*$S_w/3 # largeur par défaut de la fenêtre principale

strange_shift=15  # set windows revovering possibilities (15 nothing)

## beginning of serious stuff 
dsk=$(wmctrl -d |grep "*"|awk '{print $1}')
anzahl=$(wmctrl -l|awk -v dk="$dsk" '$2==dk {print $1}'| wc -w )
#id active
ak=$(xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)" ) 
akib=$(echo $ak |awk '{print $5}'|sed 's/0x/0x0/g')
# set akib length homogenous with wmctrl -l outpu
while [[ $(echo $akib | wc -m ) != 11 ]] ; 
do
	akib=$(echo $akib |sed 's/0x/0x0/g')
done

# find the "main" (active) windows on the desktop
b=-1
a=$(wmctrl -l|grep $akib |awk '{print $2}')
echo ak $ak akib $akib array $array dsk $dsk a $a b $b
if [ $a -eq $b ] ; then 
	akib=($(wmctrl -l|awk -v dk="$dsk" '$2==dk {print $1}'| grep "0" --max-count=1))
fi

#list not active
array=($(wmctrl -l|grep  -v $akib  |awk -v dk="$dsk" '$2==dk {print $1}'))

#list active and without special _NET_WM_STATE 
# 0 being the active windows
active_win[0]=$akib
wmctrl -i -r $akib -b remove,maximized_horz
wmctrl -i -r $akib -b remove,maximized_vert
num_act=1
for win in ${array[@]}
do
	win_state=$(xprop -notype -id $win _NET_WM_STATE)
	win_hidden=$(echo $win_state | grep HIDDEN)
	echo win $win  win_state $win_state
	if [[ $win_hidden == "" ]] ; then
		active_win[$num_act]=$win
		let num_act=$num_act+1
		echo win:$win state:$win_state
		# remove annoying things to be able to tile properly
		wmctrl -i -r $win -b remove,maximized_horz
		wmctrl -i -r $win -b remove,maximized_vert
		win_state=$(xprop -notype -id $win _NET_WM_STATE)
		echo win:$win state:$win_state
	fi

done
nb_act=$num_act

# define the with basis of the tiling
if [[ $1 == "1" ]] ; then
	# in this case use the width of the main windows as a basis
	let main_w=$(wmctrl -lG | grep $akib | awk -F ' ' '{print $5}')
fi


echo ak $ak akib $akib array $array num_act $num_act 
##minimierte/maximierte einbeziehen
#for wnd in ${array[@]} 
#do
#wmctrl -a $wnd -i 
#wmctrl -r $wnd -i -b remove,maximized_vert,maximized_horz
#done
let second_w=$S_w-$main_w-2*$strange_shift ;

# tile the windows
case "$num_act" in
1)
# wmctrl -r $akib -i -e "0,0,0,$S_w,$S_h";;
wmctrl -i -r $akib -b add,maximized_vert,maximized_horz ;;
2)
let second_init_x=$main_w+$strange_shift ;
# wmctrl -i -r $akib -b toggle,maximized_vert ;
# wmctrl -i -r ${active_win[1]} -b toggle,maximized_vert ;
wmctrl -r $akib -i -e "0,0,0,$main_w,$S_h" ;
wmctrl -r ${active_win[1]} -i -e "0,$second_init_x,0,$second_w,$S_h";;
3)
let second_init_x=$main_w+$strange_shift ;
let second_h=$S_h/2 ;
let second_h=$second_h-3*$strange_shift ;
let third_init_y=$second_h+3*$strange_shift ;
# echo $second_h $third_init_y $
wmctrl -r ${active_win[0]} -i -e "0,0,0,$main_w,$S_h";
wmctrl -r ${active_win[1]} -i -e "0,$second_init_x,0,$second_w,$second_h";
wmctrl -r ${active_win[2]} -i -e "0,$second_init_x,$third_init_y,$second_w,$second_h" ;;
4)
let second_init_x=$main_w+$strange_shift ;
let second_h=$S_h/3 ;
let second_h=$second_h-3*$strange_shift ;
let third_init_y=$second_h+3*$strange_shift+5 ;
let fourth_init_y=2*$second_h+5*$strange_shift ;
wmctrl -r ${active_win[0]} -i -e "0,0,0,$main_w,$S_h";
wmctrl -r ${active_win[1]} -i -e "0,$second_init_x,0,$second_w,$second_h";
wmctrl -r ${active_win[2]} -i -e "0,$second_init_x,$third_init_y,$second_w,$second_h";
wmctrl -r ${active_win[3]} -i -e "0,$second_init_x,$fourth_init_y,$second_w,$second_h" ;;
5)
wmctrl -r $akib -i -e "0,0,0,430,745" ;
wmctrl -r ${active_win[1]} -i -e "0,445,0,395,350";
wmctrl -r ${active_win[2]} -i -e "0,850,0,420,350";
wmctrl -r ${active_win[3]} -i -e "0,445,575,395,370";
wmctrl -r ${active_win[4]} -i -e  "0,850,575,420,370";;
6)
wmctrl -r $akib -i -e "0,0,0,430,350" ;
wmctrl -r ${active_win[1]} -i -e "0,445,0,395,350";
wmctrl -r ${active_win[2]} -i -e "0,850,0,420,350";
wmctrl -r ${active_win[3]} -i -e "0,445,575,395,370";
wmctrl -r ${active_win[4]} -i -e  "0,850,575,420,370";
wmctrl -r ${active_win[5]} -i -e "0,0,445,430,370" ;;
7)
wmctrl -r $akib -i -e "0,0,0,430,245" ;
wmctrl -r ${active_win[1]} -i -e "0,445,0,420,245" ;
wmctrl -r ${active_win[2]} -i -e "0,880,0,395,245";
wmctrl -r ${active_win[3]} -i -e "0,0,300,430,245";
wmctrl -r ${active_win[4]} -i -e "0,445,300,420,245";
wmctrl -r ${active_win[5]} -i -e  "0,880,300,395,245";
wmctrl -r ${active_win[6]} -i -e "0,0,575,1268,190" ;;
8)
wmctrl -r $akib -i -e "0,0,0,430,245" ;
wmctrl -r ${active_win[1]} -i -e "0,445,0,420,245" ;
wmctrl -r ${active_win[2]} -i -e "0,880,0,395,245";
wmctrl -r ${active_win[3]} -i -e "0,0,300,430,245";
wmctrl -r ${active_win[4]} -i -e "0,445,300,420,245";
wmctrl -r ${active_win[5]} -i -e  "0,880,300,395,245";
wmctrl -r ${active_win[6]} -i -e "0,0,575,630,190" ;
wmctrl -r ${active_win[7]} -i -e "0,645,575,630,190" ;;
9)
wmctrl -r $akib -i -e "0,0,0,430,245" ;
wmctrl -r ${active_win[1]} -i -e "0,445,0,420,245" ;
wmctrl -r ${active_win[2]} -i -e "0,880,0,395,245";
wmctrl -r ${active_win[3]} -i -e "0,0,300,430,245";
wmctrl -r ${active_win[4]} -i -e "0,445,300,420,245";
wmctrl -r ${active_win[5]} -i -e  "0,880,300,395,245";
wmctrl -r ${active_win[6]} -i -e "0,0,575,430,190" ;
wmctrl -r ${active_win[7]} -i -e "0,445,575,420,190" ;
wmctrl -r ${active_win[8]} -i -e "0,880,575,395,190" ;;
esac
exit





          





