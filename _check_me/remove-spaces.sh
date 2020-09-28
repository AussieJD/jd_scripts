for i in *
 do
	FileName=`basename "$i"`

    	ShortName=`echo $FileName | sed 's/ //g'`

    	if [ $ShortName != "$FileName" ]
    	 then
      		mv "$FileName" "$ShortName"
    	fi

done
