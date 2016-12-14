# Hardware

All prices in GBP, rounded up, inc tax

- 192 = 6x RPi3b @ 32
- 58 = 2x Anker PowerPort 6 (60W) inc [6-Pack] Premium 1ft Micro USB Cables @ 29
- 54 = 6x SanDisk Extreme 16 GB microSDHC Class 10 Memory Card
- 27 = 1x Mepro Raspberry Pi 3 Model B 6-layer Stack Clear Case (design: "Eleduino")
  - I think this is the same one: http://www.eleduino.com/Raspberry-Pi-3-Model-B-6-layer-Stack-Clear-Case-Support-Raspberry-Pi-2B-B-B-A-p10567.html
- 20 = 1x NETGEAR GS308-100UKS 8 Port Gigabit Ethernet Switch
- 14 = 1x AC Infinity MULTIFAN S5, Quiet Dual 80mm USB Fan
- 10 = 1x 10-Pack 0.3m Meters Cat6 Ethernet Cable
- 7 = 1x perforated metal plate, from local builder
- free: old metal bracket, retaining bolt, cable ties

Total: 382 GBP

TCO per node: ~ 64 + power + effort

# Power Consumption

Absolutely everything is plugged into a powerstrip which is then
plugged into a Killawatt power meter, and thence into the mains; some
rough stats on power draw:

- ~ 2W all devices halted, nodes unplugged (leaving switch + PSUs)
- 5W as above, but with nodes plugged & halted
- 14W nodes booted & running, mostly idle
- 29W nodes running 100% quad-process CPU-burning test

# Cooling

Following the advice in this video:

https://www.youtube.com/watch?v=1AYGnw6MwFM

...I use the following as a CPU-loading benchmark on the RPi:

```
22:53:32 rig1:~ $ cat bin/burn-cpu.sh
#!/bin/sh
exec sysbench --test=cpu --cpu-max-prime=20000 --num-threads=4 run
```

It runs for almost exactly 2 minutes, and can easily be looped.

Also, the CPU temperature may be measured using a simple script:

```
cat /sys/class/thermal/thermal_zone0/temp
```

...or see `watch-system-stats.sh` in the src directory.

## Cooling Summary:

* running the CPU benchmark repeatedly with no fans = temperature range 67..71
* running with fans set to L (low) = 64..65
* running with fans set to M (medium) = 57..59
* running with fans set to H (high) = 56..57

The RPi starts to throttle performance to maintain coolness at
[some temperature] - so I am trying to keep it below 60C.

## Heatsinks?

Not yet. They seem like a good idea, though, to increase the
effectiveness of the fans.

## Why are the fans side-mounted?

I used to be a Datacentre Architect; the maxim was to "cool the
environment, not the CPUs"; the CPUs are not the only source of heat,
if everything is a little cooler then everything benefits / fewer
hotspots build up. Also, 2x big fans are cheaper, quieter and less
fiddly than 6x CPU-mounted tiny ones.

I got lucky that the approximate rack dimensions* are approx 60 x 90 x
180mm, so two 80mm USB-powered fans, stacked, mounted on stubby rubber
"feet", are about the right size.

* nb: rack dimensions cited do not account for flanges, posts, etc.

# Layout

I'm trying to squeeze everything into a fairly small footprint; see
the "images" directory for evolution. Note especially P1030959.jpg,
taken after I realised that (if mounting vertically) the network
switch is most sensibly mounted a few centimeters *forward* of the
rest of the RPi hardware, leaving clearance for the RPi power cables
at the rear of the switch.


# Comments & Ideas

* I could probably have gotten away with a single Anker to drive the
  nodes, however the Fans + use of an extra Pi (not costed above) and
  other toys would take the rack over the power and port-count budget.
  I'm happier having a spurplus of power to push around, plus the USB
  chargers are easily reusable.
* I got an 8-port hub; this is very reasonable (6 nodes + 1 upstream +
  1 maybe-controller) however I am now wondering about adding extra
  USB Ethernet ports to some of the nodes, trying to get extra network
  bandwidth out of them. In such circumstance a larger switch would be
  good, possibly faster than 1Gbit, too.

# Comparative Pricing

As-listed, in USD.

## RPi3b
- 1.2GHz 64-bit Quad-Core ARMv8 CPU @ $36 (AMZN USA)
- 1gb RAM
- 16gb Flash @ $9 (AMZN USA)
- estimate $45 per device - not including power, case...

## AWS t2.micro instance
- 1x Xeon "vCPU"
  - "performance equivalent to 20% of a CPU core"
  - "burstable" additional performance at need
- 1gb RAM
- EBS (cloud) storage
- 1 year upfront payment contract: $69
  - https://aws.amazon.com/ec2/instance-types/
  - https://aws.amazon.com/ec2/pricing/

# License

All documentation content (including example code fragments) under
https://github.com/alecmuffett/drafts-not-complete-not-tested-do-not-use/
is made available by the author under the terms of the Creative
Commons Attribution Share Alike 4.0 License - see
http://choosealicense.com/licenses/cc-by-sa-4.0/ for details.
