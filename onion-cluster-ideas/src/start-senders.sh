#!/bin/sh

Send() {
    while : ; do
        echo starting port $1
        dd if=/dev/zero | nc -l $1
    done
}

for hs in hs*.d
do
    port=`grep HiddenServicePort $hs/config | awk -F: '{print $2}'`
    Send $port &
done

wait
