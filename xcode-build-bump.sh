#!/bin/sh
###############################################################################
#                                                                             #
# Bump the app build version                                                  #
#                                                                             #
# @version: 1.0.0                                                             #
# @author: Steiner Patrick <patrick.steiner@mopius.com>                       #
# @date: 29.05.2015 11:46                                                     #
# License: BSD                                                                #
#                                                                             #
###############################################################################

PROJECT_DIR="NearspeakKit"
INFOPLIST_FILE="Info.plist"

buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
buildNumber=$(($buildNumber + 1))

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"