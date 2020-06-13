## yr.no hour-by-hour meteogram tools

The Norway Weather forecast website [https://www.yr.no](https://www.yr.no) provides user friendly graphical
representation of hour-by-hour weather conditions called meteogram.

Here are some linux tools to work with meteograms:

* meteogram.sh ... script to retrieve, cache, extract, scale and translate meteogram
* display-meteogram.sh ... meteogram utility for mpv (IPTV) player
* wallpaper.sh ... Trinity Desktop Environment (TDE) tools for inserting live meteogram into desktop wallpaper

Each script can be called by -h (-help) parameter to show usage help.

### meteogram.sh

BASH script to retrieve hour-by-hour web page from [https://www.yr.no](https://www.yr.no) for specific location (wget).
The retrieved html page is cached locally for configurable time. The meteogram svg graphic is extracted and optionally
scalled to required dimensions (xmllint). Optional simplistic text translation based on string find and replace is also
available (sed script). The result is either svg or html format.

    $ ./meteogram.sh -h

    = weather meteogram = extract svg graphic meteogram from yr.no = (c) 2020.06.11 by Robert = https://github.com/blue-sky-r/yrno-tools =

    usage: ./meteogram.sh [-h][-d][-l tag][-t sec][-a agent][-c cache][-e exp][-cc CC][-i title][-s css][-u url][-o loc][-r res][-f force][-wxh WxH]

    h        ... this usage help
    d        ... verbose/debug output to stdout (overrides log setting)
    l tag    ... log output to logger with tag (default yr.no)
    t sec    ... http timeout in sec (default 7)
    a agent  ... user-agent string for html page retrieval (default Mozilla/5.0 Gecko/26.0 Firefox/26.0 * https://github.com/blue-sky-r/yrno-tools/meteogram.sh)
    c cache  ... cache file (default /tmp/cache-hour_by_hour.html)
    e exp    ... cache  expiry time (default 1 hour + 15 mins)
    cc CC    ... translate to language CC (default EN), empty is EN
    i title  ... html title (default empty), result is html format if title is provided, svg format otherwise
    s css    ... css style for html output (default body { background-color: black; cursor: none; } body div { display: table, margin: auto; })
    u url    ... url to get meteogram svg graphic (default https://www.yr.no/place/Canada/Ontario/Toronto/hour_by_hour.html)
    o loc    ... location instead of full url in the format Country/Province/City (default Canada/Ontario/Toronto)
    r res    ... result file (default /tmp/meteogram.html)
    f force  ... force update action (default empty)
                 wget - force cache refresh even within expiry period
                 svg  - force regeneration of meteogram
    wxh WxH  ... scale graphics to width W and height H (default empty), empty for no scaling = original size

    Required: pkg: libxml2-utils, script: [ meteogram-CC.sed for the translation to CC language ]

### dispaly-meteohram.sh

BASH script to retrieve (calling meteogram.sh) and display full-screen meteogram for configurable time.
Firefox browser in kiosk-mode is used as svg+html full-screen viewer. To display the meteogram the firefox
is bring to the front while IPTV mpv player in full-screen mode is sent to back. The browser is forced to refresh
the page to always display the updated meteogram, After configurable time the IPTV player is brought again to front.

### wallpaper.sh

TDE (KDE 3) Desktop Wallpaper config supportd user program to draw wallpaper. This feature is utilised by this BASH script
to dynamically render meteogram on the Desktop Wallpaper. This offers the user quick access to detailed weather forecast
for the next 48 hours. Position and size of the meteogram are configurable.


### keywords

weather, forecast, meteogram, TDE, Trinity Desktop, KDE3, wallpaper