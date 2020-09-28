OUTFILE=$HOME/WWW/docs/se/lateloans.html
TMPFILE=/tmp/`basename $0`.$$
PREAMBLE=$HOME/bin/lateloans.pre
POSTAMBLE=$HOME/bin/lateloans.post
#
#
#
cat > $TMPFILE
START=`egrep -n "notify.spl" $TMPFILE | cut -d: -f1`
END=`egrep -n "shipped out" $TMPFILE | cut -d: -f1`
( cat $PREAMBLE
cat $TMPFILE | tail +$START
cat $POSTAMBLE ) > $OUTFILE
rm $TMPFILE
