#!/usr/bin/env bash
# From ML: jonas@cowboyprogrammer.org
# An option which combines "pass generate" with "pass edit" would be great. 

# A simple wrapper for pass edit. Takes one argument, and that is the
# password file to open (which can be new). As a convenience, a new
# password is generated and placed in the clipboard so you can paste
# it with Mouse3.

if [ $# -eq 0 ]; then
echo "No arguments provided"
exit 1
fi

CLIP_TIME=45

# Borrowing from pass
clip() {
# This base64 business is because bash cannot store binary data in a
# shell variable. Specifically, it cannot store nulls nor
# (non-trivally) store trailing new lines.
local sleep_argv0="password store sleep on display $DISPLAY"
local before
local now
pkill -f "^$sleep_argv0" 2>/dev/null && sleep 0.5
before="$(xclip -o -selection "$X_SELECTION" 2>/dev/null | base64)"
echo -n "$1" | xclip -selection "$X_SELECTION" || \
die "Error: Could not copy data to the clipboard"
(
( exec -a "$sleep_argv0" sleep "$CLIP_TIME" )
now="$(xclip -o -selection "$X_SELECTION" | base64)"
[[ $now != $(echo -n "$1" | base64) ]] && before="$now"

# It might be nice to programmatically check to see if klipper
# exists, as well as checking for other common clipboard
# managers. But for now, this works fine -- if qdbus isn't there
# or if klipper isn't running, this essentially becomes a no-op.
#
# Clipboard managers frequently write their history out in
# plaintext, so we axe it here:
qdbus org.kde.klipper \
/klipper org.kde.klipper.klipper.clearClipboardHistory \
&>/dev/null

echo "$before" | base64 -d | xclip -selection "$X_SELECTION"
) 2>/dev/null & disown
#echo "Copied $2 to clipboard. Will clear in $CLIP_TIME seconds."
}

# -B - don't use ambiguious characters
# -s - added randomness
# 20 chars long
# 1 output only
pw=$(pwgen -B -s 20 1)

# Copy password to clipboard
clip "$pw"

# Open editor, paste password with Mouse3
pass edit "$1"

