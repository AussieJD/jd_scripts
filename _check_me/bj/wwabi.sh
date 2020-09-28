HOST=`uname -n`:0.0
echo HOST=$HOST
echo "Running wabi from williams and displaying it on $HOST..."
rsh williams /opt/SUNWwabi/bin/wabi -display $HOST
