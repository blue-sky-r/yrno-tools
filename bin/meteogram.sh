#!/usr/bin/env bash

# Extract meteogram graphic from yr.no forecast page
# ==================================================
# local caching, scaling, localization - see usage help

# version
#
VER=2020.06.03

# packages required
#
REQUIRES="libxml2-utils"

# author
#
AUTH='Robert'

# github repository
#
REPO="https://github.com/blue-sky-r/mpv-wifi-rc"

# copyright
#
COPY="= weather meteogram = extract svg graphic meteogram from yr.no = (c) $VER by $AUTH = $REPO ="

# DEFAULTS #
#-----------

# location
#
LOC="Canada/Ontario/Toronto"
#LOC="Slovakia/Bansk%C3%A1_Bystrica/Bansk%C3%A1_Bystrica"
# http yr.no
HTTP="https://www.yr.no/place"
# hour-by-hour page
PAGE="hour_by_hour.html"
# construct url
URL="$HTTP/$LOC/$PAGE"

# http timeout in seconds
#
TIMEOUT=7

# result html/svg
#
RESULT="/tmp/meteogram.html"

# cache file
#
CACHE="/tmp/cache-$PAGE"

# force update (one of 'wget', 'wget svg','svg')
#
FORCE=

# html title (empty for only SVG output format)
#
TITLE=

# refresh cache (minimum 60 mins - please read and respect Data-access-and-terms-of-service)
# https://hjelp.yr.no/hc/en-us/articles/360001946134-Data-access-and-terms-of-service
#
EXPIRY='1 hour'

# scale to width x height (empty for no scaling)
#
WxH=

# debug (output to stdout)
#
DBG=

# logger tag (empty no logging)
#
LOG="yr.no"

# user-agent
#
UA='Mozilla/5.0 (Tablet; rv:26.0) Gecko/26.0 Firefox/26.0'

# translate CC (empty for default EN lang)
#
LANG_CC=

# /DEFAULTS #
#------------

usage="
$COPY

usage: $0 [-h][-d][-l tag][-t sec][-a agent][-c cache][-e exp][-cc CC][-i title][-u url][-o loc][-r res][-f force][-wxh WxH]

h       ... this usage help
d       ... verbose/debug output to stdout (overrides log setting)
l tag   ... log output to logger with tag (default $LOG)
t sec   ... http timeout in sec (default $TIMEOUT)
a agent ... user-agent string for html page retrieval (default $UA)
c cache ... cache file (default $CACHE)
e exp   ... cache  expiry time (default $EXPIRY)
cc CC   ... translate to language CC (default $LANG_CC), empty is EN
i title ... html title (default $TITLE), result is html format if title is provided, svg format otherwise
u url   ... url to get meteogram svg graphic (default $URL)
o loc   ... location instead of full url in the format Country/Province/City (default $LOC)
r res   ... result file (default $RESULT)
f force ... force update action (default $FORCE)
            wget - force cache refresh even within expiry period
            svg  - force regeneration of meteogram
wxh WxH ... scale graphics to width W and height H (default $WxH), empty for no scaling = original size

Required pkgs: $REQUIRES
"

# debug or logger output
#
#function msg()
#{
#    [   $DBG ] && echo -e "$LOG $@"
#    [ ! $DBG ] && [ -n "$LOG" ] && logger -t "$LOG" "$@"
#    return
#}

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
        URL="$HTTP/$LOC/$PAGE"
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

# debug or logger output
#
msg="true"
# logger
[ -n "LOG" ] && msg="logger -t \"$LOG\""
# stdout
[ $DBG ] && msg="echo -e"

# log
#
$msg "= starting $0 = cache $CACHE = expiry $EXPIRY = result $RESULT = WxH $WxH = html.title $TITLE = lang.cc $LANG_CC = force $FORCE ="

# retrieve forecast page if required ($cache doesn't exist or older then $expiry)
#
if [[ $FORCE == *wget* || ! -s "$CACHE" || $(date -d "now - $EXPIRY" +%s) > $(date -r "$CACHE" +%s) ]]
then

    # log
    #
    $msg "refresh cache: $( ls -l $CACHE ) = url: $URL = timeout $TIMEOUT"

    # get
    #
    wget -q -U "$UA" --timeout=$TIMEOUT -O "$CACHE" "$URL" && cache_updated=1

    # log
    #
    $msg "updated cache: $( ls -l $CACHE )"
else
    # log
    #
    $msg "no update needed, cache: $( ls -l $CACHE )"
fi


# regenerate result only if we got updated $cache file
#
if [[ $FORCE == *svg* || -s "$CACHE" && $cache_updated ]]
then

    # start with empty result
    #
    echo -n "" > "$RESULT"

    # optional html header
    #
    [ -n "$TITLE" ] && echo -e "<html>\n<head>\n<title>$TITLE</title>\n</head>\n" \
                                "<body style=\"background-color: black; cursor: none;\">\n" \
                                "<div  style=\"display: table; margin: auto;\">\n" >> "$RESULT"

    # filter svg parts (suppress warnings and errors - and yes, there are many)
    #
    xmllint --html --nowarning --xpath '//body/svg' "$CACHE" >> "$RESULT" 2>/dev/null

    xmllint --html --nowarning --xpath '//div[@class="meteogramme"]' "$CACHE" >> "$RESULT" 2>/dev/null

    # <meta property="og:description" content="05 June 2020 at 12:00-13:00: Rain, Temperature 15, 0.5 mm, Gentle breeze, 5 m/s from south" />

    # optional html footer
    #
    [ -n "$TITLE" ] && echo -e "\n</div>\n</body></html>\n" >> "$RESULT"

    # optional scaling
    #
    if [ -n "$WxH" ]
    then
        # source dimensions
        w=828; h=272

        # target dimensions
        width=${WxH%x*}
        height=${WxH#*x}

        # scale factor (3 decimal digits)
        wscale=$( echo "$width $w"  | awk '{printf "%.3f",$1 / $2}' )
        hscale=$( echo "$height $h" | awk '{printf "%.3f",$1 / $2}' )

        # log
        $msg "optional scaling factor ($wscale, $hscale) source dim: $w x $h -> $width x $height"

        # scale svg and yr logo
        sed -i -e '
            # svg
            s/g transform="translate(0.5,0.5)"/g transform="scale('$wscale','$hscale')"/
            s/ width="'$w'" height="'$h'"/ width="'$width'" height="'$height'"/
            # yr logo
            s/g transform="translate(655,4) scale(0.5)"/g transform="translate(655,4) scale(0.2,0.2)"/
            ' -i "$RESULT"
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
