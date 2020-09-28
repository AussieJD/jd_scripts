ROWSPERPAGE=5
MAX=17
COUNT=1
COUNT2=0
COUNT3=10
BASE=/home/staff/jon/pics
ls -1 $BASE/pics1 > $BASE/templist.out
LINES=`cat $BASE/templist.out |wc -l`
rm $BASE/bin*
while [ $COUNT -le $LINES ] 
  do
   ### Start creating the pages of pics
   #	
   rm $BASE/bin$COUNT3.html

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
   <H2> Created using /home/staff/jon/pics/move2.sh</H2>
   </HEAD>
   <BODY>
   <BR>
   '       ) >> $BASE/bin$COUNT3.html
   #
   ###
	INCREMENT=1
	while [ $INCREMENT -le $ROWSPERPAGE ]	
	  do
		STEPS=`expr $COUNT2 \* $ROWSPERPAGE`
		LINENUMBER=`expr $INCREMENT \+ $STEPS`
		INCREMENT=`expr $INCREMENT + 1`
		echo "stepping $LINENUMBER lines into the file, writing to file bin$COUNT3"
		#
		### Put the relevant filename link into the bin.html
		#
(       echo '
<TABLE BORDER COLS=2 WIDTH="50%" >
<BR>
<H3> Pictures in this pages ...</H3>

' ) >> $BASE/bin$COUNT3.html

(       echo '
<TR>
<TD><IMG SRC="'${j}'" NOSAVE WIDTH=50%></TD>
<TD>'${j}'<BR><A HREF="./'${j}'">Click here for actual image</A></TD>
</TR>
' ) >> $BASE/bin$COUNT3.html


#		sed -n "$LINENUMBER p" $BASE/templist.out >> $BASE/bin$COUNT3
#		FILETOUSE=`sed -n "$LINENUMBER p" $BASE/templist.out `
#		cp $BASE/pics.store/$FILETOUSE $BASE/bin$COUNT3
#		sleep 1
	  done
   #
   ### Finish writing the pics page
   #
   ( echo '
   
   </TABLE>
   &nbsp;
   </BODY>
   </HTML>
   '       ) >> $BASE/bin$COUNT3.html
   chmod 755 $BASE/bin$COUNT3.html
   #
   ### end of finish creating pics page
   #
   COUNT=`expr $COUNT + $ROWSPERPAGE`
   COUNT2=`expr $COUNT2 + 1`
   COUNT3=`expr $COUNT2 + 10`
  done
