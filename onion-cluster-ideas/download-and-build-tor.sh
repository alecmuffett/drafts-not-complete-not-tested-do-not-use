#!/bin/sh

url=https://www.torproject.org/dist/tor-0.2.8.10.tar.gz
tarball=`basename $url`
dir=`basename $url .tar.gz`

sudo aptitude install libevent-dev zlib1g-dev libssl-dev || exit 1
wget $url || exit 1
tar xvfz $tarball || exit 1
cd $dir || exit 1
./configure || exit 1
make || exit 1
sudo make install || exit 1
exit 0
