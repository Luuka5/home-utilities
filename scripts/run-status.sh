#!/bin/bash

STATUS_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/statusbar"

mkdir -p $STATUS_DIR


(
# Make sure status is ran after dwl has started properly
status
sleep 1
status
sleep 1
status
sleep 1
status

while [ 1 ]; do
  status
  # Rerun always when the minute changes
  sleep $((60 - "$(date +%s)" % 60))
done

) &

(
	ip monitor | grep -e " UP " -e " DOWN " | while read line; do
		status
	done
) &

