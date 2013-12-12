#!/bin/sh

# shot - screenshot / video capture tool based on scrot and recordmydesktop
# 2013, Laurent Ghigonis <laurent@gouloum.fr>
# This file is licensed under the ISC license. Please see COPYING for more information.

# Dependencies:
# * scrot
# * xprop
# Dependencies for videoshot:
# * recordmydesktop
# * xwininfo
# * xdotool

SHOTDIR="$HOME/shots"

header() {
    cat <<_EOF
shot - screenshot / video capture tool based on scrot and recordmydesktop
2013, Laurent Ghigonis <laurent@gouloum.fr>
_EOF
}

usage() {
    cat <<_EOF
$program [-h] [-r] [-w | -s] [-q] [-a] [name]
    -b   : browse shots directory ($SHOTDIR)
    -r   : video instead of screenshot
    -s   : select manualy window instead of focused window
    -w   : whole screen instead of focused window
    -q   : do not ask filename
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified

By default it creates files like 20131211_nameyouentered.png
_EOF
}

examples() {
    cat <<_EOF
Example key shortcuts for your window manager:
WIN + c         : shot.sh        (Capture shot focused window)
WIN + SHIFT + c : shot.sh -w     (Capture shot whole screen)
WIN + r         : shot.sh -r     (Record video focused window)
WIN + SHIFT + r : shot.sh -r -w  (Record video whole screen)
WIN + ALT + c   : shot.sh -b     (Browse shots directory)
WIN + g         : shot.sh -q     (Capture shot focused window, but unnamed)
_EOF
}

make_screenshot() {
    opts="-b"
    [ $screen -eq 0 ] && opts=$opts" -u"
    [ $select -eq 1 ] && opts=$opts" -s"
    scrot $opts $filename_tmp
}

make_videoshot() {
    opts=""
    if [ $select -eq 1 ]; then
        winid=$(xwininfo | awk '/Window id:/ {print $4}')
        opts="--windowid=$winid"
    elif [ $screen -eq 0 ]; then
        winid=$(xdotool getmouselocation --shell 2>/dev/null |grep WINDOW |sed 's".*=\(.*\)"\1"')
        opts="--windowid=$winid"
    fi
    xterm -e " \
echo -e \">>> To normally end a recording you can press ctrl-c <<<\n\n\"; \
recordmydesktop --no-sound $opts -o $filename_tmp; \
echo -e \"\n>>> Capture ended <<<\"; \
read a"
}

program="$(basename "$0")"

browse=0
video=0
select=0
screen=0
noname=0
opts="$(getopt -o brswqh -n "$program" -- "$@")"
err=$?
eval set -- "$opts"
while true; do case $1 in
    -b) browse=1; shift ;;
    -r) video=1; shift ;;
    -s) select=1; shift ;;
    -w) screen=1; shift ;;
    -q) noname=1; shift ;;
    -h) header; echo; usage; echo; examples; exit 0;;
    --) shift; break ;;
esac done

if [ $err -ne 0 -o $# -gt 1 ]; then
    usage && exit 1
fi
if [ $select -eq 1 -a $screen -eq 1 ]; then
    echo "Error: cannot use -r with -w" && exit 1
fi
if [ ! -d $SHOTDIR ]; then
    mkdir $SHOTDIR ||exit
fi

if [ $browse -eq 1 ]; then
    nautilus $SHOTDIR &
    exit 0
fi

umask 0002
filename_tmp=$(mktemp -u "/tmp/shotXXXXX")
now=$(date +%Y%m%d%H%M%S)
if [ $video -eq 0 ]; then
    filesuffix="png"
    filename_tmp=$filename_tmp".png"
    action="Screenshot"
    make_screenshot
else
    filesuffix="ogv"
    filename_tmp=$filename_tmp".ogv"
    action="Videoshot"
    make_videoshot
fi
info=$(ls -sh $filename_tmp |cut -d' ' -f1)

fileprefix=$SHOTDIR/${now}
if [ $# -eq 1 ]; then
    filename="${fileprefix}_$(echo $1 |sed s/" "/"_"/g).${filesuffix}"
elif [ $noname -eq 0 ]; then
    name=$(zenity --entry --text="$action name ($info)" --title="shot")
    [ ! -z $name ] && name="_$name"
    filename="${fileprefix}$(echo $name |sed s/" "/"_"/g).${filesuffix}"
else
    filename="${fileprefix}.${filesuffix}"
fi
mv $filename_tmp $filename

echo "created $filename ($info)"
zenity --notification --text="created ${filename}\n($info)" &
