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

There is a culture of "clustering" RPi - do a google search on "raspberry pi bramble"

# What can 1x RPi do?

So I bought an RPi3, the "official full starter pack" including PSU, RPi, small case, memory card.

After a lot of experimentation I determined that - as a developer - it's best to erase the memory card (hard-format it as a clean FAT filesystem) then drag-and-drop the "NOOBS" installer onto the card, and boot _that_. 

Frankly the alternative upgrade-path of doing `apt-get dist-upgrade` leaves the RPi in a messy state where some stuff does not work.

Also, I've taken some tips from http://www.zdnet.com/article/raspberry-pi-extending-the-life-of-the-sd-card/ and remounted some (but not all) of the suggested filesystems as `tmpfs` to save the card a little stress. More details on that, to follow later.



# Building a Cluster

# Projected Output

