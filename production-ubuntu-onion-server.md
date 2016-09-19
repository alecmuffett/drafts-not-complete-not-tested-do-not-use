# Installing Onion Addresses on Ubuntu Server

----
## THIS DOCUMENT IS INCOMPLETE AND HAS NOT BEEN REVIEWED
## DO NOT USE THIS DOCUMENT OR YOU MAY BE CYBERSPANKED
----

## Install Ubuntu

Follow the instructions to install Ubuntu Server.

Notes:

- configure network interfaces carefully
- set the hostname to be `invalid` (verbatim)
- install a personal account for sysadmin
- install security updates automatically
- install "standard system utilities" and "OpenSSH server"

## Initial Setup

Do:

```sh
sudo -i 
apt-get install aptitude
aptitude update
aptitude upgrade
aptitude install git tmux # check: these should be already installed?
shutdown -r now
```

## Installing Tor

Log in again and do: `sudo -i `

In a browser elsewhere, retreive the instructions for installing Tor from https://www.torproject.org/docs/debian.html.en

- Configure the APT repositories for Tor
  - I recommend that you add the Tor repos to the end of config file
  - I am not sure whether it makes a difference, but there was weirdness, once
- Do the gpg thing
- Do the tor installation

## Check Tor Connectivity

Do this:

```sh
torsocks curl https://www.facebook.com/si/proxy/ ; echo ""
```

...this should print: `tor`

Do this:

```sh
torsocks curl https://www.facebookcorewwwi.onion/si/proxy/ ; echo ""
```

...this should print: `onion`

## Fake a Fully Qualified Domain Name for Email

- edit `/etc/hosts`
- add `invalid.invalid` as an alias for the existing `invalid` entry

The first couple of lines should probably now look like this:

```
127.0.0.1       localhost
127.0.1.1       invalid invalid.invalid
```


## Install Local-Only Email
### (do it now, because package dependencies will bite you later)

do:

- `aptitude install postfix`
  - select `local` delivery 
  - set the email hostname `invalid.invalid` - to match the above FQDN hack

## Put the Tor configuration under revision control

Because we all can make mistakes:

```sh
cd /etc/tor
git init
git add .
git commit -m initial
```

## Make Git shut up about Email addresses

do: `env EDITOR=vi git config --global --edit`

...and either uncomment the relevant lines or fix it properly

## Constrain Tor SOCKS access to literally 127.0.0.1

edit: `/etc/tor/torrc` - and search for the SOCKSPolicy section; then insert:

```
SOCKSPolicy accept 127.0.0.1
SOCKSPolicy reject *
```

## Add Virtual Network Addresses to /etc/hosts
### (we create 4 as an example)

Notes:

- these are addresses in separate "/30" subnets of the DHCP address space
  - the DHCP address space is not routable in the same way as RFC1918 but is unlikely to clash with extant subnets
  - if this really upsets you, replace `169.254.255` with whatever, throughout the rest of this process
- we use the first usable address in each of separate "/30"-type subnets to inhibit routing and cross-contamination.
- because of what we are trying to achieve we could perhaps try using "/31" pairs and treat them as point-to-point, but that would be complex and contentious, whereas this is vanilla networking.

Edit: `/etc/hosts` - and add the following (*verbatim* - these will be auto-edited later):

```
# descending order of IP address
169.254.255.253	osite0.onion
169.254.255.249	osite1.onion
169.254.255.245	osite2.onion
169.254.255.241	osite3.onion
```

## Disable IP Forwarding and Multihoming

Edit: `/etc/sysctl.conf` - and uncomment and set to 0 the following:

```
net.ipv4.ip_forward=0
net.ipv6.conf.all.forwarding=0
```
...and also uncomment and set to 1 the following...

```
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
```
*TODO(alecm) - check that rp_filter checks on the internal loopback offer the same value as strict destination multihoming*

## Create Onion Addresses
### (we create 4 as an example)

Edit: `/etc/tor/torrc` - and search for HiddenServiceDir section, and insert the following (*verbatim* - these will be auto-edited later): 

```
HiddenServiceDir /var/lib/tor/osite0/
HiddenServicePort 80 osite0.onion:80

HiddenServiceDir /var/lib/tor/osite1/
HiddenServicePort 80 osite1.onion:80

HiddenServiceDir /var/lib/tor/osite2/
HiddenServicePort 80 osite2.onion:80

HiddenServiceDir /var/lib/tor/osite3/
HiddenServicePort 80 osite3.onion:80
```

