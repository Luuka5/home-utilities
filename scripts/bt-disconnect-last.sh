#!/bin/bash

STATUS_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/statusbar/bt-disconnect-last.txt"
echo "-$(printf '\uf294')" > "$STATUS_FILE"
status

# Get the most recently connected device from bluetoothctl
DEVICE=$(bluetoothctl devices | while read -r _ mac name; do
    # Check if device is paired and get its info
    if bluetoothctl info "$mac" | grep -q "Paired: yes"; then
        echo "$mac"
        break
    fi
done | head -1)

if [ -n "$DEVICE" ]; then
    echo "Connecting to last connected device: $DEVICE"
    bluetoothctl disconnect "$DEVICE"
else
    echo "No previously connected device found"
fi

sleep 0.5
rm "$STATUS_FILE"

status
