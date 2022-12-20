#!/usr/bin/env python
# This file is part of ap_verify_ci_dc2.
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

"""Script for copying calibs appropriate for these exposures.

This script currently requires that the calibration collection be part of a
chained collection, so that it can query the latter to identify the subset of
calibs to export. This restriction should go away after DM-37409.

Example:
$ python import_calibs.py -c "u/me/DM-123456-calib-chain"
imports image calibrations from (the calibration collections in)
u/me/DM-123456-calib in /repo/main to calibs in this dataset's preloaded repo.
"""

import argparse
import logging
import os
import sys
import tempfile

import lsst.log
import lsst.skymap
from lsst.daf.butler import Butler, CollectionType


logging.basicConfig(level=logging.INFO, stream=sys.stdout)
lsst.log.configure_pylog_MDC("DEBUG", MDC_class=None)


########################################
# Command-line options

def _make_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("-b", dest="src_dir", default="/repo/dc2",
                        help="Repo to import from, defaults to '/repo/dc2'.")
    parser.add_argument("-c", dest="src_collection", required=True,
                        help="Calib collection to import from. Must be a chained collection before DM-37409.")
    return parser


args = _make_parser().parse_args()


########################################
# Export/Import

DATA_IDS = [dict(detector=164, visit=982985, physical_filter="r_sim_1.4", instrument="LSSTCam-imSim"),
            dict(detector=168, visit=943296, physical_filter="r_sim_1.4", instrument="LSSTCam-imSim")]
CALIB_NAMES = ("bias", "dark", "flat")
CALIB_COLLECTION = "LSSTCam-imSim/calib"
DATASET_REPO = os.path.join(os.environ["AP_VERIFY_CI_DC2_DIR"], "preloaded")


def _export(butler, export_file):
    """Export the files to be copied.

    Parameters
    ----------
    butler : `lsst.daf.butler.Butler`
        A Butler pointing to the repository and collection(s) to be
        exported from.
    export_file : `str`
        A path pointing to a file to contain the export results.

    Returns
    -------
    calib_collections : iterable [`str`]
        The names of the calibration collections containing validities.
    """
    with butler.export(filename=export_file, transfer=None) as contents:
        for name in CALIB_NAMES:
            for data_id in DATA_IDS:
                calibs = butler.registry.queryDatasets(name, dataId=data_id, collections=butler.collections)
                contents.saveDatasets(calibs)

        calib_collections = set()
        for collection in butler.collections:
            calib_collections.update(_save_validities(butler.registry, contents, collection))
        return calib_collections


def _save_validities(registry, exporter, collection):
    """Transfer the validity information found in a collection or any of its
    sub-collections.

    This function is guaranteed not to add any datasets to the exporter.

    Parameters
    ----------
    registry : `lsst.daf.butler.Registry`
        The registry managing the collections.
    exporter : `lsst.daf.butler.transfers.RepoExportContext`
        The export manager to which to copy validities.
    collection : `str`
        The collection from which to copy validities.

    Returns
    -------
    calib_collections : iterable [`str`]
        All the individual calibration collections that were exported.
    """
    match registry.getCollectionType(collection):
        case CollectionType.CALIBRATION:
            exporter.saveCollection(collection)
            return {collection}
        case CollectionType.CHAINED:
            calib_collections = set()
            for child in registry.getCollectionChain(collection):
                calib_collections.update(_save_validities(registry, exporter, child))
            return calib_collections
        case _:
            return []


def _import(butler, export_file, base_dir):
    """Import the exported files.

    Parameters
    ----------
    butler : `lsst.daf.butler.Butler`
        A Butler pointing to the dataset repository.
    export_file : `str`
        A path pointing to a file containing the export results.
    base_dir : `str`
        The base directory for the file locations in ``export_file``.
    """
    butler.import_(directory=base_dir, filename=export_file, transfer="copy")


with tempfile.NamedTemporaryFile(suffix=".yaml") as export_file:
    src = Butler(args.src_dir, collections=args.src_collection, writeable=False)
    calib_collections = _export(src, export_file.name)
    dest = Butler(DATASET_REPO, writeable=True)
    _import(dest, export_file.name, args.src_dir)
    dest.registry.registerCollection(CALIB_COLLECTION, CollectionType.CHAINED)
    chain = list(dest.registry.getCollectionChain(CALIB_COLLECTION))
    chain.extend(calib_collections)
    dest.registry.setCollectionChain(CALIB_COLLECTION, chain)

logging.info(f"Calibs stored in {DATASET_REPO}:{CALIB_COLLECTION}.")
