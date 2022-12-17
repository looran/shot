#!/bin/bash

# shot - screenshot / video capture tool based on ksnip and recordmydesktop
# 2013-2022 Laurent Ghigonis <ooookiwi@gmail.com>
# This file is licensed under the ISC license. Please see LICENSING file for more information.

# Dependencies:
# * ksnip (capture and edit screenshot), tested with version from git 20220322
# * xclip (copy file path to copypaste buffer)
# * kdialog (interactive window to ask screenshot name)
# Additional dependencies for videoshot:
# * recordmydesktop
# * xdotool (get active window)
# * xwininfo (select a window)
# * xterm (because the subprocess is started in hardcoded terminal)

SHOTDIR="${SHOTDIR-$HOME/shots}"
KSNIP_CONFIG=$HOME/.config/ksnip/ksnip.conf
PROG="$(basename "$0")"

set -e

usage() {
    cat <<_EOF
$PROG [-ehqsC] [-x <command>] (image selection|window|screen|allscreens | video selection|window|screen) [name]
options
    -e   : edit screenshot after capture, can be specified alone
    -h   : show extended help
    -q   : do not ask filename
    -s   : enable sound for video
    -C   : don't copy shot path to clipboard
    -x <command>  : execute command (%f=shot_path, %n=filename, %d=shot_date, %i=file_infos)
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified
Screenshot are named as follows: <YYYYMMDD_HHMMSS>_<titled_you_entered>.png in SHOTDIR=$SHOTDIR
_EOF
}

examples() {
    cat <<_EOF
Example key shortcuts for your window manager:
WIN + c         : shot image window		(Capture screenshot of focused window)
WIN + SHIFT + c : shot image selection	(Capture screenshot of custom selection)
WIN + g         : shot -q shot screen	(Capture screenshot of current window, quietly without asking for name)
WIN + r         : shot video window		(Record video of focused window)
WIN + SHIFT + r : shot video screen		(Record video of whole screen)
WIN + ALT + c   : shot edit				(edit last screenshot)
_EOF
}

trace() {
    echo "$ $*" >&2
    "$@"
}

clipboard_set() {
	local content="$1"
	echo -n "$content" |trace xclip -selection clipboard
}

#ksnip_set_savefile() {
#	local path="$1"
#	sed -i "s#SaveDirectory=.*#SaveDirectory=$(dirname $path)#" $KSNIP_CONFIG
#	sed -i "s/SaveFilename=.*/SaveFilename=$(basename ${path%.*})/" $KSNIP_CONFIG
#}

screenshot_edit() {
	local path="$1"
	[ ! -e "$path" ] && echo "ERROR: screenshot to edit does not exist ! ($path)" && exit 1
#	path_edit="${path%.*}_edited.png"
#	ksnip_set_savefile "$path_edit"
	trace ksnip "$path"
	[ $clip -eq 1 ] && clipboard_set "$path"
}

waitfile() {
	path="$1"
	until [ -f "$path" ]; do sleep 0.3; echo .; done
}

video_sound=0
quiet=0
clip=1
edit=0
execute=""
opts="$(getopt -o ehqsCx: -n "$PROG" -- "$@")"
err=$?
eval set -- "$opts"
while true; do case $1 in
    -h) echo "screenshot / video capture tool based on ksnip and recordmydesktop"; echo; usage; echo; examples; exit 0 ;;
	-e) edit=1; shift ;;
    -q) quiet=1; shift ;;
    -s) video_sound=1; shift ;;
    -C) clip=0; shift ;;
    -x) execute="$2"; shift; shift ;;
    --) shift; break ;;
esac done
[ $err -ne 0 ] && usage && exit 1
[ $edit -eq 1 -a $# -eq 0 ] && screenshot_edit "$SHOTDIR/$(ls -tr $SHOTDIR |tail -n1)" && exit 0
[ $# -lt 2 -o $# -gt 3 ] && usage && exit 1
if [ ! -d $SHOTDIR ]; then
    mkdir $SHOTDIR ||exit
fi
name=""
action=$1
target=$2
[ $# -eq 3 ] && name="$3"
umask 0077
path_tmp=$(mktemp -u "/tmp/shotXXXXX")
now=$(date +%Y%m%d_%H%M%S)

case $action in
	i|img|image)
		extension="png"
		path_tmp=$path_tmp".png"
		action="screenshot"
		opts="-s"
		[ $target = "selection" ] && opts="$opts -r"
		[ $target = "window" ] && opts=$opts" -a"
		[ $target = "screen" ] && opts=$opts" -m"
		[ $target = "allscreens" ] && opts=$opts" -f"
#		ksnip_set_savefile $path_tmp
		trace ksnip $opts -p "$path_tmp" &
		waitfile $path_tmp
		;;
	v|vid|video) 
		extension="ogv"
		path_tmp=$path_tmp".ogv"
		action="videoshot"
		if [ $target = "selection" ]; then
			winid=$(xwininfo | awk '/Window id:/ {print $4}')
			opts="--windowid $winid"
		elif [ $target = "window" ]; then
			winid=$(xdotool getmouselocation --shell 2>/dev/null |grep WINDOW |sed 's".*=\(.*\)"\1"')
			opts="--windowid $winid"
		elif [ $target = "screen" ]; then
			opts=""
		else
			usage && exit 1
		fi
		if [ $video_sound -eq 0 ]; then
			opts="$opts --no-sound"
		else
			opts="$opts --device pulse"
		fi
		trace xterm -geometry 100x20+0-30 -e sh -c "\
		echo -e \">>> To normally end a recording you can press ctrl-c <<<\n\n\"; \
		recordmydesktop $opts -o $path_tmp; \
		echo -e \"\n>>> Capture ended <<<\"; \
		read a"
		;;
	*)
		usage && exit 1
	;;
esac
file_info=$(ls -sh $path_tmp |cut -d' ' -f1)

if [ ! -z "$name" ]; then
    filename="${now}_$(echo $name |sed s/" "/"_"/g).${extension}"
elif [ $quiet -eq 0 ]; then
    name=$(kdialog --inputbox "$action name ($file_info)" --title="shot")
    [ ! -z "$name" ] && name="_$name"
    filename="${now}$(echo $name |sed s/" "/"_"/g).${extension}"
else
    filename="${now}.${extension}"
fi
path="$SHOTDIR/$filename"
trace mv "$path_tmp" "$path"

[ $edit -eq 1 ] && screenshot_edit $path
[ $clip -eq 1 ] && clipboard_set $path

if [ $quiet -eq 0 ]; then
    echo "created $path ($file_info)"
    notify-send "created $(basename ${path})" "($file_info)" &
fi

if [ ! -z "$execute" ]; then
    f="$(echo $path |sed 's/[\&/]/\\&/g')"
    n=$(basename $path)
    d="$now"
    i="$file_info"
    command=$(echo "$execute" |sed "s/"%f"/${f}/g" |sed "s/"%n"/${n}/g" |sed "s/"%d"/${d}/g" |sed "s/"%i"/${i}/g")
    echo "running $command"
    $command
fi
