
#
# Usage: Create an index.html for a directory of photos
#		with only a certain no. of photos per page
#

umask 022

debug=n

title=$*
date=`date "+%e %B %Y"`
now=`date "+%e %B %Y - %H:%M "`
numberimages=`ls | grep -i ".jpg"| grep -v ".dat"|wc -l`
echo numberimages=$numberimages
remaining=$numberimages
picsperrow=2					# images per table row
maxrows=4					# max allowable rows of pics
picsperpage=$(($picsperrow*$maxrows))		# counter to tell when to start a new page
echo picsperpage=$picsperpage
maxpages=$(($numberimages/$picsperpage+1))	# max pages that will be created
echo maxpages=$maxpages
col=1						# which picture col are we in (see picsperrow above)
piccount=0					# which picture is the script up to on current page
pagecount=1					# number of the current page
page=index					# page name *base*
pagetag=html					# page file tag
log=make_index2.log



########################################################
# Start Main part of script here....

echo "-------\nRunning make_index2.sh - ${now}" >> $log

# do thumbnail folders exist (if no, make one!)

[ ! -d thumb150 ] && mkdir thumb150
[ ! -d thumb600 ] && mkdir thumb600

# remove existing html files

rm *html
ln -s index1.html index.html

# copy the basic image for page to current directory

[ ! -f start_image.jpg ] && cp /home/jd51229/jdnet/pics/start_image.jpg .

# count no. of images in the current directory

echo "number images = $numberimages, \c" >> $log

# Echo progress to output (screen?)

echo "Images remaining: \c"

# and now step through them 
echo "cycling through images, and building web pages... \c" >> $log

for pic in `ls | grep -i ".jpg"| grep -v ".dat"`
  do

	# we will be creating a series of web pages each with 5 images
	# then linking to any subsequent pages
	# each *row* in a table will contain an image thumbnail

	# increment pic counter

	piccount=`expr $piccount + 1`
	echo "pic=$piccount,\c" >> $log

	# if a *pic.dat* info file does not exist, create one with basic info

	[ ! -f ${pic}.dat ] && echo "$pic\nNoRotate\nThe Comment" > ${pic}.dat;

	# if piccount = 1 then assume we are starting a new html page
	# and add header, script, and master *large* image.
	# the html will be left open, and later added to  


	if [ $piccount = "1" ]
  	 then 
	echo "
	<HTML>
	<!-- %%NOBANNER%% -->
	<!-- entry for topcities banners -->
  	<TITLE>$title</TITLE>
  	<script language=\"JavaScript\">
  	<!--
  	var rollover = new MakeArray(1);
  	rollover[0].src = \"/widgets/dot_clear.gif\"
  	rollover[1].src = \"/widgets/diamond.gif\"
  	function MakeArray(n) {
  	this.length = n
  	for (var i = 0; i<=n; i++) {
  	this[i] = new Image()
  	}
  	 return this
  	}
  	function msover(num,id) {
  	document [id].src = rollover[num].src
  	}
  	function msout(num,id) {
  	document [id].src = rollover[num].src
  	}
  	//-->
  	</script>
  	</HEAD>
  	<BODY BGCOLOR=\"goldenrod\">
  	<BR>
  	<CENTER>
  	<B><I><FONT COLOR=:#8080ff SIZE=7>$title</FONT></I></B>
  	<br><font size=+1>
	you are on page $pagecount of $maxpages <br>
	" >> ${page}${pagecount}.$pagetag

	count=1
	while [ $count -le $maxpages ];do
		echo "<a href=\"$page$count.$pagetag\">$count</a>&nbsp " >> ${page}${pagecount}.$pagetag
		count=$(($count+1))
	done

	echo "
  	</font><br>
  	<table border=\"2\" cellpadding=5 cellspacing=0 width=\"900\"> <tr> <TD -- new cell ---  ROWSPAN=\"$(($maxrows + 1))\" >
  	  <IMG NAME=\"master\" BORDER=\"1\" VSPACE=\"10\" HSPACE=\"10\" HEIGHT=\"400\" SRC=\"start_image.jpg\">
  	  <IMG NAME=\"width\" WIDTH=\"600\" HEIGHT=\"1\" SRC=\"start_image.jpg\">
  	  </TD>
  	 </TR>
  	" >> ${page}${pagecount}.$pagetag
	pagefinished=no
  	fi	

	# start to query the status of the current *pic*
	# so, check its .dat file for information

	# is the image set for rotation?

  	rotate=`cat ${pic}.dat|head -2|tail -1`

	# 	what is the comment to go under the image on the html page?

  	subtitle=`cat ${pic}.dat|tail -1`

	# run image processing part of script 

	echo "Processing image, $pic, rotate=$rotate, Comment=$subtitle ...." >> $log

	# If the tag *rotate* is set, process the rotate, and remove any existing thumbnails

        if [ ${rotate} != "NoRotate" ]; then
         echo "..rotating original image, removing old thumbnails...." >> $log
         [ ${rotate} = "right" ] && convert -rotate 90 ${pic} ${pic}
         [ ${rotate} = "left" ] && convert -rotate 270 ${pic} ${pic}
         [ -f thumb150/${pic} ] && /usr/bin/rm thumb150/${pic}
         [ -f thumb600/${pic} ] && /usr/bin/rm thumb600/${pic}
	echo "$pic\nNoRotate\n$subtitle" > ${pic}.dat
        fi

	# If *pic* exists, then

       if [ -f ${pic} ]; then

        # discover the dimensions of *pic* using identify (part of image magik)

        size=`identify -ping $pic| awk '{ print $2 }'`
        vsize=`identify -ping $pic| awk '{ print $2 }'|awk -Fx '{ print $2}'`
        vsize=`identify -ping $pic| awk '{ print $2 }'|awk -Fx '{ print $1}'`
        echo "..size of $pic = $size.... " >> $log

        # calculate what ratio to apply to *pic* to create a 600 pixel wide thumbnail

        ratio600=`(echo "scale=10;(600)/($vsize)" | bc)`
        echo "..generate thumb600 images (if they don't already exist!)...." >> $log
        echo "..ratio for 600=$ratio600...." >> $log

        # calculate what ratio to apply to *pic* to create a 150 pixel wide thumbnail

        ratio150=`(echo "scale=10;(150)/($vsize)" | bc)`
        echo "..generate thumb150 images (if they don't already exist!)...." >> $log
        echo "..ratio for 150=$ratio150...." >> $log

        # if thumbnails do not already exist, create them....

        [ ! -f thumb150/$pic ] && imscale -scale $ratio150 $pic thumb150/$pic
        [ ! -f thumb600/$pic ] && imscale -scale $ratio600 $pic thumb600/$pic

        # add relevant HTML code into the .html file being created

        echo "..insert HTML code into $page$pagecount.$pagetag" >> $log

        if [ $col = "1" ] ; then echo "<TR>" >> ${page}${pagecount}.$pagetag ;col=2;else col=1;fi
	echo "
	<TD>
         <A target=_blank onMouseOver=\"document.images[0].src='thumb600/${pic}'\"
          onMouseOut=\"document.images[0].src='start_image.jpg'\"
          HREF=\"$pic\">
         <IMG width=150 src=\"thumb150/$pic\">
         </A><BR><B><FONT SIZE=-1>
          $subtitle <br>
	" >> ${page}${pagecount}.$pagetag

        else

          echo "** Unable to find $pic .. ignoring"

       fi

