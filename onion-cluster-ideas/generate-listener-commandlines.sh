#!/bin/sh
tbb_socks_port=9150
for hs in hs*.d
do
    host=`cat $hs/hostname`
    port=`grep HiddenServicePort $hs/config | awk '{print $2}'`
    echo "nc -X 5 -x localhost:$tbb_socks_port $host $port >/dev/null"
done
# now paste the resulting commandlines into a receiver running TBB,
# one-by-one, into different terminal windows, so you can watch the
# growth.
