#!/bin/sh
root=`dirname $0`
cd $root
root=`pwd`
tor=./tor-0.2.8.10/src/or/tor
for i in 0 1 2 3 4 5 6 7 8 9 ; do # works for up-to ..9
    hs=hs$i
    dir=$root/$hs.d
    port=900$i
    test -d $dir || mkdir $dir || exit 1
    chmod 700 $dir
    if [ ! -f $dir/config ] ; then
        (
            echo DataDirectory $dir
            echo HiddenServiceDir $dir/
            echo HiddenServicePort $port localhost:$port
            echo SOCKSPort 905$i
        ) > $dir/config
    fi
    $tor --hush -f $dir/config &
done
wait