...this should be safe since we're not actually running anything on port 80 yet.

## Restart Tor

do: `/etc/init.d/tor restart`

This will create the hidden service directories cited above, etc

## Configure Virtual IP interfaces/addresses to map to the Onions 

edit: `/etc/network/interfaces` - inserting the following text, replacing <INTERFACE> with your "primary network interface" (eg: `eth0`, `wlan0`, `enp4s0`, ...) as cited in that file.

```
# osite0
auto <INTERFACE>:0
iface <INTERFACE>:0 inet static
  address 169.254.255.253
  netmask 255.255.255.252
  broadcast 169.254.255.255

# osite1
auto <INTERFACE>:1
iface <INTERFACE>:1 inet static
  address 169.254.255.249
  netmask 255.255.255.252
  broadcast 169.254.255.251

# osite2
auto <INTERFACE>:2
iface <INTERFACE>:2 inet static
  address 169.254.255.245
  netmask 255.255.255.252
  broadcast 169.254.255.247

# osite3
auto <INTERFACE>:3
iface <INTERFACE>:3 inet static
  address 169.254.255.241
  netmask 255.255.255.252
  broadcast 169.254.255.243
```

## Create the Virtual IP Addresses

do: `ifup -a`

then: `ifconfig -a` - and you should see the four new network interfaces

## Tor Finalisation - **THE GRAND RENAMING**

First, make a backup of the hosts file: `cp /etc/hosts /etc/hosts,backup`

Then: run this script:

```sh
for odir in /var/lib/tor/osite?/ ; do
oname=`basename $odir`
oaddr=`cat $odir/hostname`
perl -pi~ -e "s/$oname.onion/$oaddr $oname/" /etc/hosts
perl -pi~ -e "s/$oname.onion:/$oaddr:/" /etc/tor/torrc
done
```

Then test the resolution of `osite0` (etc) into IPv4-equivalent onion names:

```sh
ping -c 1 osite0
ping -c 1 osite1
ping -c 1 osite2
ping -c 1 osite3
```

For each address you should see something like this:

```
root@invalid:~# ping -q -c 1 osite0
PING zxd674r63j44zfj7.onion (169.254.255.253) 56(84) bytes of data.

--- zxd674r63j44zfj7.onion ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.096/0.096/0.096/0.000 ms
```

...demonstrating that `osite0` is now an alias for a hostname `zxd674r63j44zfj7.onion` - which itself is a name that is bound to a virtual interface on your machine, and to which `torrc` is now configured forward connections on port 80:

```
root@invalid:~# grep zxd674r63j44zfj7.onion /etc/tor/torrc
HiddenServicePort 80 zxd674r63j44zfj7.onion:80
```

## Reboot

Do: `shutdown -r now`

If you are unwilling to do this, at least restart Tor with: `/etc/init.d/tor restart` - otherwise you will not pick up the changes that we jut made to the `torrc` file.

## The Story So Far...

You now have a server which is configured with (up to) four onion addresses.

You may disable any onion addresses that you are not using (by editing `/etc/tor/torrc`) or you may have avoided creating them in the first place.

The reason for creating IPv4 addresses to act as "shadows" for the onion addresses is one of Unix access control - eg: Apache "Listen" and VirtualHost directives can be configured clearly and unambiguously with the given Onion name, which will resolve also locally and (hopefully) avoid complaints.

Also: applications which enforce access-control on the basis of source IP address will inherit and resolve the name of the Onion address through which the traffic arrived, by virtue of the Tor daemon connecting to the correspondingly-named IP address.

There is a small risk here that bad system administrators will permit the contents of (eg:) /var/lib/tor/oside0/hostname to get out of sync with either/both of `/etc/hosts` or `/etc/tor/torrc`.  So don't let that happen.

## Install a Firewall

**TO BE DONE**

## Redirect DNS over Tor

**TO BE DONE**

## More Security Stuff TBD?

**TO BE DONE**

## Check For Promiscuous Network Listeners

Do:

