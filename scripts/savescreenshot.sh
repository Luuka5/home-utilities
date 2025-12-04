#!/bin/bash
mkdir -p ~/Pictures/screenshots
file=~/Pictures/screenshots/screenshot-$(date +"%Y%m%d-%H%M%S").png
grim -g "$(slurp)" $file


