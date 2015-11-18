#!/bin/bash

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -h|--host)
    HOST="$2"
    shift # past argument=value
    ;;
    -s|--serial-number)
    SERIAL="$2"
    shift # past argument=value
    ;;
    -l|--local-port)
    LOCAL_PORT="$2"
    shift # past argument=value
    ;;
    -k|--kill-connection-on-port)
    KILL="$2"
    shift # past argument=value
    ;;
    -d|--debug)
    echo "Enabling Debug"
    set -x
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
shift # past arguent or value
done

if [ -n "$KILL" ]
  then
    echo "Killing connection on port $KILL"
    adb disconnect localhost:$KILL
    sleep 5
    adb devices
    kill `cat /tmp/ssh-tunnel-$KILL.pid`
    exit 0
fi
if [ -z "$HOST" ]
  then
    echo "No ssh host given"
    exit 1
fi
if [ -z "$SERIAL" ]
  then
    echo "No adb serial number given"
    exit 1
fi
if [ -z "$LOCAL_PORT" ]
  then
    echo "No local port specified, using default of 5555"
    LOCAL_PORT=5555
fi

RANDOMISH_PORT=$(shuf -i 2000-65000 -n 1)

echo "ADB == usb"
ssh $HOST -C "adb -s $SERIAL usb"
sleep 5
echo "ADB == tcpip:5555"
ssh $HOST -C "adb -s $SERIAL tcpip 5555"
sleep 5
echo "ADB == localhost:$RANDOMISH_PORT"
ssh $HOST -C "adb -s $SERIAL forward tcp:$RANDOMISH_PORT tcp:5555"
sleep 5
echo "Port forwarding remotehost:$RANDOMISH_PORT to localhost:$LOCAL_PORT"
ssh -fNt -L $LOCAL_PORT:localhost:$RANDOMISH_PORT $HOST
TUNNEL_PID=$(pgrep -f "ssh -fNt -L $LOCAL_PORT:localhost:$RANDOMISH_PORT $HOST")
echo $TUNNEL_PID > /tmp/ssh-tunnel-$LOCAL_PORT.pid
sleep 5
adb connect localhost:$LOCAL_PORT
sleep 5
adb devices
