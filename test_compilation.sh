#!/bin/bash
# test if compilation ended with no errors

function test {
    if grep -q "no errors" "$1"; then
        echo "Test passed - $1"
        return 0
    else
        echo "Test failed - $1"
        cat $1
        return 1
    fi 
}

test test.lst
t1=$?

test clock.lst
t2=$?

if [ "$t1" -ne "0" ] || [ "$t2" -ne "0" ]; then
    exit 1
fi
