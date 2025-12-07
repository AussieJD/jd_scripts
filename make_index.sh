#!/bin/sh
#
# Usage: Create an index.html for a directory of photos
#		with only a certain no. of photos per page
#

umask 022

title=$*
date=`date "+%e %B %Y"`
now=`date "+%e %B %Y - %H:%M "`

INDEXMODE=0
col=1
count=1

# sub to create a single table cell
# (this sub gets called later in the script)
makecell()
{
	pic=$1
	rotate=$2
	subtitle=$3
echo "Processing image, $pic, rotate=$rotate, Comment=$subtitle ...." >> make_index.log

	if [ ${rotate} != "NoRotate" ]; then

echo "..rotating original image, removing old thumbnails...." >> make_index.log
	 [ ${rotate} = "right" ] && convert -rotate 90 ${pic} ${pic}
	 [ ${rotate} = "left" ] && convert -rotate 270 ${pic} ${pic}
	 [ -f thumb600/${pic} ] && /usr/bin/rm thumb600/${pic}
	fi

	if [ -f ${pic} -o -f thumb600/${pic} ]; then
	size=`identify -ping ${pic}| awk '{ print $2 }'`
	vsize=`identify -ping ${pic}| awk '{ print $2 }'|awk -Fx '{ print $2}'`
	hsize=`identify -ping ${pic}| awk '{ print $2 }'|awk -Fx '{ print $1}'`

echo "..size of $pic = $size.... " >> make_index.log
	ratio600=`(echo "scale=10;(600)/($vsize)" | bc)`

echo "..generate thumb600 images (if they don't already exist!)...." >> make_index.log
echo "..ratio for 600=$ratio600...." >> make_index.log
  	  [ ! -f thumb600/${pic} ] && imscale -scale ${ratio600} ${pic} thumb600/${pic}
  	  [ ${col} -eq 1 ] && echo "<TR VALIGN=top>" >> index.html

echo "..insert HTML code into index.dat" >> make_index.log
 	  echo "
	    <td><a HREF=\"JavaScript:Disp('thumb600/${pic}','${subtitle}','${hsize}','${vsize}');\">
	    <IMG BORDER=0 SRC=\"thumb600/${pic}\" HEIGHT=150 ></A><BR><B><FONT SIZE=-1>${subtitle} 
           <br><a target=_blank href="${pic}">Original ($size)
            </FONT></B></TD>" >> index.html
  	  count=`expr ${count} + 1`
  	  col=`expr ${col} + 1`
  	  if [ ${col} -gt 4 ]; then
  		col=1
  		echo "</TR>" >> index.html
  	  fi
	else
	  echo "** Unable to find ${pic} or thumb600/${pic}.. ignoring"
	fi
}


# Start Main part of script here....

echo "Running make_index.sh - ${now}" >> make_index.log

# create the directory for the thumb600 thumbnails
echo "Verifying dirs for thumbnails etc...." >> make_index.log
if [ ! -d thumb600 ] ;then mkdir thumb600;fi 

# write preamble to the start of the index.html file
/bin/cat >index.html <<!ENDPreamble 
<HTML>
<HEAD>
<TITLE>$title</TITLE>
<SCRIPT LANGUAGE="JavaScript">

BaseWidth=800;
NewWindowWidth=BaseWidth-50;
NewWindowHeight=Math.floor(BaseWidth*0.80)-50;
MaxWidth=NewWindowWidth-30;
MaxHeight=NewWindowHeight-10;


function Disp(FileName,Title,Wo,Ho){
  Ratio=Math.min(MaxWidth/Wo,MaxHeight/Ho);
    if(Ratio>1)Ratio=1;
  W=Math.floor(Wo*Ratio);
  H=Math.floor(Ho*Ratio);
  mW=window.open("","NewWindow","width="+NewWindowWidth+",Height="+NewWindowHeight);
  mW.focus();
  mW.document.open();
  mW.document.write("<TITLE>"+FileName+"</TITLE>");
  mW.document.write("<BODY BGCOLOR='GoldenRod'>");
  mW.document.write("<CENTER><FONT COLOR=#8080ff SIZE=+1>"+Title+"</FONT></CENTER>");
  mW.document.write("<TABLE BORDER=0 HEIGHT="+MaxHeight+" CELLSPACING=0>");
  mW.document.write("<TR><TD ALIGN=CENTER VLAIGN=MIDDLE>");
  mW.document.write("<A HREF='JavaScript:window.close();'>");
  mW.document.write("<IMG SRC="+FileName+" HEIGHT=450 BORDER=0>");
  mW.document.write("</A><BR><CENTER><I>Click on picture to close window</I></CENTER>");
  mW.document.write("</A><BR><CENTER><I>Hold Shift + Click on picture to save image</I></CENTER>");
  mW.document.write("</TABLE>");
  mW.document.close();
}

