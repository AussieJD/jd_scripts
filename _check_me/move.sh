clear
DATE=`date +%C`
INDEXNAME=picsindex.html
MAX=17
COUNT=1
COUNT2=0
COUNT3=10
BASE=/home/staff/jon/pics
PICSTORE=$BASE/pics1
#HTTPREF=file:///D|/jd_c/Images/rotation/private
HTTPREF=http://sunsa.aus/se/jon/pics
ls -1 $PICSTORE > $BASE/templist.out
LINES=`cat $BASE/templist.out |wc -l`
echo "\n Enter number of images per page...> \c"
read ROWSPERPAGE
rm -r $BASE/bin*
#
### Start creating the index.html file
#
rm $BASE/$INDEXNAME
( echo ' 
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
<META NAME="Author" CONTENT="Jon Driscoll">
<META NAME=GENERATOR CONTENT=>
<TITLE>Picture Index by JD</TITLE>
<HEAD>
<H1>
Catalogue of images for $PICSTORE.. </H1>
<H3> last updated  '$DATE' </H3>
</HEAD>
<BODY>
<BR>
<H3> HTML files containing pictures...</H3> 
'       ) >> $BASE/$INDEXNAME
#
### Pause the creation of the index.html file
#

while [ $COUNT -le $LINES ] 
  do
   COUNT4=`expr $COUNT3 + 1`
   COUNT5=`expr $COUNT3 - 1`
   ### Start creating the pages of pics
   #	

   ( echo '
   <HEAD>
   <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
   <META NAME="Author" CONTENT="Jon Driscoll">
   <META NAME="GENERATOR" CONTENT="Mozilla/4.04 [en] (Win95; I) [Netscape]">
   <TITLE>Picture Index by JD bin$COUNT3</TITLE>
   <HEAD>
   <H1>
   Catalogue of images from ... '$DIR'</H1>
   <H3> last updated  '$DATE' </H3>
   <H2> Created using /home/staff/jon/pics/move.sh</H2>
   </HEAD>
   <BODY>
   <A HREF="'$HTTPREF/$INDEXNAME'" >' Index '</A><H3>   </H3>
   <A HREF="' $HTTPREF/bin$COUNT5.html'" >' Previous '</A><H3>   </H3>
   <A HREF="' $HTTPREF/bin$COUNT4.html'" >' Next'</A><BR>
   <BR>
   <TABLE BORDER COLS=5 WIDTH="100%" >
   <BR>
   <H3> Pictures in this pages ...</H3>
   '       ) >> $BASE/bin$COUNT3.html
   #
   ###
	INCREMENT3=0
	INCREMENT2=0
	INCREMENT=1
 while [ $INCREMENT3 -le 3 ]
  do	INCREMENT3='expr $INCREMENT3 + 1'
 while [ $INCREMENT2 -le 5 ]
  do 	INCREMENT2='expr $INCREMENT2 + 1'
	( echo ' <TR> ' ) >> $BASE/bin$COUNT3.html
  while [ $INCREMENT -le $ROWSPERPAGE ]	
    do
	STEPS=`expr $COUNT2 \* $ROWSPERPAGE`
	LINENUMBER=`expr $INCREMENT \+ $STEPS`
	INCREMENT=`expr $INCREMENT + 1`
	echo "stepping $LINENUMBER lines into the file, writing to file bin$COUNT3"
#
### Put the relevant filename link into the bin.html
#
	FILETOUSE=`sed -n "$LINENUMBER p" $BASE/templist.out `
	(echo ' <TD><A HREF="' $HTTPREF/pics1/$FILETOUSE'" ><IMG SRC="'$HTTPREF/pics1/${FILETOUSE}'" NOSAVE WIDTH=100 ></TD> ' ) >> $BASE/bin$COUNT3.html
#
### end adding file to page
#

  done
	(echo ' </TR> ' ) >> $BASE/bin$COUNT3.html
	INCREMENT2=`expr $INCREMENT2 + 1`
 done
 done
   #
   ### Finish writing the pics page
   #
   ( echo '
   
   </TABLE>
   &nbsp;
   <A HREF="' $HTTPREF/$INDEXNAME'" >' Index '</A><H3>   </H3>
   <A HREF="' $HTTPREF/bin$COUNT5.html'" >' Previous '</A><H3>   </H3>
   <A HREF="' $HTTPREF/bin$COUNT4.html'" >' Next'</A><BR>
   </BODY>
   </HTML>
   '       ) >> $BASE/bin$COUNT3.html
   chmod 755 $BASE/bin$COUNT3.html
   #
   ### end of finish creating pics page
   #
   ### add a reference to the page into the index
   #
   (echo '<H2><A HREF="' $HTTPREF/bin$COUNT3.html'" >' bin$COUNT3.html'</A><BR></H2>' ) >> $BASE/$INDEXNAME
   (echo '<H4> Filename: '${FILETOUSE}' </H4>' ) >> $BASE/$INDEXNAME
   #
   ### end add a reference to the page into the index
   #
   COUNT=`expr $COUNT + $ROWSPERPAGE`
   COUNT2=`expr $COUNT2 + 1`
   COUNT3=`expr $COUNT2 + 10`
  done
#
### Resume creating the index file
#
( echo '

</TABLE>
&nbsp;
</BODY>
</HTML>
'       ) >> $INDEXNAME
chmod 775 $INDEXNAME
#
###
#
#
# The End!
