
## THIS IS A WORK IN PROGRESS - CHECK BACK OR STAR IT FOR UPDATES

# Goals

- Serve sustained 500Mbits of TCP traffic
  - not HTTP, just plain TCP traffic with boring content
- Over Onion Connections
  - "vanilla" latest Tor with a basic config
- from a "single" Onion address
  - using OnionBalance

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

There is a culture of "clustering" RPi - do a [google search on "raspberry pi bramble"](https://www.google.co.uk/search?q=raspberry+pi+bramble).

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

(Typing from memory, please forgive any bugs; also I have renamed some files when uploading them to GitHub, for clarity.)

I connected the RPi to my network.

Then, I needed a network load-monitoring tool, so I got `ifstat`

```
sudo aptitude install ifstat
```

Then, on the RPi, in one window I did this to watch the network load: 

```
ifstat -atbn 
```

[see watch-network-traffic.sh](watch-network-traffic.sh)

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

See [download-and-build-tor.sh](download-and-build-tor.sh)

Then I wrote a script to create up-to-10 separate Tor daemon hidden-service configurations, and to launch the daemons:

See [polytunnel.sh](polytunnel.sh)

...and I ran it:

```
11:33:34 pi3b-0:tor $ pwd
/home/alecm/src/tor

11:33:35 pi3b-0:tor $ ls
build.sh  hs1.d  hs3.d  hs5.d  hs7.d  hs9.d         polytunnel.sh  tor-0.2.8.10
hs0.d     hs2.d  hs4.d  hs6.d  hs8.d  listeners.sh  senders.sh     tor-0.2.8.10.tar.gz

11:35:50 pi3b-0:tor $ ls hs0.d/
cached-certs                cached-microdescs      config    lock         state
cached-microdesc-consensus  cached-microdescs.new  hostname  private_key
```

I then wrote and ran a script to generate traffic for the hidden service.

See [start-senders.sh](start-senders.sh)

Careful how you run/kill this. If it goes berzerk, you need to `killall start-senders.sh`

Then I wrote and ran another script to tell me what to type, on my MacMini, to use my Mac's TorBrowserBundle to pull data from the senders.

See [generate-listener-commandlines.sh](generate-listener-commandlines.sh)

When you run it, you see output like:

```
nc -X 5 -x localhost:9150 kzzyean5mihkgxn2.onion 9000 >/dev/null
nc -X 5 -x localhost:9150 c5es6r32s477d5nd.onion 9001 >/dev/null
nc -X 5 -x localhost:9150 2acilolxzrsovrqq.onion 9002 >/dev/null
nc -X 5 -x localhost:9150 lxahthftubieyy7k.onion 9003 >/dev/null
nc -X 5 -x localhost:9150 tuuwnz3algkjat2k.onion 9004 >/dev/null
nc -X 5 -x localhost:9150 ywfbfdngksbfsz2y.onion 9005 >/dev/null
nc -X 5 -x localhost:9150 e5bpsjcpccifrqzu.onion 9006 >/dev/null
nc -X 5 -x localhost:9150 twwbw2nfeu4wt2is.onion 9007 >/dev/null
nc -X 5 -x localhost:9150 d3dcfbp6xbcjwp23.onion 9008 >/dev/null
nc -X 5 -x localhost:9150 oxn5pvrfkazgig55.onion 9009 >/dev/null
```

...which you can paste into different windows, one at a time, on another machine/machines, to make the Onions send data.

So, on another machine, I started using these commands.  

Fairly rapidly the senders maxed-out my home DSL line: https://twitter.com/AlecMuffett/status/804856245446447108

18Mbps upstream, at 15% busy.

# Plans for Building a Cluster

Looking around the web, a credible RPi cluster typically has 6 nodes / 6 boards.

This makes sense, because you can build an 6-node cluster in a nice case (eg: https://www.amazon.co.uk/Mepro-Raspberry-6-layer-Enclosure-Support/dp/B01COU8Z1O/) and plug them into an 8-port 1Gbit (or 10Gbit) Switch.

You would need an 8-port switch because: 6 for the RPis, 1 for "upstream" and 1 for (maybe) chaining to the _next_ cluster.

I think I will shoot for something like the one illustrated, but with added heatsinks and fans.

# Projected Output

1x RPi generates 18Mbit without really breaking a sweat, at ~15% CPU.

Our target is 500Mbit. `500 / 18 = 27.777`.

Round this up to "We need 28x more traffic, to beat our target.

In a 6-Pi cluster, we're multiplying the CPU performance linearly, and: `28 / 6 = 4.667`

Therefore each Pi will need to do 4.667x (round this up to 5x) more work.

5x more work * 15% current load = 75% target load, which does not seem unreasonable, though cooling will be an issue.

Also: 6x RPi at 96.8Mbit = 580.8Mbit hardware bandwidth cap, so that also seems achievable so long as we choose a zero-contention switch for use as a core interconnect.

# Tor Deployment Architecture

TBD. If you are reading this and know what `Direct Server Return Scaling` means, you'll have a fair idea of where I am going with this. OnionBalance gives you something similar to DSR, but this will have a slight Tor twist.

## Notes to fill-in later

* probably use Wifi as a static-IP private "backplane" network, leave the ethers free for Onion traffic.
* dhcp the ethers
* we will have 6 machines => 24 cores
  * call the machines: `a`, `b`, `c`...
  * number the tor daemons on each machine as (eg:) `1..4` => 4 daemons
  * defer the question of how many daemons vs: how many cores, for a moment
* maximum descriptor space in OnionBalance is 10 Introduction Points per descriptor
  * 10 Introduction Points x 6 distinct descriptors (banked 2x3) => 60 Intro Points
* we can slice the introduction point space in several ways:
  * 1 introduction point = 1 daemon
  * 2+ introduction points = 1 daemons
  * mixture of the above
 
## How many Tor Daemons per machine?
 
These machines won't be serving web traffic, so we're free to eat all the CPU and bus bandwidth for pushing packets out the door; otherwise it would be sane to leave some resources free.
 
Obvious deployment strategies:

* 4 daemons per machine = 1 daemon per core
* 5 daemons per machine = 1 daemon per core + 1 spare to prevent scheduler `stalls`
* 8 daemons per machine = 2 daemons per core

#### Wild Guess Time

For the moment let's go with the 5 daemons per machine, which sorta-guarantees CPU occupancy (0% idle) without necessarily thrashing; then we ramp up/down/stay-still as results warrant.

This gives us 5 * 6 = 30 daemons.  

### How do we construct the six descriptors

We have to make 6 descriptors each containing 10 introduction points corresponding to our service.

That's 60 introduction points, so we should construct our individual daemons to create two introduction points apiece; we could do one introduction point per daemon and repeat that data twice, but that's a potential choke on access to one of our daemons.

For each daemon, name its two introduction points as `x` and `y`; they is no reason obvious to me to worry about preferring one over the other for any given daemon.

#### naive descriptor layout

```
#!/bin/sh
for intro in x y ; do
    for machine in A B C D E F ; do
        for daemon in 1 2 3 4 5 ; do
            echo $machine$daemon$intro
        done
    done
done |
    awk '{ printf("%s ", $1)} NR%10==0 {print "" }' |
    cat -n
$ sh q
     1	A1x A2x A3x A4x A5x B1x B2x B3x B4x B5x
     2	C1x C2x C3x C4x C5x D1x D2x D3x D4x D5x
     3	E1x E2x E3x E4x E5x F1x F2x F3x F4x F5x
     4	A1y A2y A3y A4y A5y B1y B2y B3y B4y B5y
     5	C1y C2y C3y C4y C5y D1y D2y D3y D4y D5y
     6	E1y E2y E3y E4y E5y F1y F2y F3y F4y F5y
```

This is a bad descriptor layout; if (say) descriptors 1 and 4 get preferred over all others, then machines A and B will be burning CPU and the other four machines will be idle.

#### better descriptor layout

```
#!/bin/sh
for intro in x y ; do
    for daemon in 1 2 3 4 5 ; do
        for machine in A B C D E F ; do
            echo $machine$daemon$intro
        done
    done
done |
    awk '{ printf("%s ", $1)} NR%10==0 {print "" }' |
    cat -n
$ sh q
     1	A1x B1x C1x D1x E1x F1x A2x B2x C2x D2x
     2	E2x F2x A3x B3x C3x D3x E3x F3x A4x B4x
     3	C4x D4x E4x F4x A5x B5x C5x D5x E5x F5x
     4	A1y B1y C1y D1y E1y F1y A2y B2y C2y D2y
     5	E2y F2y A3y B3y C3y D3y E3y F3y A4y B4y
     6	C4y D4y E4y F4y A5y B5y C5y D5y E5y F5y
```

This is much improved; again imagine that descriptors 1 and 4 get preferred over all others, then machines C/D/E/F will get proportionately more traffic than A and B, because in a given descriptor (eg: `a1 b1 c1 d1 e1 f1 a2 b2 c2 d2`) machines C/D/E/F each get two mentions, whereas A/B only get one mention.

#### randomised descriptor layout

```
$ cat q
#!/bin/sh
for intro in x y ; do
    for daemon in 1 2 3 4 5 ; do
        for machine in A B C D E F ; do
            echo $machine$daemon$intro
        done
    done
done |
    randsort |
    awk '{ printf("%s ", $1)} NR%10==0 {print "" }' |
    cat -n
$ sh q
     1	A3x C1x C1y F5x D5x D2x B4x B4y D3x E1x
     2	A2y F1y F2y A1x A4y F4x F4y C3y E3y D3y
     3	F3x B1x D2y C3x E4y C4y E5y F2x C4x A5y
     4	C5x C2x D5y F5y E2y A3y C2y B5y D4y B3x
     5	E5x E1y F1x A5x B5x A1y B3y E2x F3y A4x
     6	D4x D1x E4x D1y B2y E3x A2x B2x B1y C5y
```

This is at the whim of the gods, but with random sorting the systematic hotspots are now random hotspots

####
