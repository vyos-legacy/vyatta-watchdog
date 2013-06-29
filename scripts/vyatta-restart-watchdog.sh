#!/bin/sh

if cli-shell-api existsActive system watchdog; then
   /etc/init.d/watchdog restart
else
   echo "Watchdog is not running"
fi

