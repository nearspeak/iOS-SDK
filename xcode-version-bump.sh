#!/bin/sh
###############################################################################
#                                                                             #
# Bump the app version                                                        #
#                                                                             #
# @version: 1.0.0                                                             #
# @author: Steiner Patrick <patrick.steiner@mopius.com>                       #
# @date: 29.05.2015 11:46                                                     #
# License: BSD                                                                #
#                                                                             #
###############################################################################

PROJECT_DIR="NearspeakKit"
INFOPLIST_FILE="Info.plist"

VERSIONNUM=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PROJECT_DIR}/${INFOPLIST_FILE}")
NEWSUBVERSION=`echo $VERSIONNUM | awk -F "." '{print $3}'`
NEWSUBVERSION=$(($NEWSUBVERSION + 1))
NEWVERSIONSTRING=`echo $VERSIONNUM | awk -F "." '{print $1 "." $2 ".'$NEWSUBVERSION'" }'`

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEWVERSIONSTRING" "${PROJECT_DIR}/${INFOPLIST_FILE}"