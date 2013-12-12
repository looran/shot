shot - screenshot / video capture tool based on scrot and recordmydesktop

$program [-h] [-r] [-w | -s] [-q] [-a] [name]
    -b   : browse shots directory ($SHOTDIR)
    -r   : video instead of screenshot
    -s   : select manualy window instead of focused window
    -w   : whole screen instead of focused window
    -q   : do not ask filename
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified

By default it creates files like 20131211_nameyouentered.png

Example key shortcuts for your window manager:
WIN + c         : shot.sh        (Capture shot focused window)
WIN + SHIFT + c : shot.sh -w     (Capture shot whole screen)
WIN + r         : shot.sh -r     (Record video focused window)
WIN + SHIFT + r : shot.sh -r -w  (Record video whole screen)
WIN + ALT + c   : shot.sh -b     (Browse shots directory)
WIN + g         : shot.sh -q     (Capture shot focused window, but unnamed)
