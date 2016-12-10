#!/bin/sh

while :
do
    echo :::: temperature "(x1000)" ::::
    cat /sys/class/thermal/thermal_zone0/temp

    echo :::: load average ::::
    uptime

    echo :::: entropy ::::
    cat /proc/sys/kernel/random/entropy_avail

    echo :::: mem ::::
    vmstat 1 1

    echo :::: net ::::
    ifstat -bntT 1 10

    echo ""
done
