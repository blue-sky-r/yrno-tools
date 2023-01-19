#!/usr/bin/python

# DEFAULTS

# fullscreen display of svg for timeout seconds
#
timeout = 20

# /DEFAULTS

import os.path

__version__ = '2023.01.15'

__github__ = 'https://github.com/blue-sky-r/yrno-tools'

__usage__ = """
= Simple PyQt5 SVG viewer = version %(ver)s = %(repo)s =

usage: %(exe)s filename.svg [timeout]

filename.svg ... full path to svg file to display
timeout      ... optional time in sec to display (default %(timeout)d seconds)
""" % {
    'exe': os.path.basename(__file__),
    'ver': __version__,
    'timeout': timeout,
    'repo': __github__
}

import sys

from PyQt5.QtWidgets import QApplication
from PyQt5.QtSvg import QSvgWidget
from PyQt5.QtCore import QTimer

# display usage help if less than 1 arg given
if len(sys.argv) < 2:
    print(__usage__)
    sys.exit(-1)

# cli args
svgFile = sys.argv[1]
if len(sys.argv) > 2:
    timeout = int(sys.argv[2])

# screen widget
app = QApplication(sys.argv)
svgWidget = QSvgWidget(svgFile)
svgWidget.showFullScreen()

# schedule quit after timeout
timer = QTimer()
timer.timeout.connect(lambda: app.quit())
timer.start(1000 * timeout)

# main execute
sys.exit(app.exec_())