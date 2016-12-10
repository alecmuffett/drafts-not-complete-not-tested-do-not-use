#!/bin/sh

root=`dirname $0`
cd $root
root=`pwd`

tor=./tor-0.2.8.11/src/or/tor

# for testing I will run 3x daemons on 7 nodes = 21 daemons
# compute: ceiling(60 / 21) = 3 = three intropoints/daemon
num_daemons_per_node=3
num_intro_points=3

# ports are based on this number (starting at N+1)
portroot=8500

i=1
while [ $i -le $num_daemons_per_node ] ; do
    hs=hs$i
    dir=$root/$hs.d
    port=`expr $portroot + $i`

    test -d $dir || mkdir $dir || exit 1
    chmod 700 $dir

    if [ ! -f $dir/config ] ; then
        (
            echo DataDirectory $dir
            echo HiddenServiceDir $dir/
            echo HiddenServicePort $port localhost:$port
	    echo HiddenServiceNumIntroductionPoints $num_intro_points
            echo SOCKSPort 905$i
        ) > $dir/config
    fi

    $tor --hush -f $dir/config &

    i=`expr $i + 1`
done

wait