#  	  <TD -- new cell ---  ROWSPAN=\"$maxrows\" >
#  	  <IMG NAME=\"master\" BORDER=\"1\" VSPACE=\"10\" HSPACE=\"10\" HEIGHT=\"400\" SRC=\"start_image.jpg\">
#  	  </TD>
#  	 </TR>

	# if we are at our fifth image for the page, finish the page html
	# increment the page count and reset the row count to start a new page!

  	if [ $piccount = "$picsperpage" ]
  	then
  	
	echo "
  	</TABLE>
  	<P><A HREF=\"..\">[Back to Master Index Page]</A></P>
  	<HR>
  	<P><I>Updated by:</I><BR>
  	<A HREF=\"mailto:jonathon.driscoll@Sun.COM\">Jon Driscoll</A> (jonathon.driscoll@Sun.COM)<BR>
  	Last Modified: ${date}<BR>
  	</BODY>
  	</HTML>
	" >> ${page}${pagecount}.$pagetag 
  	pagecount=`expr $pagecount + 1`
  	piccount=0
	pagefinished=yes
  	fi

# beep after each image is processed

remaining=$(($remaining - 1))
echo '\07\c'
echo "$remaining \c"

done

if [ $pagefinished = "no" ];then
	echo "
        </TABLE>
        <P><A HREF=\"..\">[Back to Master Index Page]</A></P>
        <HR>
        <P><I>Updated by:</I><BR>
        <A HREF=\"mailto:jonathon.driscoll@Sun.COM\">Jon Driscoll</A> (jonathon.driscoll@Sun.COM)<BR>
        Last Modified: ${date}<BR>
        </BODY>
        </HTML>
        " >> ${page}${pagecount}.$pagetag
fi

# beep tree times when finished!

echo '\07\07\07\c'
echo " Finished processing! \n"

echo "Finished running make_index2.sh - ${now}" >> $log
echo "-----------------------------------------------------------" >> $log
#
