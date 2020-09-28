TMP0=/tmp/part0
TMP1=/tmp/part1
FILE=/tmp/output4
TMP2=/tmp/part2
TMP3=/tmp/part3
TMP4=/tmp/part4
TMP5=/tmp/part5
TMP6=/tmp/part6
cut -c 2-17 $FILE > $TMP0
cut -c 19-19 $FILE > $TMP1
cut -c 21-47 $FILE > $TMP2
cut -c 79-82 $FILE > $TMP3
cut -c 91-94 $FILE > $TMP4
cut -c 96-125 $FILE > $TMP5
cut -c 127-200 $FILE > $TMP6
paste -d! $TMP0 $TMP1 $TMP2 $TMP3 $TMP4 $TMP5 $TMP6 | sort -t! -k 1,1 -k 4,4 -k 2,2 -k 5,5
