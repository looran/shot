#### shot - screenshot / video capture tool based on scrot and recordmydesktop

* Short commands, easily bindable to key shortcuts
* Same commands to do both screenshot and videoshot
* Nice date in shot title by default (20131212_032511)
* No question mode (-q) = quick screenshots
* -c copies path of shot to clipboard
* -e executes command (%f will be the shot path)

#### Examples that you can bind to key shortcuts

```bash
# Capture shot focused window, and copy shot path to clipboard
shot -c
```

```bash
# Capture shot whole screen
shot -w
```

```bash
# Record video focused window, and copy shot path to clipboard
shot -c -r
```

```bash
# Record video whole screen
shot -r -w
```

```bash
# Capture shot focused window, but unnamed
shot -q
```

```bash
# Browse shots directory
shot -b
```

```bash
# Take a screenshot of focused window, upload it your website and copy URL to clipboard
shot -e 'xterm -e "scp %f _myserver:www/; echo 'http://myserver.fr/%n'; echo 'http://myserver.fr/%n' |xclip -selection clipboard; read a"'
```

#### Synopsis

```
shot [-hbrRswqce] [name]
    -b   : browse shots directory (/home/laurent/shots)
    -r   : video instead of screenshot
    -R   : video (with sound) instead of screenshot
    -s   : select manualy window instead of focused window
    -w   : whole screen instead of focused window
    -q   : do not ask filename
    -c   : copy shot path to clipboard
    -e   : execute command (%f=shot_path, %n=filename, %d=shot_date, %i=infos)
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified
```

By default it creates files like ```20131211_153611_nameyouentered.png```

#### Dependencies

On Ubuntu, just run ```sudo make linux-dependencies```

Dependencies:
* scrot
* xclip
* zenity

Additional dependencies for videoshot:
* recordmydesktop
* xwininfo (in x11-utils in Ubuntu)
* xdotool
