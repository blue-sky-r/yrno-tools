#!/bin/bash

# Desktop Wallpaper wih live Meteogram from yr.no forecast page
# =============================================================
# css styling with background image, result is png image - see usage help

# version
#
VER=2020.06.09

# packages / scripts required
#
REQUIRES="pkg: cutycapt; script: meteogram.sh [meteogram-CC.sed]"

# author
#
AUTH='Robert'

# github repository
#
REPO="https://github.com/blue-sky-r/yrno-tools"

# copyright
#
COPY="= generate desktop wallpaper png image with actual weather meteogram from yr.no = (c) $VER by $AUTH = $REPO ="

# temporary file
#
HTML=/tmp/meteo.html

# DEFAULTS #
#-----------

# location
#
LOC="Canada/Ontario/Toronto"
LOC="Slovakia/Banská_Bystrica/Banská_Bystrica"

# debug (output to stdout)
#
DBG=

# logger tag (empty no logging)
#
LOG="meteo-wallpaper"

# translate CC (empty for default EN lang)
#
LANG_CC=SK

# html title (whatever, just to activate html output)
#
TITLE="html"

# desktop dimensions
#
X=1280
Y=1024

# css for html page
#
CSS_BG="background-color: black"

# css margin to position svg meteogram on html page
# unscaled svg dim: 828 x 272
# cass margin: top right bottom left
#CSS_MARGIN="0 0 675 440"    # scaling: 1.000, 1.250 for 1280x1024
CSS_MARGIN="0 0 743 440"    # scaling: 1.000, 1.000 for 1280x1024

# optional border around meteogram for visual enhancement
#
CSS_BORDER="3px solid cyan"

# /DEFAULTS #
#------------

usage="
$COPY

usage: $0 [-h][-d][-l tag][-cc CC][-bg image][-m margin][-b border] -x width -y height -o loc -r res

h        ... this usage help
d        ... verbose/debug output to stdout (overrides log setting)
l tag    ... log output to logger with tag (default $LOG)
cc CC    ... translate to language CC (default is EN)
bg image ... optional background image (default $CSS_BG)
m margin ... css margin to position svg meteogram on html page (default $CSS_MARGIN)
b border ... optional border around meteogram (default $CSS_BORDER)
x width  ... x-size (width  in pixels)
y height ... y-size (height in pixels)
o loc    ... location in the format Country/Province/City (default $LOC)
r res    ... result desktop wallpaper (png) file

Required: $REQUIRES

Examples

Default position of meteogram in the right-top corner on Trinity crystal_fire wallpaper:

 > $0 -x 1280 -y 1024 -bg /opt/trinity/share/wallpapers/crystal_fire.png -r /tmp/test.png

Position of meteogram in the right-bottom corner on Trinity crystal_fire wallpaper:

 > $0 -x 1280 -y 1024 -bg /opt/trinity/share/wallpapers/crystal_fire.png -m '600 0 0 200' -r /tmp/test.png

Default position of meteogram on black background for for Toronto, CA

 > $0 -x 1280 -y 1024 -bg black -loc 'Canada/Ontario/Toronto' -r /tmp/test.png

Command for Trinity / Desktop / Advanced settings:

 > $0 -x %x -y %y -loc 'Canada/Ontario/Toronto' -bg /opt/trinity/share/wallpapers/crystal_fire.png -r %f
"

# construct style
#
function style()
{
    local w=$1
    local h=$2
    local bg=$3

    local border=$4
    local margin=$5

    # body
    #
    echo -n "body { "
    # is bg a file ?
    [ -s "$bg" ] && echo -n "background-image: url($bg); background-size: 100% 100%; " \
                 || echo -n "background-color: ${bg#background-color:}; "
    # visual white border (for testing)
    #echo -n "border: 1px dotted white; "
    # width and height
    echo -n "width: $w; height: $h; } "

    # div
    #
    echo -n "body div { "
    [ -n "$border" ] && echo -n "border: ${border#border:}; "
    echo -n "display: table; "
    [ -n "$margin" ] && echo -n "margin: ${margin#margin:}; "
    echo -n " } "
}

# calculate W x H for meteogram
#
function calc_wxh()
{
    local dimx=$1
    local dimy=$2
    local border=${3//[^0-9]/}
    # top right bottom left
    local margin=${4#*margin:}

    local w=$( echo "$dimx $border $margin" | awk '{print $1 - 4*$2 - $4 - $6}' )
    local h=$( echo "$dimy $border $margin" | awk '{print $1 - 3*$2 - $3 - $5}' )

    echo "${w}x${h}"
}


# process cli parameters
#
while [ $# -gt 0 ]
do
    case $1 in

    -h|-help|-usage)
        echo -e "$usage"
        exit 1
        ;;

    -d|-dbg|-v)
        DBG=1
        ;;

    -l|-log)
        shift
        LOG=$1
        ;;

    -cc|-lang)
        shift
        LANG_CC=$1
        ;;

    -bg|-background)
        shift
        CSS_BG=$1
        ;;

    -m|-margin)
        shift
        CSS_MARGIN=$1
        ;;

    -b|-border)
        shift
        CSS_BORDER=$1
        ;;

    -x|-width)
        shift
        X=$1
        ;;

    -y|-height)
        shift
        Y=$1
        ;;

    -o|-loc|-location)
        shift
        LOC=$1
        ;;

    -r|-result)
        shift
        RESULT=$1
        ;;

    *)
        echo "$0 ignoring unknown parameter ($1)"
        ;;

    esac

    shift
done

# msg - debug or logger output
#
msg="true"
# logger
[ -n "LOG" ] && msg="logger -t \"$LOG\""
# stdout
[ $DBG ] && msg="echo -e $LOG:"

# log
#
$msg "= starting $0 = cc $LANG_CC = css.bg $CSS_BG = css.margin $CSS_MARGIN = css.border $CSS_BORDER = WxH $X x $Y = result $RESULT ="

# prepare cc if LANG-CC not empty
#
[ -n "$LANG_CC" ] && cc="-cc $LANG_CC"

# calculate WxH
#
wxh=$( calc_wxh $X $Y "$CSS_BORDER" "$CSS_MARGIN" )
# log
$msg "calculated svg dimensions WxH: $wxh"

# build css
#
css=$( style $X $Y "$CSS_BG" "$CSS_BORDER" "$CSS_MARGIN" )
# log
$msg "using html.css: $css"

# get meteogram
#
$(dirname "$0")/meteogram.sh -wxh $wxh $cc -i "$TITLE" -css "$css" -loc "$LOC" -r "$HTML"

# log
#
$msg "result.html: $(ls -l $HTML)"

# render html to png
#
[ -s "$HTML" -a -n "$RESULT" ] && cutycapt --url="file://$HTML" --out-format=png --out="$RESULT"

# log
#
$msg "result.png: $(ls -l $RESULT)"
