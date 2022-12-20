#!/bin/bash
# This file is part of ap_verify_dataset_template.
#
# Developed for the LSST Data Management System.
# This product includes software developed by the LSST Project
# (https://www.lsst.org).
# See the COPYRIGHT file at the top-level directory of this distribution
# for details of code ownership.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Script for automatically generating differencing templates for this dataset.
# It takes roughly <TBD> hours to run on rubin-devl.
# Running this script allows for templates to incorporate pipeline
# improvements. It makes no attempt to update the set of input exposures; they
# are hard-coded into the file.
#
# Example:
# $ nohup generate_templates.sh -c "u/me/DM-123456-calib" -o "u/me/DM-123456-template" &
# produces templates in /repo/main in the u/me/DM-123456-template collection.
# See generate_templates.sh -h for more options.


# Abort script on any error
set -e


########################################
# Raw template exposures to process

PIPELINE="${AP_VERIFY_DATASET_TEMPLATE_DIR}/pipelines/ApTemplate.yaml"
INSTRUMENT=LSSTCam
DEFAULT_COLLECTION=${INSTRUMENT}/defaults
SKYMAP=latiss_v1

# The following variables can be any expression that's valid in a Butler query's IN clause.

# Mapping indexed by tract ID
declare -A PATCHES
PATCHES[1234]="27..42"
PATCHES[1235]="1, 5, 22"

# Exposure filter is a safeguard against queries that can't be constrained by
# tract/patch, or against inclusion of data from other surveys. It also lets
# science users curate the coadd inputs, if desired.
EXPOSURES="288934, 288935, 288975, 288976, 289015, 289016, 289055, 289056, 289160, 289161, 289201,
           289783, 289818, 289820, 289828, 289870, 289871, 289912, 289913"


########################################
# Command-line options

print_error() {
    >&2 echo "$@"
}

usage() {
    print_error
    print_error "Usage: $0 [-b BUTLER_REPO] -c ROOT_COLLECTION [-h]"
    print_error
    print_error "Specific options:"
    print_error "   -b          Butler repo URI, defaults to /repo/main"
    print_error "   -c          input calib collection for template processing"
    print_error "   -o          template collection name; will also appear in final repo"
    print_error "   -h          show this message"
    exit 1
}

parse_args() {
    while getopts "b:c:o:h" option $@; do
        case "$option" in
            b)  BUTLER_REPO="$OPTARG";;
            c)  CALIBS="$OPTARG";;
            o)  TEMPLATES="$OPTARG";;
            h)  usage;;
            *)  usage;;
        esac
    done
    if [[ -z "${BUTLER_REPO}" ]]; then
        BUTLER_REPO="/repo/main"
    fi
    if [[ -z "${CALIBS}" ]]; then
        print_error "$0: mandatory argument -- c"
        usage
        exit 1
    fi
    if [[ -z "${TEMPLATES}" ]]; then
        print_error "$0: mandatory argument -- o"
        usage
        exit 1
    fi
}
parse_args "$@"


########################################
# Generate templates

FILTER="instrument='$INSTRUMENT' AND skymap='$SKYMAP'
        AND exposure IN (${EXPOSURES}) AND ("
OR=""
for tract in ${!PATCHES[*]}; do
    FILTER="${FILTER} ${OR} (tract=${tract} AND patch IN (${PATCHES[${tract}]}))"
    OR="OR"
done
FILTER="${FILTER})"


# Run single-frame processing and coaddition separately, so that isolated
# errors in SFP do not prevent coaddition from running. Instead, coadds will
# use all successful runs, ignoring any failures.
pipetask run -j 12 -d "${FILTER}" -b ${BUTLER_REPO} -i ${CALIBS},${DEFAULT_COLLECTION} -o ${TEMPLATES} \
    -p ${PIPELINE}#singleFrameAp
pipetask run -j 12 -d "${FILTER}" -b ${BUTLER_REPO} -o ${TEMPLATES} \
    -p ${PIPELINE}#makeTemplate


########################################
# Final summary

echo "Templates stored in ${BUTLER_REPO}:${TEMPLATES}"
