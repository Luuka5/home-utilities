#!/bin/bash

STATUS_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/statusbar"

#STATUS="$(find "$STATUS_DIR" -type f -exec cat {} \; -exec echo -n "  " \;)"


STATUS=""
for file in "$STATUS_DIR"/*; do
    [ -f "$file" ] && STATUS="${STATUS}  $(cat "$file")"
done

BATTERY=""
# Battery status script - finds first system battery and shows percentage with status
#
# Find the system batteries
for ps in /sys/class/power_supply/*; do
    # Check if scope is System
    scope=$(cat "$ps/scope" 2>/dev/null)
    
    if [ "$scope" = "System" ]; then
        # Get battery percentage
        capacity=$(cat "$ps/capacity" 2>/dev/null)

        # Get charging status
        status=$(cat "$ps/status" 2>/dev/null)
        
        if [ -n "${capacity:-00}" ] && [ -n "$status" ]; then
            # Determine battery icon based on capacity
            if [ "$capacity" -le 10 ]; then
                icon=$(printf '\uf244')  # nf-fa-battery_0
            elif [ "$capacity" -le 35 ]; then
                icon=$(printf '\uf243')  # nf-fa-battery_1
            elif [ "$capacity" -le 60 ]; then
                icon=$(printf '\uf242')  # nf-fa-battery_2
            elif [ "$capacity" -le 85 ]; then
                icon=$(printf '\uf241')  # nf-fa-battery_3
            else
                icon=$(printf '\uf240')  # nf-fa-battery_4
            fi
            
            # Format the status text
            case "$status" in
                "Charging")
			status_text="$(printf '\uf0e7')"
                    ;;
                "Discharging")
			status_text=""
                    ;;
                "Full")
			status_text="$(printf '\ueb2d')"
                    ;;
                "Not charging")
			status_text="$(printf '\ueb2d')"
                    ;;
                *)
                    status_text="$status"
                    ;;
            esac
          
            # Set the variable and output
            BATTERY="$BATTERY  ${capacity}% ${icon} ${status_text}"
        fi
    fi
done

# Network status script - warns if disconnected 

# No active connection found
if ip a | grep -q " UP " ; then
    NETWORK="  $(printf '\uead0')"
fi

dwlb -status all "$STATUS$BATTERY$NETWORK  $(date '+%H:%M')"

