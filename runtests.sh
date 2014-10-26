#!/bin/bash

SIZES="10 100 1000 5000 10000 50000 100000 500000 1000000"

echo "Creating ascending.."
for s in $SIZES; do
    sort -n random$s-1 > random$s-asc
    sort -nr random$s-1 > random$s-desc
done


for s in $SIZES; do
    for n in $(seq 1 20); do
        FILENAME="random$s-$n"
        printf "Sorting $FILENAME: "
        /usr/bin/time --format %e ./sorter $FILENAME $1 > result
        sort -nc result
    done
done
