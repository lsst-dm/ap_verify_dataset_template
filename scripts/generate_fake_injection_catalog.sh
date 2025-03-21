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

# Script for automatically generating fake source injection catalogs.
# This script requires the source_injection repository to be set up, and for
# templates to already exist in this data set.
#
# Example:
# "${SCRIPT_DIR}/generate_fake_injection_catalog.sh" -b ${DATASET_REPO} -o ${INJECTION_CATALOG_COLLECTION}

# Abort script on any error
set -e


########################################
# Per data set configuration

TEMPLATE_TYPE=goodSeeing  # Must match the type used in this data set
BANDS="g"                 # Band(s) for which to generate fakes
RA_RANGE="152.0 156.0"    # Catalog box in degrees
DEC_RANGE="-6.02 -5.6"
MAG_RANGE="18 26"
DENSITY=5000              # Source density in deg^-2


########################################
# Capture repository and script directory

SCRIPT_DIR="$( dirname -- "${BASH_SOURCE[0]}" )"
REPO_DIR="${SCRIPT_DIR}/../preloaded/"

print_error() {
    >&2 echo "$@"
}

usage() {
    print_error
    print_error "Usage: $0 [-b BUTLER_REPO] -c ROOT_COLLECTION [-h]"
    print_error
    print_error "Specific options:"
    print_error "   -b          Butler repo yaml file URI, defaults to preloaded repo"
    print_error "   -o          name of the output collection for injection catalog"
    print_error "   -h          show this message"
    exit 1
}

parse_args() {
    while getopts "b:o:h" option $@; do
        case "$option" in
            b)  BUTLER_REPO="$OPTARG";;
            o)  OUTPUT_COLLECTION="$OPTARG";;
            h)  usage;;
            *)  usage;;
        esac
    done
    if [[ -z "${BUTLER_REPO}" ]]; then
        BUTLER_REPO=$REPO_DIR
    fi
    if [[ -z "${OUTPUT_COLLECTION}" ]]; then
        print_error "$0: mandatory argument -- o"
        usage
        exit 1
    fi
}
parse_args $@

TEMPLATE_NAME=${TEMPLATE_TYPE}Coadd
TEMPLATE_COLLECT=templates/${TEMPLATE_TYPE}

# The -a (RA) and -d (Dec) options are the limits of the sky polygon
#  where to draw random fake positions, -s is source density per sq degree,
#  -m is the magnitude interval, -i is the filter set to use, and --seed fixes the random see to use.
generate_injection_catalog \
    # Expansions of *_RANGE and BANDS are unquoted so that they expand into multiple words
    -a $RA_RANGE \
    -d $DEC_RANGE \
    -p source_type Star \
    -s ${DENSITY} \
    -b "${BUTLER_REPO}" \
    -w "$TEMPLATE_NAME" \
    -c "$TEMPLATE_COLLECT" \
    -o "${OUTPUT_COLLECTION}" \
    -m $MAG_RANGE \
    -i $BANDS \
    --seed 314
