#!/bin/bash
set -e

# get paths ###############################################

SRCPATH="$(cd "$(dirname "$0")" && pwd -P)"
BUILDPATH="${SRCPATH}/dist"

# clean up ################################################

rm -rf "${BUILDPATH}"

# done ####################################################
