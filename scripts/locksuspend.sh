#!/bin/bash

/usr/local/bin/lock

systemctl suspend

sleep 1

killall kanshi
kanshi &
