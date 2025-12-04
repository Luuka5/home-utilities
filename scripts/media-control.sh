#!/bin/bash
# Media control script with fallback player
# Usage: media-control {play-pause|next|prev|play|pause|stop|volume|status}

# Configuration - set your preferred fallback player command
FALLBACK_PLAYER="spotify"  # or "vlc", "rhythmbox", etc.

get_active_player() {
    # Get all MPRIS2 players
    players=$(busctl --user list 2>/dev/null | grep 'org.mpris.MediaPlayer2\.' | awk '{print $1}')
    
    if [ -z "$players" ]; then
        return 1
    fi
    
    # First, check for any playing player
    for player in $players; do
        status=$(busctl --user get-property "$player" /org/mpris/MediaPlayer2 \
            org.mpris.MediaPlayer2.Player PlaybackStatus 2>/dev/null | awk '{print $2}' | tr -d '"')
        if [ "$status" = "Playing" ]; then
            echo "$player"
            return 0
        fi
    done
    
    # If nothing playing, check for paused players
    for player in $players; do
        status=$(busctl --user get-property "$player" /org/mpris/MediaPlayer2 \
            org.mpris.MediaPlayer2.Player PlaybackStatus 2>/dev/null | awk '{print $2}' | tr -d '"')
        if [ "$status" = "Paused" ]; then
            echo "$player"
            return 0
        fi
    done
    
    # If no playing/paused, return first available player
    echo "$players" | head -n1
    return 0
}

send_command() {
    local player=$1
    local method=$2
    
    dbus-send --print-reply --dest="$player" \
        /org/mpris/MediaPlayer2 \
        "org.mpris.MediaPlayer2.Player.$method" >/dev/null 2>&1
}

adjust_volume() {
    local delta=$1
    
    # Check if wpctl is available
    if ! command -v wpctl &> /dev/null; then
        echo "Error: wpctl not found. Please install pipewire-tools/wireplumber"
        exit 1
    fi
    
    # Get default sink (audio output)
    # First isolate the Sinks section, then find the line with asterisk
    local sink=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep '\*' | awk '{print $3}' | tr -d '.')
    
    if [ -z "$sink" ]; then
        echo "Error: Could not find default audio sink"
        exit 1
    fi
    
    # Adjust volume using wpctl
    # wpctl accepts volume changes like "5%+" or "5%-"
    if [ "$delta" -gt 0 ]; then
        wpctl set-volume "$sink" "${delta}%+"
    else
        # Remove the minus sign for the command
        local abs_delta=${delta#-}
        wpctl set-volume "$sink" "${abs_delta}%-"
    fi
    
    # Get and display new volume
    local volume_info=$(wpctl get-volume "$sink")
    echo "Volume: $volume_info"
}

start_fallback_player() {
    echo "No active players found. Starting $FALLBACK_PLAYER..."
    
    case "$FALLBACK_PLAYER" in
        spotify)
            if command -v spotify &> /dev/null; then
                spotify &
                disown
            else
                echo "Error: Spotify not found"
                exit 1
            fi
            ;;
        vlc)
            if command -v vlc &> /dev/null; then
                vlc &
                disown
            else
                echo "Error: VLC not found"
                exit 1
            fi
            ;;
        rhythmbox)
            if command -v rhythmbox &> /dev/null; then
                rhythmbox &
                disown
            else
                echo "Error: Rhythmbox not found"
                exit 1
            fi
            ;;
        *)
            echo "Error: Unknown fallback player: $FALLBACK_PLAYER"
            exit 1
            ;;
    esac
    
    # Wait a moment for player to register on D-Bus
    sleep 2
    
    # Try to get the new player
    PLAYER=$(get_active_player)
    if [ -z "$PLAYER" ]; then
        echo "Error: Failed to detect started player"
        exit 1
    fi
}

# Main logic
ACTION=$1
VOLUME_DELTA=$2

if [ -z "$ACTION" ]; then
    echo "Usage: $0 {play-pause|next|prev|play|pause|stop|volume <delta>|status}"
    echo "  volume <delta>: Adjust volume by percentage (e.g., +5, -10)"
    exit 1
fi

# Get active player
PLAYER=$(get_active_player)

# If no player found and action is play-related, start fallback
if [ -z "$PLAYER" ]; then
    if [ "$ACTION" = "play-pause" ] || [ "$ACTION" = "play" ]; then
        start_fallback_player
    else
        echo "No active media players found"
        exit 1
    fi
fi

# Execute the requested action
case "$ACTION" in
    play-pause)
        send_command "$PLAYER" "PlayPause"
        ;;
    next)
        send_command "$PLAYER" "Next"
        ;;
    prev|previous)
        send_command "$PLAYER" "Previous"
        ;;
    play)
        send_command "$PLAYER" "Play"
        ;;
    pause)
        send_command "$PLAYER" "Pause"
        ;;
    stop)
        send_command "$PLAYER" "Stop"
        ;;
    volume)
        if [ -z "$VOLUME_DELTA" ]; then
            echo "Error: volume action requires a delta value"
            echo "Usage: $0 volume <delta> (e.g., $0 volume +5 or $0 volume -10)"
            exit 1
        fi
        adjust_volume "$VOLUME_DELTA"
        ;;
    status)
        if [ -n "$PLAYER" ]; then
            echo "Active player: $PLAYER"
            status=$(busctl --user get-property "$PLAYER" /org/mpris/MediaPlayer2 \
                org.mpris.MediaPlayer2.Player PlaybackStatus 2>/dev/null | awk '{print $2}' | tr -d '"')
            echo "Status: $status"
        fi
        ;;
    *)
        echo "Unknown action: $ACTION"
        echo "Usage: $0 {play-pause|next|prev|play|pause|stop|volume <delta>|status}"
        exit 1
        ;;
esac
