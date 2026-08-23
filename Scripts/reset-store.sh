#!/bin/bash
# Clears the UniTrack database so the app returns to first-run setup.
#
# Use this when you cannot sign in. Passwords are hashed and cannot be
# recovered, and demo-mode accounts get a random password each launch that is
# never written down, so a reset is the way back in.
#
# The old store is moved aside rather than deleted, in case you want it back.
#
#   ./Scripts/reset-store.sh
set -euo pipefail

STORE="$HOME/Library/Application Support/UniTrack"

if [ ! -d "$STORE" ]; then
  echo "No store found. The app will show first-run setup on next launch."
  exit 0
fi

BACKUP="$HOME/Library/Application Support/UniTrack-backup-$(date +%Y%m%d-%H%M%S)"
mv "$STORE" "$BACKUP"

echo "Store moved to:"
echo "  $BACKUP"
echo
echo "Next launch will show 'Set Up UniTrack' so you can create an administrator."
echo "Delete the backup folder once you are sure you no longer need it."
