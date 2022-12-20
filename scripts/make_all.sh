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

# Script for regenerating a complete repository in preloaded/.
# Running this script allows for AP pipeline inputs to incorporate Science
# Pipelines improvements. It makes no attempt to update the set of input
# exposures; they are hard-coded into the files.
# This script takes roughly <TBD> hours to run on rubin-devl.
#
# Example:
# $ nohup make_all.sh -t "u/me/DM-123456" &
# fills this dataset, using the u/me/DM-123456 collection in
# /repo/main as a staging area. See make_all.sh -h for more options.

# Abort script on any error
set -e
# Echo all commands
set -x

SCRIPT_DIR="$( dirname -- "${BASH_SOURCE[0]}" )"
DATASET_REPO="${AP_VERIFY_DATASET_TEMPLATE_DIR:?'dataset is not set up'}/preloaded/"

INSTRUMENT=LSSTCam
UMBRELLA_COLLECTION="${INSTRUMENT}/defaults"  # Hardcoded into ap_verify, do not change!

########################################
# Command-line options

print_error() {
    >&2 echo "$@"
}

usage() {
    print_error
    print_error "Usage: $0 [-b BUTLER_REPO] [-c CALIB_COLLECTION] -t TEMPLATE_SCRATCH_COLLECTION [-h]"
    print_error
    print_error "Specific options:"
    print_error "   -b          Butler repo URI, defaults to /repo/main"
    print_error "   -c          calibration collection (chain) from which to draw calibs, defaults to <instrument>/calib"
    print_error "   -t          unique collection name for template generation; will also appear in final repo"
    print_error "   -h          show this message"
    exit 1
}

parse_args() {
    while getopts "b:c:t:h" option $@; do
        case "$option" in
            b)  SCRATCH_REPO="$OPTARG";;
            c)  CALIB_COLLECTION="$OPTARG";;
            t)  TEMPLATE_COLLECTION="$OPTARG";;
            h)  usage;;
            *)  usage;;
        esac
    done
    if [[ -z "${SCRATCH_REPO}" ]]; then
        SCRATCH_REPO=/repo/main
    fi
    if [[ -z "${CALIB_COLLECTION}" ]]; then
        CALIB_COLLECTION="${INSTRUMENT}/calib"
    fi
    if [[ -z "${TEMPLATE_COLLECTION}" ]]; then
        print_error "$0: mandatory argument -- t"
        usage
        exit 1
    fi
}
parse_args $@


# Unlikely to be workflow- or version-dependent, so hardcode it.
REFCAT_COLLECTION=refcats


########################################
# Prepare templates

"${SCRIPT_DIR}/generate_templates.sh" -b ${SCRATCH_REPO} -c "${CALIB_COLLECTION}" \
    -o "${TEMPLATE_COLLECTION}"


########################################
# Repository creation and instrument registration

"${SCRIPT_DIR}/make_empty_repo.sh"


########################################
# Import calibs, templates, and refcats

python "${SCRIPT_DIR}/import_calibs.py" -b ${SCRATCH_REPO} -c "${CALIB_COLLECTION}"
# Don't need import_templates --where, because $TEMPLATE_COLLECTION has only the templates we need.
python "${SCRIPT_DIR}/import_templates.py" -b ${SCRATCH_REPO} -t "${TEMPLATE_COLLECTION}"
python "${SCRIPT_DIR}/ingest_refcats.py" -b ${SCRATCH_REPO} -i "${REFCAT_COLLECTION}"


########################################
# Download solar system ephemerides

python "${SCRIPT_DIR}/generate_ephemerides.py"


########################################
# Final clean-up

# The individual collections are set in the appropriate sub-scripts.
butler collection-chain "${DATASET_REPO}" "${UMBRELLA_COLLECTION}" templates/goodSeeing skymaps ${INSTRUMENT}/calib refcats sso

python "${SCRIPT_DIR}/make_preloaded_export.py"

echo "Preloaded repository complete."
echo "All preloaded data products are accessible through the ${UMBRELLA_COLLECTION} collection."
