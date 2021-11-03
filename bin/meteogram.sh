#!/usr/bin/env bash

# Extract meteogram graphic from yr.no forecast page
# ==================================================
# local caching, scaling, localization - see usage help

# version
#
VER=2021.11.02

# packages required
#
REQUIRES="pkg: libxml2-utils, script: [ meteogram-CC.sed for the translation to CC language ]"

# author
#
AUTH='Robert'

# github repository
#
REPO="https://github.com/blue-sky-r/yrno-tools"

# copyright
#
COPY="= weather meteogram = extract svg graphic meteogram from yr.no = (c) $VER by $AUTH = $REPO ="

# DEFAULTS #
#-----------

# location
#
# How to find your location id:
# https://www.yr.no - search [right top] - type Your location - select from suggestion - copy location id from URL in format 2-123456
#
LOC="2-6167865"     # https://www.yr.no/en/forecast/graph/2-6167865/Canada/Ontario/Toronto
# http yr.no
HTTP="https://www.yr.no"
# EN lang
EN_CONT="en/content"
# hour-by-hour graph
SVG="meteogram.svg"

# http timeout in seconds
#
TIMEOUT=7

# result html/svg
#
RESULT="/tmp/meteogram.html"

# cache file
#
CACHE="/tmp/cache-$SVG"

# force update (one of 'wget', 'wget svg','svg', unknown tokens are ignored)
#
FORCE=

# html title (empty for only SVG output format)
#
TITLE=

# css for html page
#
#STYLE="body { background-color: black; cursor: none; } body div { display: table, margin: auto; }"
STYLE="body { background-color: white; cursor: none; }"

# refresh cache (minimum 60 mins - please read and respect Data-access-and-terms-of-service)
# https://hjelp.yr.no/hc/en-us/articles/360001946134-Data-access-and-terms-of-service
#
EXPIRY='4 hour + 15 mins'

# scale to width x height (empty for no scaling)
#
WxH=

# debug (output to stdout)
#
DBG=

# logger tag (empty no logging)
#
LOG="yr.no"

# user-agent (include reference to the repository and itself)
#
UA="Mozilla/5.0 Gecko/20100101 Firefox/93.0 * $REPO/meteogram.sh"

# translate CC (empty for default EN lang)
#
LANG_CC=

# /DEFAULTS #
#------------

usage="
$COPY

usage: $0 [-h][-d][-l tag][-t sec][-a agent][-c cache][-e exp][-cc CC][-i title][-s css][-u url][-o loc][-r res][-f force][-wxh WxH]

h        ... this usage help
d        ... verbose/debug output to stdout (overrides log setting)
l tag    ... log output to logger with tag (default $LOG)
t sec    ... http timeout in sec (default $TIMEOUT)
a agent  ... user-agent string for html page retrieval (default $UA)
c cache  ... cache file (default $CACHE)
e exp    ... cache  expiry time (default $EXPIRY)
cc CC    ... translate to language CC (default ${LANG_CC:-EN}), empty is EN
i title  ... html title (default ${TITLE:-empty}), result is html format if title is provided, svg format otherwise
s css    ... css style for html output (default $STYLE)
u url    ... url to get meteogram svg graphic (default $URL)
o loc    ... location id instead of full url in the format 2-12345 (default $LOC)
r res    ... result file (default $RESULT)
f force  ... force update action (default ${FORCE:-empty})
             wget - force cache refresh even within expiry period
             svg  - force regeneration of meteogram
wxh WxH  ... scale graphics to width W and height H (default ${WxH:-empty}), empty for no scaling = original size

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

    -d|-dbg|-v)
        DBG=1
        ;;

    -l|-log)
        shift
        LOG=$1
        ;;

    -u|-url)
        shift
        URL=$1
        ;;

    -o|-loc|-location)
        shift
        LOC=$1
        ;;

    -t|-timeout)
        shift
        TIMEOUT=$1
        ;;

    -r|-result)
        shift
        RESULT=$1
        ;;

    -c|-cache)
        shift
        CACHE=$1
        ;;

    -cc|-lang|-translate)
        shift
        LANG_CC=$1
        ;;

    -e|-expiry)
        shift
        EXPIRY=$1
        ;;

    -i|-title|-html)
        shift
        TITLE=$1
        ;;

    -s|-css|-style)
        shift
        STYLE=$1
        ;;

    -f|-force)
        shift
        FORCE=$1
        ;;

    -wxh|-scale|-geo|-geometry)
        shift
        WxH=$1
        ;;

    -a|-agent)
        shift
        UA=$1
        ;;

    *)
        echo "$0 ignoring unknown parameter ($1)"
        ;;

    esac

    shift
