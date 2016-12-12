# Software

RPi uses a Debian variant called Raspbian; there are a few packages
which are RPi-specific, but mostly this should be Debian-compatible,
maybe even Ubuntu-compatible.




# Entropy Starvation

Juha Nurmi warned against entropy starvation:

>For instance, years ago I had some exit nodes and it took me several
>days to figure out what was the bottleneck of the traffic. There were
>plenty of CPU, RAM and bandwidth available but the entropy level of the
>VM was close to zero.
>Tip: follow your `cat /proc/sys/kernel/random/entropy_avail` and maybe
>`apt-get install haveged`.

See also: https://www.irisa.fr/caps/projects/hipsor/

Brian Howson later pointed out that the Pi has a hardware random
number generator:

https://twitter.com/bkhowson/status/807618014136963072

This observation leads to the following advice:

- apt-get install rng_tools
  - https://wiki.archlinux.org/index.php/Rng-tools

Being in a fit of experimentation, I decided to install both
`rng_tools` and `haveged`, because I felt like doing so.

I'm sure someone will explain how this is a bad idea, if it really
_is_ a bad idea.

Result was good: system entropy rose from typical ~700 to a range of
1600..2200
