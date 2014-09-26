#!/bin/bash

SIZES="10 100 1000 5000 10000 50000 100000 500000 1000000"


for s in $SIZES; do
    for n in $(seq 1 20); do
        FILENAME="random$s-$n"
        echo "Sorting $FILENAME"
        /usr/bin/time -f "%U" ./sorter $FILENAME > result
        sort -nc result
    done
done
