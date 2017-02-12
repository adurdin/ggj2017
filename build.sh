#!/bin/bash
set -e

# get paths ###############################################

SRCPATH="$(cd "$(dirname "$0")" && pwd -P)"
BUILDPATH="${SRCPATH}/dist"
LOVEFILE="${BUILDPATH}/fracktheplanet.love"
ZIPFILE="${BUILDPATH}/Frack The Planet.zip"

# create .love file #######################################

FILELIST=(README.md main.lua assets)
rm -f "${LOVEFILE}"
cd "${SRCPATH}"
zip -q -r "${LOVEFILE}" "${FILELIST[@]}"
cd - >/dev/null

# win32 ###################################################

WIN32PATH="${BUILDPATH}/win32"
mkdir -p "${WIN32PATH}"
cd "${WIN32PATH}"
unzip -q -o -j "${BUILDPATH}/love2d/love-0.10.2-win32.zip" '*/*.dll' '*/love.exe' '*/license.txt'
cp -f "${SRCPATH}/README.md" "${WIN32PATH}/README.txt"
cat "${WIN32PATH}/love.exe" "${LOVEFILE}" > "${WIN32PATH}/Frack The Planet.exe"
rm -f "${WIN32PATH}/love.exe"
cd - >/dev/null

# win64 ###################################################

WIN64PATH="${BUILDPATH}/win64"
mkdir -p "${WIN64PATH}"
cd "${WIN64PATH}"
unzip -q -o -j "${BUILDPATH}/love2d/love-0.10.2-win64.zip" '*/*.dll' '*/love.exe' '*/license.txt'
cp -f "${SRCPATH}/README.md" "${WIN64PATH}/README.txt"
cat "${WIN64PATH}/love.exe" "${LOVEFILE}" > "${WIN64PATH}/Frack The Planet.exe"
rm -f "${WIN64PATH}/love.exe"
cd - >/dev/null

# macos ###################################################

MACOSPATH="${BUILDPATH}/macos"
mkdir -p "${MACOSPATH}"
cd "${MACOSPATH}"
unzip -q -o "${BUILDPATH}/love2d/love-0.10.2-macosx-x64.zip" 'love.app/*'
cp -f "${SRCPATH}/README.md" "${MACOSPATH}/README.txt"
cp -f "${MACOSPATH}/love.app/Contents/Resources/license.txt" "${MACOSPATH}/"
cp -f "${BUILDPATH}/macos-Info.plist" "${MACOSPATH}/love.app/Contents/Info.plist"
cp -f "${LOVEFILE}" "${MACOSPATH}/love.app/Contents/Resources/"
rm -rf "${MACOSPATH}/Frack The Planet.app"
mv "${MACOSPATH}/love.app" "${MACOSPATH}/Frack The Planet.app"
cd - >/dev/null

# linux ###################################################

LINUXPATH="${BUILDPATH}/linux"
mkdir -p "${LINUXPATH}"
cd "${LINUXPATH}"
cp -f "${SRCPATH}/README.md" "${LINUXPATH}/README.txt"
# Don't have a linux source .zip, so just use the licence from the Windows version
unzip -q -o -j "${BUILDPATH}/love2d/love-0.10.2-win64.zip" '*/license.txt'
cp -f "${BUILDPATH}/linux-conf.lua" "${LINUXPATH}/conf.lua"
cp -f "${LOVEFILE}" "${LINUXPATH}/"
cd - >/dev/null

# zip it all up ###########################################

cd "${BUILDPATH}"
FILELIST=(win32 win64 macos linux)
rm -f "${ZIPFILE}"
zip -q -r -y "${ZIPFILE}" "${FILELIST[@]}"
cd - >/dev/null

# done ####################################################

echo "${ZIPFILE}"
