vyatta-watchdog
===============

Vyatta watchdog configuration templates and scripts

Depends on Linux watchdog daemon (available from the repos).

Configuration commands:

system
  watchdog
    driver <module name>
    options
      realtime
      reset-interval <1-60, seconds>
    repair
      executable <file path>
      timeout <integer, seconds>
    tests
      free-memory <integer, megabytes>
      process
        service
          bgp
          ntp
          ospf
          rip
          routing-engine
          ssh
        user-defined
          pid-file <file path>
      system-load
        interval-1  <integer>
        interval-5  <integer>
        interval-15 <integer>
      user-defined
        executable <file path>
        timeout <integer, seconds>
    
## driver

On many systems watchdog module may not be compiled into the kernel.
This option allows to specify the module to load. It can not guess,
which one you need, you should find it yourself. E.g. here:
http://cateee.net/lkddb/web-lkddb/

This is only relevant to Vyatta as it runs on a wide range of
hardware. EdgeOS has drivers for supported hardware built into
the kernel.

## options

### realtime
Locks the watchdog daemon into memory and ensures
it's never swapped so it can do its job even under high load.
This is recommended.

### reset-interval
Time interval the daemon kicks the dog.
Unless you are having problems with specific driver,
you likely have no reason to change it. Default is one second.

Example:
set system watchdog options realtime
set system watchdog options reset-interval 10

## repair

Executes repair program instead of resetting the system
(e.g. soft reload or script to restart failed daemons).

If timeout it set to zero, repair program is allowed to
run for arbitrary time. Otherwise if repair program
does not terminate before timeout is exceeded,
the system will be rebooted.

If it terminates with non-zero exit code, the system
also reboot.

Example:
set system watchdog repair executable /config/scripts/repair
set system watchdog repair timeout 60

## tests

If one or more tests fail, the system is rebooted or
repair program is executed.

### free-memory

Amount of memory in megabytes that should stay free.

Example:
set system watchdog tests free-memory 50

### process

Check is a process is still running. Built-in critical
services are predefined, but you can specify custom
PID files too.

#### service

bgp             Border Gateway Protocol
ntp             Network Time Protocol 
ospf            Open Shortest Path First protocol version 2
rip             Routing Information Protocol version 2 daemon
routing-engine  Routing control plane
ssh             Secure SHell

Example:
set system watchdog tests process service bgp
set system watchdog tests process service routing-engine

### user-defined pid-file

Custom PID file.

Example:
set system watchdog tests process user-defined pid-file /var/run/mydaemon.pid

### system-load

Check system load in specified interval.

interval-1   Load average for the last minute
interval-5   Load average for the last 5 minutes
interval-15  Load average for the last 15 minutes

Example:
set system watchdog tests system-load interval-5 10

### user-defined

User defined test program.

If it terminates with zero exit code, the test is successfull,
othersie it's unsuccessfull. If the test is unsuccessfull,
action (reboot or repair program execution) is taken.

If tests fails to complete before timeout is exceeded,
it also considered unsuccessfull.

Default timeout is 0 (unlimited).

Example:
set system watchdog tests user-defined executable /config/scripts/mytest
set system watchdog tests user-defined timeout 30

## Complete example

system {
     watchdog {
         options {
             realtime
         }
         tests {
             free-memory 50
             process {
                 service {
                     routing-engine
                     ssh
                 }
             }
             system-load {
                 interval-5 10
             }
         }
     }
 }

