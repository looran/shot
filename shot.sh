#!/bin/sh

# shot - screenshot / video capture wrapper tool using maim, ksnip and recordmydesktop
# This file is licensed under the ISC license. Please see COPYING for more information.

# Dependencies:
# * ksnip (capture and edit screenshot)
# * xclip (copy file path to copypaste buffer)
# * zenity (interactive window)
# * xdotool (get active window)
# Additional dependencies for videoshot:
# * recordmydesktop
# * gnome-terminal (because the subprocess is started in hardcoded terminal)
# * xwininfo (select a window)

SHOTDIR="$HOME/shots"

set -e

header() {
    cat <<_EOF
shot - screenshot / video capture tool based on scrot and recordmydesktop
2013, 2016, 2018, 2019, Laurent Ghigonis <laurent@ooookiwi@gmail.com>
_EOF
}

usage() {
    cat <<_EOF
$program [-hbBrRswqce] [name]
    -B   : edit last shot
    -r   : video instead of screenshot
    -R   : video (with sound) instead of screenshot
    -s   : select manualy window instead of focused window
    -w   : whole screen instead of focused window
    -q   : do not ask filename
    -C   : don't copy shot path to clipboard
    -e   : execute command (%f=shot_path, %n=filename, %d=shot_date, %i=infos)
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified

By default it creates files like 20131211_133615_nameyouentered.png
_EOF
}

examples() {
    cat <<_EOF
Example key shortcuts for your window manager:
WIN + c         : shot       (Capture shot focused window)
WIN + SHIFT + c : shot -w    (Capture shot whole screen)
WIN + r         : shot -r    (Record video focused window)
WIN + SHIFT + r : shot -r -w (Record video whole screen)
WIN + ALT + c   : shot -b    (Browse shots directory)
WIN + g         : shot -q    (Capture shot focused window, but unnamed)
By using -c it also copies the path of the shot to the clipboard.
_EOF
}

trace() {
    echo "$ $*"
    "$@"
}

make_screenshot() {
    opts="-u"
    if [ $select -eq 1 ]; then
        opts=$opts" -s"
    elif [ $screen -eq 0 ]; then
        opts=$opts" -i $(xdotool getactivewindow)"
    fi
	echo $opts
    trace maim $opts $filename_tmp
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
    if [ $video_sound -eq 0 ]; then
		opts="$opts --no-sound"
	else
		opts="$opts --device pulse"
	fi
    trace gnome-terminal --geometry 70x5 --wait -- sh -c "\
	echo -e \">>> To normally end a recording you can press ctrl-c <<<\n\n\"; \
	recordmydesktop $opts -o $filename_tmp; \
	echo -e \"\n>>> Capture ended <<<\"; \
	read a"
}

program="$(basename "$0")"

edit_last=0
video=0
video_sound=0
select=0
screen=0
noname=0
clip=1
execute=0
execute_command=""
opts="$(getopt -o hbBrRswqCe: -n "$program" -- "$@")"
err=$?
eval set -- "$opts"
while true; do case $1 in
    -h) header; echo; usage; echo; examples; exit 0;;
    -B) edit_last=1; shift ;;
    -r) video=1; shift ;;
    -R) video=1; video_sound=1; shift ;;
    -s) select=1; shift ;;
    -w) screen=1; shift ;;
    -q) noname=1; shift ;;
    -C) clip=0; shift ;;
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

if [ $edit_last -eq 1 ]; then
	name_base="$(ls -tr $SHOTDIR |tail -n1)"
    [ -z "$name_base" ] && echo "ERROR: no last shot !" && exit 1
	name_edit="$(basename $name_base .png)_edited"
	sed -i "s#SaveDirectory=.*#SaveDirectory=$SHOTDIR#" $HOME/.config/ksnip/ksnip.conf
	sed -i "s/SaveFilename=.*/SaveFilename=$name_edit/" $HOME/.config/ksnip/ksnip.conf
    ksnip -e "$SHOTDIR/$name_base"
    if [ $clip -eq 1 ]; then
		echo -n "$SHOTDIR/$(ls -tr $SHOTDIR |tail -n1)" |xclip -selection clipboard
	fi
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
