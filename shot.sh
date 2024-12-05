#!/bin/bash

# shot - screenshot / video capture tool based on spectacle and ffmpeg
# 2013-2024 Laurent Ghigonis <ooookiwi@gmail.com>

# Dependencies:
# * spectacle
# * xclip (copy file path to copypaste buffer)
# * kdialog (interactive window to ask screenshot name)
# Additional dependencies for videoshot:
# * ffmpeg
# * xdotool (get active window)
# * xwininfo (select a window)
# * xterm (because ffmpeg is started in new terminal)

SHOTDIR="${SHOTDIR-$HOME/shots}"
PROG="$(basename "$0")"

set -e

usage() {
    cat <<_EOF
$PROG [-hqC] [-x <command>] (image select|window|screen|allscreens [-e]) | (video select|window|screen [-s] | -e)
   -e : edit screenshot after capture
   -s   : enable sound for video
   -h   : show extended help
   -q   : do not ask filename after screenshot
   -C   : don't copy shot path to clipboard
   -x <command>  : execute command after screenshot
      %f=shot_path %n=filename %d=shot_date %i=file_infos
   name : optional, appended to filename after date
      if not specified, will be asked using Zenity if -q not specified
Screenshot are named as follows: <YYYYMMDD_HHMMSS>_<titled_you_entered>.png in SHOTDIR=$SHOTDIR
_EOF
}

examples() {
    cat <<_EOF
Example key shortcuts for your window manager:
WIN + c         : shot image window     (Capture screenshot of focused window)
WIN + SHIFT + c : shot image select     (Capture screenshot of custom selection)
WIN + g         : shot -q shot screen   (Capture screenshot of current window, quietly without asking for name)
WIN + r         : shot video window     (Record video of focused window)
WIN + SHIFT + r : shot video screen     (Record video of whole screen)
WIN + ALT + c   : shot -e               (edit last screenshot)
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

screenshot_edit() {
	local path="$1"
	[ ! -e "$path" ] && echo "ERROR: screenshot to edit does not exist ! ($path)" && exit 1
	trace spectacle -E "$path"
	[ $clip -eq 1 ] && clipboard_set "$path"
}

waitfile() {
	path="$1"
	until [ -f "$path" ]; do sleep 0.3; echo .; done
}

ffmpeg_get_opts() {
	x=$(xwininfo $@ |grep "Absolute upper-left X" |awk '{print $4}')
	y=$(xwininfo $@ |grep "Absolute upper-left Y" |awk '{print $4}')
	w=$(xwininfo $@ |grep Width |awk '{print $2}')
	h=$(xwininfo $@ |grep Height |awk '{print $2}')
	echo "-video_size ${w}x${h} -f x11grab -i $DISPLAY.0+${x},${y}"
}
win_active_id() {
	xdotool getmouselocation --shell 2>/dev/null |grep WINDOW |sed 's".*=\(.*\)"\1"'
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
    -h) usage; echo; examples; exit 0 ;;
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
path_tmp=$(mktemp -u "/var/tmp/shotXXXXX")
now=$(date +%Y%m%d_%H%M%S)

case $action in
	i|img|image)
		extension="png"
		path_tmp="$path_tmp.$extension"
		[ $target = "select" ] && opts="-r"
		[ $target = "window" ] && opts="-a"
		[ $target = "screen" ] && opts="-m"
		[ $target = "allscreens" ] && opts="-f"
		trace spectacle -n -b -S -o "$path_tmp" $opts
		#waitfile $path_tmp
		;;
	v|vid|video)
		extension="mp4"
		path_tmp="$path_tmp.$extension"
		if [ $target = "select" ]; then
			opts="$(ffmpeg_get_opts '')"
		elif [ $target = "window" ]; then
			opts="$(ffmpeg_get_opts -id $(win_active_id))"
		elif [ $target = "screen" ]; then
			opts="-f x11grab -i $DISPLAY.0"
		else
			usage && exit 1
		fi
		if [ $video_sound -eq 1 ]; then
			opts="$opts -f pulse -ac 2 -i default"
		fi
		trace xterm -geometry 100x20+0-30 -e sh -c "\
		echo -e \">>> To normally end a recording you can press ctrl-c <<<\n\n\"; \
		ffmpeg $opts -c:v libx264 $path_tmp; \
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
trace chmod 640 "$path"

[ $edit -eq 1 ] && screenshot_edit $path
[ $clip -eq 1 ] && clipboard_set $path

if [ $quiet -eq 0 ]; then
    echo "created $path ($file_info)"
    notify-send -i $path "created $(basename ${path})" "($file_info)" &
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
