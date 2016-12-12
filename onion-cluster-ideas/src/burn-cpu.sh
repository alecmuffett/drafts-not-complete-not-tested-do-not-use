#!/bin/sh
exec sysbench --test=cpu --cpu-max-prime=20000 --num-threads=4 run