</SCRIPT>
<!--  mW.document.write("<IMG SRC="+FileName+" WIDTH="+W+" HEIGHT="+H+" BORDER=0>");-->
</HEAD>

<BODY BGCOLOR="goldenrod">
<BR>

<CENTER>
<B><I><FONT COLOR=:#8080ff" SIZE=7>$title</FONT></I></B>
</CENTER>

<BR><P><BR><HR>

<CENTER><I>Click on picture to enlarge</I></CENTER><BR>
<!TABLE CELLPADDING=5>
<table border="0" cellpadding=5 cellspacing=0 width=130><tr>

!ENDPreamble

# finished initial write to index.html file

# If index.dat exists, use it to add comments to images
# (and also add any new images to the bottom of it)
# If it doesn't exist, add a list of images, with a field for comments
#!start
if [ $INDEXMODE = 0 ]; then

echo "index.dat does not exist - creating....">> make_index.log

  # add instruction line
 	echo "### To rotate image: replace 'NoRotate' with 'left' or 'right'">> index.dat
 	echo "### To add comments to web page: replace '1. pic-name' with '1. comment'">> index.dat
  # generate a line for each
#!!start
  for pic in `ls *jpg *gif *.JPG *.GIF`
  do
  	echo "${pic}\tNoRotate\t${count}. ${pic}" >> index.dat
# use subshell defined above that asks for pic name and subtitle
#  	makecell ${pic} NoRotate "${count}. ${pic}"
  	makecell ${pic} NoRotate "$subtitle"

  done


#!start
else

echo "index.dat exists - reading comments and rotation instructions...." >> make_index.log

#!!start
  for pic in `ls *jpg *gif *.JPG *.GIF`
   do
	grep $pic index.dat > /dev/null 2>&1
	if [ $? -eq 1 ]
	 then

		echo "...adding new images to index.dat...." >> make_index.log
		count2=`cat index.dat | wc -l`
#		echo "${pic}\tNoRotate\t${count2}. ${pic}" >> index.dat
		echo "${pic}\tNoRotate\t comment" >> index.dat
	fi
   done
#!!start
  for indexpic in `cat index.dat | grep -v "###" |awk '{ print $1 }'`
   do
#        echo $indexpic = from file
        ls | grep $indexpic
        if [ $? -eq 1 ]
          then
                echo " $indexpic is in index.dat, but does not ACTUALLY exist = remove from index.dat"
                cat index.dat | grep -v $indexpic > /tmp/index.dat.new
                cp /tmp/index.dat.new index.dat
        fi
  done
#!!start
  cat index.dat | grep -v "###" | while read pic rotate subtitle
  do
	if [ $pic = "#title" ]; then
		echo "</TR>\n<TR><TD COLSPAN=4><FONT COLOR="#8080ff"> \ 
		<B>${subtitle}</B></FONT></TD></TR>" >> index.html
		col=1
	else
		makecell ${pic} ${rotate} "${subtitle}"
	 if [ $rotate != "NoRotate" ]; then

echo "Resetting rotation entry after rotating images...." >> make_index.log
	  cat index.dat | grep -v ${pic} > /tmp/index.dat1
	  echo "${pic}\tNoRotate\t${count}. ${subtitle}" >> /tmp/index.dat1
	  sort /tmp/index.dat1 > /tmp/index.dat2
	  cat /tmp/index.dat2 > index.dat 
	 fi	  
	fi
  done


fi
#!end
  
  [ ${col} -ne 1 ] && echo "</TR>" >> index.html
/bin/cat >>index.html <<!Footer
</TABLE>
<P><A HREF="../index.html">[Back]</A></P>


<HR>
<P><I>Updated by:</I><BR>
<A HREF="mailto:jon.driscoll@Aus.Sun.COM">Jon Driscoll</A> (jon.driscoll@Aus.Sun.COM)<BR>
Last Modified: ${date}<BR>
</BODY>
</HTML>
!Footer
echo "Finished running make_index.sh - ${now}" >> make_index.log
echo "-----------------------------------------------------------" >> make_index.log
	


