#!/usr/bin/env bash

# Retrieve and Display meteogram
# ==============================
# Display meteogram for configurable time and then return focus back to iPTV player - see usage help

# version
#
VER=2022.01.03

# packages required
#
REQUIRES="pkg: wmctrl xautomation; script: meteogram.sh"

# author
#
AUTH='Robert'

# github repository
#
REPO="https://github.com/blue-sky-r/mpv-wifi-rc"

# copyright
#
COPY="= display meteogram = retrieve and display meteogram in viewer for defined time = (c) $VER by $AUTH = $REPO ="

# DEFAULTS #
#-----------

# browser width x height
#
#WxH=1920x1080		# technika TV
WxH=1280x720		  # Veriton TV

# border (svg will be smaller by border)
#
BORDER=25

# meteogram html title (by this title the meteogram browser window is focused)
#
TITLE="meteogram"

# meteogram html
#
RESULT=/tmp/meteogram.html

# firefox browser as svg/html fullscreen viewer
#
VIEWER=firefox
#
VIEWER_TITLE_SUFFIX="Mozilla Firefox"

# browser mode (kiosk is preferred)
#
#MODE='new-window'
MODE='kiosk'

# geo location
#
LOC="2-6167865"     # https://www.yr.no/en/forecast/graph/2-6167865/Canada/Ontario/Toronto
LOC="2-3061186"     # https://www.yr.no/en/forecast/daily-table/2-3061186/Slovakia/Banskobystrick%C3%BD%20kraj/Bansk%C3%A1%20Bystrica%20District/Bansk%C3%A1%20Bystrica

# language CC for meteogram translation
#
LANG_CC=SK

# time in seconds to show meteogram
#
SHOWFOR=20

# iptv player (mpv, by this title iPTV window is focused)
#
IPTV_TITLE_SUFFIX="mpv"

# execute action
#
ACTION='meteogram viewer refresh sleep iptv'
# with force option for meteogram
#ACTION='meteogram wget svg viewer sleep iptv'

# debug (output to stdout)
#
DBG=

# logger tag (empty for no logging)
#
LOG="yr.disp"

# /DEFAULTS #
#------------

usage="
$COPY

usage: $0 [-h][-d][-l tag][-s sec][-cc CC][-i title][-v title][-o loc][-r res][-a action][-b border][-wxh WxH]

h        ... this usage help
d        ... verbose/debug output to stdout (overrides log setting)
l tag    ... log output to logger with tag (default $LOG)
s sec    ... show meteogram for time sec (default $SHOWFOR)
cc CC    ... translate to language CC (default $LANG_CC), empty is EN (no translation)
i title  ... html title (default $TITLE), result is in html format if title is provided, otherwise in svg format
v title  ... iptv player title (default $IPTV_TITLE_SUFFIX)
o loc    ... location id in the format 2-12345 (default $LOC)
r res    ... result file (default $RESULT)
a action ... execute actions (default $ACTION)
             meteogram - call script meteogram.sh to retrieve svg/html
             wget - force cache refresh even within expiry period
             svg  - force regeneration of meteogram
             viewer - execute viewer if not running and bring it to front
             refresh - force viewer refresh
             sleep - sleep (display meteogram)
             iptv - bring iptv player to front
             refresh - force refresh browser window
b border ... border size (graphics will be smaller by border)
wxh WxH  ... browser/viewer width W x height H (default $WxH)

Required: $REQUIRES
"

# process cli parameters
#
while [ $# -gt 0 ]
do
    case $1 in

    -h|-help|-usage)
        echo -e "$usage"
        exit 1
        ;;

    -d|-dbg)
        DBG=1
        ;;

    -l|-log)
        shift
        LOG=$1
        ;;

    -s|-show)
        shift
        SHOWFOR=$1
        ;;

    -r|-result)
        shift
        RESULT=$1
        ;;

    -cc|-lang|-translate)
        shift
        LANG_CC=$1
        ;;

    -i|-title|-html)
        shift
        TITLE=$1
        ;;

    -a|-action|-force)
        shift
        ACTION=$1
        ;;

    -b|-border)
        shift
        BORDER=$1
        ;;

    -wxh|-geo|-geometry)
        shift
        WxH=$1
        ;;

    *)
        echo "$0 ignoring unknown parameter ($1)"
        ;;

    esac

    shift
done

# debug or logger output
#
msg="true"
# logger
[ -n "LOG" ] && msg="logger -t \"$LOG\""
# stdout
[ $DBG ] && msg="echo -e"

# log
#
$msg "= starting $0 = result $RESULT = WxH $WxH = html.title $TITLE = show $SHOWFOR = lang.cc $LANG_CC ="

# split W x H to W and H
#
W=${WxH%x*}
H=${WxH#*x}

# get meteogram (calc w x h reduced by border size)
#
[[ $ACTION == *meteogram* ]] && $(dirname $0)/meteogram.sh -r "$RESULT" -title "$TITLE" \
                                    -wxh "$((W-BORDER))x$((H-BORDER))" \
                                    -loc "$LOC" -cc "$LANG_CC" -force "$ACTION"

# title to identify svg viewer via grep
# firefox has changed separator '-' -> '—'
#
VIEWER_TITLE="$TITLE . $VIEWER_TITLE_SUFFIX"

# title to identify iPTV player
#
IPTV_TITLE=" - $IPTV_TITLE_SUFFIX"

# optinal viewer start
#
if [[ $ACTION == *viewer* ]]
then

    # start VIEWER if not running
    #
    if ! wmctrl -l | grep -q "$VIEWER_TITLE"
    then
        $msg "starting new $VIEWER $MODE: $RESULT"

        # exec VIEWER in background
        nice $VIEWER --$MODE  "$RESULT" &

        # wait max limit*sleep or until viewer window is present
        for cnt in {1..10}
        {
            sleep 5
            wmctrl -l | grep -q "$VIEWER_TITLE" && $msg "$VIEWER window found - title: $VIEWER_TITLE" && break
            $msg "$cnt ... waiting for $VIEWER window - title: $VIEWER_TITLE"
        }
    fi

    # resize if not kiosk mode (kiosk is fixed to fullscreen)
    #
    if [ "$MODE" != "kiosk" ]
    then

        # get firefox w x h
        #
        fox_wxh=$( wmctrl -lG | grep "$VIEWER_TITLE" | awk '{printf "%dx%d",$5,$6}' )
        #
        $msg "$VIEWER $MODE geometry: $fox_wxh, required geometry: $WxH"

        # activate and fullscreen if geometry doesn't match
        #
        [ "$WxH" != "$fox_wxh" ] && wmctrl -r "$VIEWER_TITLE" -e 0,0,0,$W,$H   \
                                    && wmctrl -a "$VIEWER_TITLE" && xte "key F11" \
                                    && $msg "resize to 0,0,0,$W,$H and set Fullscreen-F11 for: $VIEWER_TITLE"
    fi
fi

# optional refresh
#
[[ $ACTION == *refresh* ]] && wmctrl -a "$VIEWER_TITLE" && xte "key F5" \
                           && $msg "forced Refresh-F5: $VIEWER_TITLE"

# sleep for $TIME
#
[[ $ACTION == *sleep* ]] && $msg "sleeping for $SHOWFOR while meteogram $RESULT is displayed ..." && sleep "$SHOWFOR"

# activate mpv
#
[[ $ACTION == *iptv* ]] && wmctrl -a "$IPTV_TITLE" && $msg "iPTV player activated - title: $IPTV_TITLE"
