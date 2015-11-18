set -x
if [ -z "$1" ]
  then
    echo "No ssh host given"
    exit 1
fi
if [ -z "$2" ]
  then
    echo "No adb serial number given"
    exit 1
fi
if [ -z "$3" ]
  then
    echo "No local port specified, using default of 5555"
    local_port=5555
else
    local_port=$3
fi
randomish_port=$(shuf -i 2000-65000 -n 1)
echo "ADB == usb"
ssh $1 -C "adb -s $2 usb"
sleep 5
echo "ADB == tcpip:5555"
ssh $1 -C "adb -s $2 tcpip 5555"
sleep 5
echo "ADB == localhost:$randomish_port"
ssh $1 -C "adb -s $2 forward tcp:$randomish_port tcp:5555"
sleep 5
echo "Port forwarding remotehost:$randomism_port to localhost $local_port"
echo "To Connect: adb connect localhost:$local_port"
echo "Ctrl-C To Exit"
ssh -N -L $local_port:localhost:$randomish_port $1
