# Goals

- Generate sustained 500Mbits of TCP traffic
  - not HTTP, just plain TCP traffic with boring content
- served over onion connections
  - "vanilla" latest Tor with a basic config
- from a "single" onion address
  - use OnionBalance

# Hardware

Because of Tor's historically monolithic (albeit efficient) implementation, to do a maximum-outflow-bandwidth test we will need to use multiple daemons, ideally spread across multiple cores for parallelism / "horizontal scalability".

Back at Facebook it was not a challenge to get hold of hardware, but from my own pocket I could pay for AWS/similar - however that would feel like cheating because AWS is "big infrastructure"; however everything I learn here can be applied to AWS as well.

So: how about Raspberry Pi? 

## Raspberry Pi 3 model "B" (RPi / RPi3 for short)

* Debian-inspired "Raspbian" distro
* quad-core 1.2GHz ARM
* 1Gb RAM
* SD-card storage
* Wifi
* 100Mbit Ethernet
* 4x USB
* bulk retail price: £28 each

There is a culture of "clustering" RPi - do a google search on "raspberry pi bramble".

# What can 1x RPi do?

So I bought an RPi3, the "official full starter pack" including PSU, RPi, small case, memory card.

After a lot of experimentation I determined that - as a developer - it's best to erase the memory card (hard-format it as a clean FAT filesystem) then drag-and-drop the "NOOBS" installer onto the card, and boot _that_. 

Frankly the alternative upgrade-path of doing `apt-get dist-upgrade` leaves the RPi in a messy state where some stuff does not work.

Also, I've taken some tips from http://www.zdnet.com/article/raspberry-pi-extending-the-life-of-the-sd-card/ and remounted some (but not all) of the suggested filesystems as `tmpfs` to save the card a little stress. 

More details on that to follow later, but for the record my `fstab` currently looks like this:

```sh
/dev/mmcblk0p7 / ext4 defaults,noatime 0 1
/dev/mmcblk0p6 /boot vfat defaults 0 2
proc /proc proc defaults 0 0
tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0
tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=30m 0 0
```


## Basic RPi Testing

### Raw Network Bandwidth

(typing from memory, please forgive any bugs)

I connected the RPi to my network.

Then, I needed a network load-monitoring tool, so I got `ifstat`

```
sudo aptitude install ifstat
```

Then, on the RPi, in one window I did this to watch the network load: 

```
ifstat -atbn 
```

...and in another I did this, which creates a listener on port 9000 and feeds nul bytes into it:

```
nc -l 9000 < /dev/zero
```

Then, on my Mac Mini, I did this:

```
nc $RPI_ETHERNET_IP_ADDRESS 9000
```

...and got I results:

```
10:55:58      0.00      0.00      0.59  96077.33    438.45      0.00
10:55:59      0.00      0.00      0.00  96896.34    432.45      0.00
10:56:00      0.00      0.00      2.67  95480.51    420.52      0.00
10:56:01      0.00      0.00      0.00  96893.43    429.26      0.00
10:56:02      0.00      0.00      0.00  96352.84    447.07      0.00
10:56:03      0.00      0.00      0.36  96879.86    442.58      0.00
```

...showing that the Ethernet interface can happily pump about 96.8Mbits of data without too much stress. 

* CPU temperature rose from 39C to 48C over several minutes
* Machine was 91% idle (~ 4.3% systime, < 1% usertime)

A similar test for the Wifi interface showed that the RPi wifi interface can do about 45Mbits, but you probably don't want to do both at the same time, because CPU contention, not to mention overall weirdness of plumbing the eventual network.

Also, apparently the RPi3 Ethernet interface is a USB interface, ganged with the other 4x USB ports on that machine.  Therefore adding more network interfaces via USB is probably not the best direction to go.

# Basic Tor Testing

The version of Tor made available to the Raspbian repo is woefully out of date

So I created a directory called `~/src/tor` and there I built a fresh Tor.


# Plans for Building a Cluster

# Projected Output

