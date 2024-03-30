#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"

fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

xset -b

xinput --set-prop 'SynPS/2 Synaptics TouchPad' 'libinput Accel Speed' -0.2
xinput --set-prop 'SynPS/2 Synaptics TouchPad' 'libinput Natural Scrolling Enabled' 1

xinput --set-prop 'ETPS/2 Elantech TrackPoint' 'libinput Natural Scrolling Enabled' 1
xinput --set-prop 'ETPS/2 Elantech Touchpad' 'libinput Natural Scrolling Enabled' 1

xinput --set-prop 'Logitech USB Receiver Mouse' 'libinput Accel Speed' -0.9
xinput --set-prop 'Logitech USB Receiver Mouse' 'libinput Natural Scrolling Enabled' 1

unclutter --start-hidden &
numlockx &
xterm &

exec awesome
