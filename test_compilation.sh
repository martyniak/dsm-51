#!/bin/bash
# test if compilation ended with no errors

function test {
    if grep -Fxq "no errors" $1; then
        echo "Test passed - $1"
        return 0
    else
        echo "Test failed - $1"
        cat $1
        return 1
    fi 
}

t1 = $(test test.lst)
t2 = $(test clock.lst)

if $t1 -ne 0 || $t2 -ne 0; then
    exit 1
fi
