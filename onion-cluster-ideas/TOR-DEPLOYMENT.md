## How many Tor daemons to run, per machine?

These machines won't be serving web traffic, so we're free to eat all
the CPU and bus bandwidth for pushing packets out the door; otherwise
it would be sane to leave some resources free.

Obvious deployment strategies:

* 3 daemons per machine = 1 daemon per core EXCEPT saving 1 core for "work"
* 4 daemons per machine = 1 daemon per core
* 5 daemons per machine = 1 daemon per core PLUS one extra daemon to keep everything "busy"
* 8 daemons per machine = 2 daemons per core

Originally I was going to go for 5 daemons per machine to ensure
everything was kept "busy", however after testing I've determined that
a single core is sufficient to fully flood the network interface with
network traffic, and am hoping to get away with 3 daemons and slightly
cooler machines.

So, that's 3 daemons x 6 machines = 18 daemons total.


### How do we construct the descriptors?

If you want to know the fundamentals of Tor Onion Service Descriptors,
see: https://www.torproject.org/docs/hidden-services.html.en

We have to create 6 descriptors (this is a Tor figure, nothing to do
with the number of Raspberry Pis) - each descriptor containing the IP
addresses of 10 introduction points corresponding to our service.

That's 60 introduction points, so we should construct our individual
daemons to create just enough introduction points apiece to fill that
number.

`60 / 18 = 3.333` - round this up to 4 introduction points per daemon.

For each daemon, name its two introduction points as `A..D`; they is
no reason obvious to me to worry about preferring one over the other
for any given daemon.

#### naive descriptor layout

```
#!/bin/sh
for intro in A B C D ; do
    for machine in 1 2 3 4 5 6 ; do
        for daemon in x y z ; do
            echo $machine$daemon$intro
        done
    done
done |
    awk '{ printf("%s ", $1)} NR%10==0 {print "" }' |
    cat -n
$ sh q
1  1xA  1yA  1zA  2xA  2yA  2zA  3xA  3yA  3zA  4xA
2  4yA  4zA  5xA  5yA  5zA  6xA  6yA  6zA  1xB  1yB
3  1zB  2xB  2yB  2zB  3xB  3yB  3zB  4xB  4yB  4zB
4  5xB  5yB  5zB  6xB  6yB  6zB  1xC  1yC  1zC  2xC
5  2yC  2zC  3xC  3yC  3zC  4xC  4yC  4zC  5xC  5yC
6  5zC  6xC  6yC  6zC  1xD  1yD  1zD  2xD  2yD  2zD
...truncated
```

This is a bad descriptor layout; if (say) descriptors 1 and 4 for some
reason get preferred over all others, then machine 1 will get twice as
much traffic as all the others (from a double-mention) whereas machine
4 will receive no traffic at all.

### randomised descriptor layout

Given the potential for attack - or simple inefficiency of trying to
squeeze fair representation into a pot of 60 introduction points,
sliced into 6 banks of 10 - it's perhaps safest just to randomise the
descriptors each and every time they are published, to hide the
internal structure of the cluster.

### suggested algorithm for onionbalance configurations

1. Where you choose to support `N` tor daemons, choose smallest integer `M` where `(N * M) > 60`
  * if `M > 10` then rethink what you are doing
1. Configure each tor daemon to announce M introduction points
1. Each time you publish an onionbalance descriptor
  - scrape all `N * M` introduction points
  - sort randomly
  - choose the first 60
  - create 6x descriptors, each of 10 introduction points
  - emplace them on the HSDir ring

# Todo

* plan to do the test both with, and without, single-hop-onion configs
* future scaling:
  * add a second cluster (machines G/H/I/J/K/L) and use them to
    replace the `y` introduction points
  * future/better
    * implement @TvdW's suggestion of hacking Tor daemon to hand-off
      requests received from the introduction point, to other machines
      in the cluster
    * then rearchitect as N introduction points handing off to M
      callback servers
