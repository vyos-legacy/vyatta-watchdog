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

# Setup free memory test
#
# Watchdog daemon (lazy butt) counts memory in pages.
# We don't want to make the user learn what a page is
# so we convert megabytes to the current system pages.
function config_freemem
{
    MEMORY_MB=$($API returnValue system watchdog tests free-memory)
    PAGE_SIZE=`getconf PAGESIZE`
    MEMORY_PAGES=$(($MEMORY_MB*1024*1024/$PAGE_SIZE))
    write_cfg "min-memory = $MEMORY_PAGES"
}

# Setup max load test
function config_max_load
{
    # tests system-load interval-1
    if $API exists $WDT_PATH tests system-load interval-1; then
        LOAD_1=$($API returnValue $WDT_PATH tests system-load interval-1)
        write_cfg "max-load-1 = $LOAD_1"
    fi

    # tests system-load interval-5
    if $API exists $WDT_PATH tests system-load interval-5; then
        LOAD_5=$($API returnValue $WDT_PATH tests system-load interval-5)
        write_cfg "max-load-5 = $LOAD_5"
    fi

    # tests system-load interval-15
    if $API exists $WDT_PATH tests system-load interval-15; then
        LOAD_15=`$API returnValue $WDT_PATH tests system-load interval-15`
        write_cfg "max-load-1 = $LOAD_15"
    fi
}

# Setup ping test
function config_ping
{
    ping_list=$($API returnValues $WDT_PATH tests ping address)
    eval "PING_HOSTS=($ping_list)"

    for i in "${PING_HOSTS[@]}"; do
        write_cfg "ping = $i"
    done
}

# Setup user defined test
function config_user_defined
{
    TEST_EXECUTABLE=$($API returnValue $WDT_PATH tests user-defined executable)
    TEST_TIMEOUT=$($API returnValue $WDT_PATH tests user-defined timeout)

    if [ -z $TEST_EXECUTABLE ]; then
        echo "Test executable must be defined"
        exit 1
    fi

    write_cfg "test-binary = $TEST_EXECUTABLE"
    write_cfg "test-timeout = $TEST_TIMEOUT"
}

# system watchdog driver
$API exists $WDT_PATH driver
if [ $? == 0 ]; then
    load_module
fi


## system watchdog tests
#$API exists $WDT_PATH tests
if $API exists $WDT_PATH tests; then
    # system watchdog tests free-memory
    if $API exists $WDT_PATH tests free-memory; then
        config_freemem
    fi

    # system watchdog tests system-load
    if $API exists $WDT_PATH tests system-load; then
        config_max_load
    fi

    # system watchdog tests ping
    if $API exists $WDT_PATH tests ping; then
        config_ping
    fi

    # system watchdog tests user-defined
    if $API exists $WDT_PATH tests user-defined; then
        config_user_defined
    fi
fi
