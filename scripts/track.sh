#!/bin/bash

if [ ! "$1" = "--" ]; then
	STATUS="$1"
	shift 1
fi

if [ ! "$1" = "--" ]; then
	SLEEP="$1"
	shift 1
fi

if [ ! "$1" = "--" ]; then
	ID="$1"
	shift 1
fi

shift 1

STATUS_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/statusbar"
COMMAND="$1"

STATUS="${STATUS:-$COMMAND}"

FILE="$STATUS_DIR/${ID:-$COMMAND}"

mkdir -p $STATUS_DIR
echo "$STATUS" > "$FILE"
MODIFY="$(stat "$FILE" | grep "Modify")"
status

"$@"
EXIT_CODE=$?

(
	sleep ${SLEEP:-"0"}
	if [ "$MODIFY" = "$(stat "$FILE" | grep "Modify")" ]; then
		rm "$FILE"
	fi
	status
) &

exit $EXIT_CODE
