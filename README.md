#### shot - screenshot / video capture tool based on scrot and recordmydesktop

* Short commands, easily bindable to key shortcuts
* Same commands to do both screenshot and videoshot
* Nice date in shot title by default (20131212_032511)
* No question mode (-q) = quick screenshots
* -c copies path of shot to clipboard

#### Examples that you can bind to key shortcuts

```bash
# Capture shot focused window, and copy shot path to clipboard
shot.sh -c
```

```bash
# Capture shot whole screen
shot.sh -w
```

```bash
# Record video focused window, and copy shot path to clipboard
shot.sh -c -r
```

```bash
# Record video whole screen
shot.sh -r -w
```

```bash
# Capture shot focused window, but unnamed
shot.sh -q
```

```bash
# Browse shots directory
shot.sh -b
```

#### Synopsis

```
shot.sh [-hbrRswqc] [name]
    -b   : browse shots directory (~/shots by default)
    -r   : video instead of screenshot
    -R   : video (with sound) instead of screenshot
    -s   : select manualy window instead of focused window
    -w   : whole screen instead of focused window
    -q   : do not ask filename
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified
```

By default it creates files like 20131211_153611_nameyouentered.png

#### Dependencies

Dependencies:
* scrot
* xclip

Additional dependencies for videoshot:
* recordmydesktop
* xwininfo
* xdotool
