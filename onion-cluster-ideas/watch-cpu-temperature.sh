#!/bin/sh
while : ; do
    expr `cat /sys/class/thermal/thermal_zone0/temp` / 1000
    sleep 1
done
