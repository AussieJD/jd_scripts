##!/usr/bin/ksh
# jon driscoll
#  6-Oct-1998
#
# Scope:	Will create an index HTML page of
#		images in *specified* sub-folders of sunsa.aus
#		the base is http://sunsa.aus = /net/williams/export/local/graphics
#		(sub-folders are specified in williams:/export/local/graphics/graphics.folders)
#
#
#
#
#
#
#################################################
#
# Variables:
#
PAGETITLE='Picture Catalogue'
INDEXNAME=aapicturesindex.html
PAGENAME=aapictures.html
FOLDERBASE="/net/williams/export/local"
WEBBASE="http://sunsa.aus"
DATE=`date +%C`
COUNT=1
#
#
##############################################
#
# START CREATING HTML FILE
##
#<TABLE BORDER COLS=2 WIDTH="100%" >
rm $INDEXNAME

( echo ' 
<HEAD>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
<META NAME="Author" CONTENT="Jon Driscoll">
<META NAME=GENERATOR CONTENT=>
<TITLE>Picture Index by JD</TITLE>
<HEAD>
<H1>
Catalogue of images for http://sunsa.aus.. </H1>
<H3> last updated  '$DATE' </H3>
<H2> Created using williams:/export/local/graphics/generate.pics.html.pages</H2>
</HEAD>

<BODY>
<BR>
<H3> Folders containing pictures...</H3> 
'	) >> $INDEXNAME
##############################################
for i in `cat $FOLDERBASE/graphics/graphics.folders`
do
#echo $i
##echo http://sunsa.aus/$DIR1$DIR2
(echo '<H2><A HREF="' $WEBBASE/$i/$PAGENAME'" >' $i'</A><BR></H2>' ) >> $INDEXNAME
done
#
#
##############################################
#
# FINISH CREATING HTML FILE
#
( echo '

</TABLE>
&nbsp;
</BODY>
</HTML>
'       ) >> $INDEXNAME


chmod 755 $INDEXNAME

##############################################
#
# Create a pics page in eac folder listed in grapgics.folders
#
  for d in `cat $FOLDERBASE/graphics/graphics.folders`
	do
	cd $FOLDERBASE/$d
	$FOLDERBASE/graphics/make.pics.pages
  done
#
