#!/bin/bash

# Config path prefix
WDT_PATH="system watchdog"

API=cli-shell-api

WDT_CONFIG=/etc/watchdog.conf

# There is an option for module loading in /etc/defaults/watchdog
# but it's probably better to find out something went wrong with
# it during commit
function load_module
{
    MODULE=`$API returnValue $WDT_PATH driver`
    lsmod | grep $MODULE > /dev/null
    if [ $? != 0 ]; then
        sudo modprobe $MODULE
        if [ $? != 0 ]; then
            echo "Could not load watchdog driver"
            exit 1
        fi
    fi
}

# Write a config line
function write_cfg
{
    echo $1
}

# system watchdog driver
$API exists $WDT_PATH driver
if [ $? == 0 ]; then
    load_module
fi

## system watchdog tests

# system watchdog tests free-memory
# watchdog daemon (lazy butt) counts memory in pages
# we don't want to make the user learn what a page is
# so we convert megabytes to the current system pages
$API exists $WDT_PATH tests free-memory
if [ $? == 0 ]; then
    MEMORY_MB=`$API returnValue system watchdog tests free-memory`
    PAGE_SIZE=`getconf PAGESIZE`
    MEMORY_PAGES=$(($MEMORY_MB*1024*1024/$PAGE_SIZE))
    write_cfg "min-memory = $MEMORY_PAGES"
fi

# system watchdog tests system-load
$API exists $WDT_PATH tests system-load interval-1
if [ $? == 0 ]; then
    LOAD_1=`$API returnValue $WDT_PATH tests system-load interval-1`
    write_cfg "max-load-1 = $LOAD_1"
fi

$API exists $WDT_PATH tests system-load interval-5
if [ $? == 0 ]; then
    LOAD_5=`$API returnValue $WDT_PATH tests system-load interval-5`
    write_cfg "max-load-5 = $LOAD_5"
fi

$API exists $WDT_PATH tests system-load interval-15
if [ $? == 0 ]; then
    LOAD_15=`$API returnValue $WDT_PATH tests system-load interval-15`
    write_cfg "max-load-1 = $LOAD_15"
fi

# system watchdog tests ping
$API exists $WDT_PATH tests ping
if [ $? == 0 ]; then
    ping_list=$($API returnValues $WDT_PATH tests ping address)
    eval "PING_HOSTS=($ping_list)"

    for i in "${PING_HOSTS[@]}"; do
        write_cfg "ping = $i"
    done
fi

# system watchdog tests user-defined
$API exists $WDT_PATH tests user-defined
if [ $? == 0 ]; then
    TEST_EXECUTABLE=$($API returnValue $WDT_PATH tests user-defined executable)
    TEST_TIMEOUT=$($API returnValue $WDT_PATH tests user-defined timeout)

    if [ -z $TEST_EXECUTABLE ]; then
        echo "Test executable must be defined"
        exit 1
    fi

    write_cfg "test-binary = $TEST_EXECUTABLE"
    write_cfg "test-timeout = $TEST_TIMEOUT"
fi
