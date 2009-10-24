#!/bin/sh

# This is an in-progress shell script...  Use at your own risk!


# HoboAptana-20070823-044146 -> HoboIntro-20070823-044146
# Tools/HTML-20060930-174924 -> HTML-20060930-174922

#OLD=Git/git-svn-20070920-181338
#NEW=Git-svn-20070920-181338
#OLD_BASE='Git/git-svn'
#NEW_BASE=Git-svn
#OLD_ESC_BASE='Git\/git-svn'
#NEW_ESC_BASE=Git-svn


OLD="Dpkg/Create the Repository-20061207-202353"
NEW="Dpkg/Apt-20061207-202352"

# TODO: automatically generate these...
# Just the file name, with the -12345678-123456 removed
OLD_BASE="Dpkg/Create the Repository"
NEW_BASE="Dpkg/Apt"
# Just the base name but with all / converted to \/
OLD_ESC_BASE="Dpkg\/Create the Repository"
NEW_ESC_BASE="Dpkg\/Apt"

# This just prints the filenames
# find . -wholename "./$NEW_BASE-*" \! -newer "$NEW" -and \! -samefile "$NEW" -print

find . -wholename "./$NEW_BASE-*" \! -newer "$NEW" -and \! -samefile "$NEW" -print | \
   sed "s/.\/$NEW_ESC_BASE-\(.*\)/git mv '$NEW_ESC_BASE-\1' '$OLD_ESC_BASE-\1'/"
