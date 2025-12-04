#!/bin/bash

ACTION="$1"

# Get the most recently connected device from bluetoothctl
DEVICE=$(bluetoothctl devices | while read -r _ mac _; do
    # Check if device is paired and get its info
    if bluetoothctl info "$mac" | grep -q "Paired: yes"; then
        echo "$mac"
        break
    fi
done | head -1)

if [ -n "$DEVICE" ]; then
    echo "Connecting to last connected device: $DEVICE"
    bluetoothctl "$ACTION" "$DEVICE"
else
    echo "No previously connected device found"
fi

