#!/bin/sh

# shot - screenshot / video capture tool based on scrot and recordmydesktop
# This file is licensed under the ISC license. Please see COPYING for more information.

# Dependencies:
# * scrot
# * xclip
# * zenity
# Additional dependencies for videoshot:
# * recordmydesktop
# * xwininfo
# * xdotool

SHOTDIR="$HOME/shots"

header() {
    cat <<_EOF
shot - screenshot / video capture tool based on scrot and recordmydesktop
2013, 2016, 2018, Laurent Ghigonis <laurent@gouloum.fr>
_EOF
}

usage() {
    cat <<_EOF
$program [-hbBrRswqce] [name]
    -b   : browse shots directory ($SHOTDIR)
    -B   : open last shot with shutter
    -r   : video instead of screenshot
    -R   : video (with sound) instead of screenshot
    -s   : select manualy window instead of focused window
    -w   : whole screen instead of focused window
    -q   : do not ask filename
    -c   : copy shot path to clipboard
    -e   : execute command (%f=shot_path, %n=filename, %d=shot_date, %i=infos)
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified

By default it creates files like 20131211_133615_nameyouentered.png
_EOF
}

examples() {
    cat <<_EOF
Example key shortcuts for your window manager:
WIN + c         : shot -c       (Capture shot focused window)
WIN + SHIFT + c : shot -c -w    (Capture shot whole screen)
WIN + r         : shot -c -r    (Record video focused window)
WIN + SHIFT + r : shot -c -r -w (Record video whole screen)
WIN + ALT + c   : shot -b       (Browse shots directory)
WIN + g         : shot -c -q    (Capture shot focused window, but unnamed)
By using -c it also copies the path of the shot to the clipboard.
_EOF
}

trace() {
    echo "$ $*"
    "$@"
}

make_screenshot() {
    opts="-b"
    if [ $select -eq 1 ]; then
        opts=$opts" -s"
    elif [ $screen -eq 0 ]; then
        opts=$opts" -u"
    fi
    trace scrot $opts $filename_tmp
}

make_videoshot() {
    opts=""
    if [ $select -eq 1 ]; then
        winid=$(xwininfo | awk '/Window id:/ {print $4}')
        opts="--windowid $winid"
    elif [ $screen -eq 0 ]; then
        winid=$(xdotool getmouselocation --shell 2>/dev/null |grep WINDOW |sed 's".*=\(.*\)"\1"')
        opts="--windowid $winid"
    fi
    [ $video_sound -eq 0 ] && opts="$opts --no-sound"
    trace xterm -geometry 70x5 -e " \
	echo -e \">>> To normally end a recording you can press ctrl-c <<<\n\n\"; \
	recordmydesktop $opts -o $filename_tmp; \
	echo -e \"\n>>> Capture ended <<<\"; \
	read a"
}

program="$(basename "$0")"

browse=0
browse_last=0
video=0
video_sound=0
select=0
screen=0
noname=0
clip=0
execute=0
execute_command=""
opts="$(getopt -o hbBrRswqce: -n "$program" -- "$@")"
err=$?
eval set -- "$opts"
while true; do case $1 in
    -h) header; echo; usage; echo; examples; exit 0;;
    -b) browse=1; shift ;;
    -B) browse_last=1; shift ;;
    -r) video=1; shift ;;
    -R) video=1; video_sound=1; shift ;;
    -s) select=1; shift ;;
    -w) screen=1; shift ;;
    -q) noname=1; shift ;;
    -c) clip=1; shift ;;
    -e) execute=1; shift; execute_command=$1; shift ;;
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
    xdg-open $SHOTDIR &
    exit 0
elif [ $browse_last -eq 1 ]; then
    last="$SHOTDIR/$(ls $SHOTDIR |tail -n1)"
    [ -z "$last" ] && echo "ERROR: no last shot !" && exit 1
    shutter -e -n --disable_systray $last &
    exit 0
fi

umask 0077
filename_tmp=$(mktemp -u "/tmp/shotXXXXX")
now=$(date +%Y%m%d_%H%M%S)
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
    [ ! -z "$name" ] && name="_$name"
    filename="${fileprefix}$(echo $name |sed s/" "/"_"/g).${filesuffix}"
else
    filename="${fileprefix}.${filesuffix}"
fi
mv $filename_tmp $filename

if [ $clip -eq 1 ]; then
    echo -n "$filename" | xclip -selection clipboard
fi

if [ $noname -ne 1 ]; then
    echo "created $filename ($info)"
    notify-send "created $(basename ${filename})" "($info)" &
fi

if [ $execute -eq 1 ]; then
    f="$(echo $filename |sed 's/[\&/]/\\&/g')"
    n=$(basename $filename)
    d="$now"
    i="$info"
    command=$(echo $execute_command |sed "s/"%f"/${f}/g" |sed "s/"%n"/${n}/g" |sed "s/"%d"/${d}/g" |sed "s/"%i"/${i}/g")
    echo "running $command"
    eval $command
fi
