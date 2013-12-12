### shot - screenshot / video capture tool based on scrot and recordmydesktop

#### Examples that you can bind to key shortcuts

```bash
# Capture shot focused window
shot.sh
```

```bash
# Capture shot whole screen
shot.sh -w
```

```bash
# Record video focused window
shot.sh -r
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
shot.sh [-h] [-r] [-w | -s] [-q] [-a] [name]
    -b   : browse shots directory ($SHOTDIR)
    -r   : video instead of screenshot
    -s   : select manualy window instead of focused window
    -w   : whole screen instead of focused window
    -q   : do not ask filename
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified
```

By default it creates files like 20131211_153611_nameyouentered.png

