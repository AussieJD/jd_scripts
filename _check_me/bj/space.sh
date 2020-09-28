cd $HOME
for file in `ls`
do
	if [ -h $file ]
	then
		echo " "
	else
		du $file
	fi
done
