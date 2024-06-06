xhost +SI:localuser:$USER
export _JAVA_AWT_WM_NONREPARENTING=1
xsetroot -cursor_name left_ptr
# Set keyboard repeat rate.
#xset r rate 200 60

dropbox start

# tint2 &
# nm-tray &
caffeine-indicator &
emacs -f exwm-enable