done

# construct url
#
URL="$HTTP/$EN_CONT/$LOC/$SVG"

# msg - debug or logger output
#
msg="true"
# logger
[ -n "LOG" ] && msg="logger -t \"$LOG\""
# stdout
[ $DBG ] && msg="echo -e $LOG:"

# log
#
$msg "= starting $0 = cache $CACHE = expiry $EXPIRY = result $RESULT = WxH $WxH = html.title $TITLE = lang.cc $LANG_CC = force $FORCE ="

# retrieve forecast page if required ($cache doesn't exist or older then $expiry)
#
if [[ $FORCE == *wget* || ! -s "$CACHE" || $(date -d "now - ${EXPIRY//+/-}" +%s) > $(date -r "$CACHE" +%s) ]]
then

    # log
    #
    $msg "refresh cache: $( ls -l $CACHE ) = url: $URL = timeout $TIMEOUT"

    # get or exit with wget exitcode
    #
    wget -q -U "$UA" --timeout=$TIMEOUT -O "$CACHE" "$URL" && cache_updated=1 \
    || { exitcode=$?; $msg "wget error code: $exitcode"; exit $exitcode; }

    # log
    #
    $msg "updated cache: $( ls -l $CACHE )"
else
    # log
    #
    $msg "no update needed, cache: $( ls -l $CACHE )"
fi


# regenerate result only if $force update requested or got updated $cache file or have $cache file but not $result
#
if [[ $FORCE == *svg* || -s "$CACHE" && $cache_updated || -s "$CACHE" && ! -s "$RESULT"  ]]
then

    # start with empty result
    #
    echo -n "" > "$RESULT"

    # optional html header (title, utf8, css) and log CSS
    #

    [ -n "$TITLE" ] && echo -e "<html>\n <head>\n <title>$TITLE</title>\n" \
                                "<meta charset=\"utf-8\">\n " \
                                "<style>\n ${STYLE} \n</style>\n " \
                                "</head>\n <body>\n <div>\n" >> "$RESULT" \
                    && $msg "html format using css $STYLE"

    # insert svg graphic
    #
    cat "$CACHE" >> $RESULT

    # optional html footer
    #
    [ -n "$TITLE" ] && echo -e "\n </div>\n </body>\n </html>\n" >> "$RESULT"

    # optional scaling
    #
    if [ -n "$WxH" ]
    then
        # source dimensions
        # w=$( awk '/width=/  {gsub(/[^0-9]/,"",$0); print $0; exit}' "$CACHE" )
        # h=$( awk '/height=/ {gsub(/[^0-9]/,"",$0); print $0; exit}' "$CACHE" )
        w=782; h=391

        # target dimensions
        width=${WxH%x*}
        height=${WxH#*x}

        # scale factor (3 decimal digits)
        wscale=$( echo "$width $w"  | awk '{printf "%.3f",$1 / $2}' )
        hscale=$( echo "$height $h" | awk '{printf "%.3f",$1 / $2}' )

        # log
        $msg "optional scaling factor ($wscale, $hscale) source dim: $w x $h -> $width x $height"

        # scale svg by transform
        #sed -i -z -e '
        #    # svg scaling
        #    s/width="'$w'"\n\s\+height="'$h'"/width="'$width'" height="'$height'" transform="scale('$wscale','$hscale')"/1
        #    ' "$RESULT"

        # scale svg by viewBox
        sed -i -z -e '
            # svg scaling
            s/width="'$w'"\n\s\+height="'$h'"/width="'$width'" height="'$height'" viewBox="0 0 '$w' '$h'" preserveAspectRatio="none"/1
            ' "$RESULT"

    fi

    # optional language translation (weekdays, month names, legend)
    #
    if [ -n "$LANG_CC" ]
    then
        # sed language file
        #
        cc_sed="${0%.sh}-${LANG_CC}.sed"

        if [ -s "$cc_sed" ]
        then
            # log
            $msg "optional lang.cc: $LANG_CC - using sed file $cc_sed: $(ls -l $cc_sed)"

            # translate
            sed -i -f "$cc_sed" "$RESULT"
        else
            # log error
            $msg "optional lang.cc: $LANG_CC - sed file $cc_sed not found !"
        fi
    fi

    # log
    #
    $msg "result: $( ls -l $RESULT )"
else
    # log
    #
    $msg "no update needed, result: $( ls -l $RESULT )"
fi
