# Disable the screensaver.
xset s noblank
xset s off

# Load UK keymap.
setxkbmap gb

# Set an aggressive key repeat rate.
xset r rate 200 50

# Launch sxhkd and bspwm.
sxhkd &
exec bspwm