```sh
netstat -a --inet --program  | awk '$6=="LISTEN" && $4~/^\*/'
```
This will print a list of network sockets which are listening to all local network interfaces simultaneously; something like:

```
tcp  0  0 *:ssh  *:*  LISTEN  1276/sshd
```

This tells you that process ID `1276` is an instance of `sshd`  which is listening to the `ssh` port on all network interfaces.  You may want to consider the security risks, and perhaps reconfigure this (and other) programs to listen only to specific, especially non-onion, network interfaces.

## ---- Finish ----

You should be good to go.

# Notes

## Putting 4 Onion Addresses on a Server? OMGWTFBBQ?

Yeah, well, whatever. Someone is gonna want more than one, so I might as well do the subnet math for them now. 

Yes there is advice to not run more than 1 onion address per machine that is attached to the internet. 

Anyone who is *actually* worried about being deanonymised can skip the extra three.

## Those DHCP IP Addresses? OMGWTFBBQ?

Basically we have created four little subnets, each of which can hold a maximum of two computers, and in each of those subnets we are using only one address - see `*-addr-1`, below.

Why do this? For convenience we want virtual IPv4 addresses which exist only on the server and which are not routable across the internet; we will then map those 1-to-1 against Onion addresses, and use them systematically in the `torrc` file so that processes (Apache, sshd, etc...) that do `gethostbyname()` on their connection's source address will see (eg:) `zxd674r63j44zfj7.onion` rather than localhost.

Quite a lot of processes would give `localhost` special privileged access, so marking inbound Onion connections as coming from somewhere other than `localhost` is a good idea. 

It just seems sane, therefore to use the onion address as a hostname, instead,

The subnets are computed like this, using a special script which does a bunch of simple math and spits out the configuration:

```
$ mknetmask 169.254.255.254/30
# 169.254.255.252/30: is a class B network and supports 2 hosts
# 169.254.255.252/30: netaddr 169.254.255.252 netmask 255.255.255.252 broadcast 169.254.255.255
# 169.254.255.252/30: netaddr 0xa9fefffc netmask 0xfffffffc broadcast 0xa9feffff
169.254.255.252	net-169-254-255-252-slash-30-netaddr
169.254.255.253	net-169-254-255-252-slash-30-addr-1
169.254.255.254	net-169-254-255-252-slash-30-addr-2
169.254.255.255	net-169-254-255-252-slash-30-broadcast

$ mknetmask 169.254.255.249/30
# 169.254.255.248/30: is a class B network and supports 2 hosts
# 169.254.255.248/30: netaddr 169.254.255.248 netmask 255.255.255.252 broadcast 169.254.255.251
# 169.254.255.248/30: netaddr 0xa9fefff8 netmask 0xfffffffc broadcast 0xa9fefffb
169.254.255.248	net-169-254-255-248-slash-30-netaddr
169.254.255.249	net-169-254-255-248-slash-30-addr-1
169.254.255.250	net-169-254-255-248-slash-30-addr-2
169.254.255.251	net-169-254-255-248-slash-30-broadcast

$ mknetmask 169.254.255.245/30
# 169.254.255.244/30: is a class B network and supports 2 hosts
# 169.254.255.244/30: netaddr 169.254.255.244 netmask 255.255.255.252 broadcast 169.254.255.247
# 169.254.255.244/30: netaddr 0xa9fefff4 netmask 0xfffffffc broadcast 0xa9fefff7
169.254.255.244	net-169-254-255-244-slash-30-netaddr
169.254.255.245	net-169-254-255-244-slash-30-addr-1
169.254.255.246	net-169-254-255-244-slash-30-addr-2
169.254.255.247	net-169-254-255-244-slash-30-broadcast

$ mknetmask 169.254.255.241/30
# 169.254.255.240/30: is a class B network and supports 2 hosts
# 169.254.255.240/30: netaddr 169.254.255.240 netmask 255.255.255.252 broadcast 169.254.255.243
# 169.254.255.240/30: netaddr 0xa9fefff0 netmask 0xfffffffc broadcast 0xa9fefff3
169.254.255.240	net-169-254-255-240-slash-30-netaddr
169.254.255.241	net-169-254-255-240-slash-30-addr-1
169.254.255.242	net-169-254-255-240-slash-30-addr-2
169.254.255.243	net-169-254-255-240-slash-30-broadcast
```
