#### shot - screenshot / video capture tool based on ksnip and recordmydesktop

* Explicit commands: `shot image window`, `show video screen`
* Asks the image title after the shot
* Coherent command between image and video shot
* Date prefix in shot title `20131212_032511`
* copies path of shot to clipboard
* -x executes command after shot

Screenshot are named as follows: `<YYYYMMDD_HHMMSS>_<titled_you_entered>.png`

#### Usage

```
shot [-ehqsC] [-x <command>] (image selection|window|screen|allscreens | video window|screen) [name]
options
    -e   : edit screenshot after capture, can be specified alone
    -h   : show extended help
    -q   : do not ask filename
    -s   : enable sound for video
    -C   : don't copy shot path to clipboard
    -x <command>  : execute command (%f=shot_path, %n=filename, %d=shot_date, %i=file_infos)
    name : optional, prepended to filename after date
           if not specified, will be asked using Zenity if -q not specified
Screenshot are named as follows: <YYYYMMDD_HHMMSS>_<titled_you_entered>.png in SHOTDIR=$HOME/shots
```

#### Dependencies

See shot.sh
