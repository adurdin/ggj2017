#!/bin/bash
set -e

# get paths ###############################################

SRCPATH="$(cd "$(dirname "$0")" && pwd -P)"
BUILDPATH="${SRCPATH}/dist"
LOVEFILE="${BUILDPATH}/fracktheplanet.love"
ZIPFILE="${BUILDPATH}/Frack The Planet.zip"

# clean up ################################################

rm -f "${LOVEFILE}" "${ZIPFILE}"
rm -rf "${BUILDPATH}/win32" "${BUILDPATH}/win64" "${BUILDPATH}/macos" "${BUILDPATH}/linux"

# done ####################################################
