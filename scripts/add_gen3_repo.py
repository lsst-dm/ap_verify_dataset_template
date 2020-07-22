#!/usr/bin/env python

"""Convert a Gen 2 dataset to a Gen 3 dataset.

By default, this creates a hybrid Gen 2/3 dataset with shared files. A flag
lets a dataset be permanently migrated to Gen 3 instead.
"""

import argparse
import os
import shutil
import tempfile

import lsst.log
import lsst.daf.butler as daf_butler
import lsst.obs.base.script.convert
import lsst.ap.verify as ap_verify


class _Parser(argparse.ArgumentParser):
    def __init__(self, **kwargs):
        # super() causes problems with program name
        argparse.ArgumentParser.__init__(
            self,
            description="Copy a dataset's Gen 2 files into the Gen 3 format, overwriting a previous copy "
                        "if necessary. This creates a hybrid Gen 2/3 dataset unless the --drop-gen2 flag "
                        "is provided. DO NOT delete the Gen 2 files unless this flag has been used, as the "
                        "Gen 3 part of a hybrid dataset depends on them.\n\n"
                        "Assumes that the dataset's config directory has three configs for "
                        "obs.base.gen2to3.ConvertRepoTask: convertRepo_calibs.py, convertRepo_copied.py and "
                        "convertRepo_templates.py. See ap_verify_dataset_template/config for examples.",
            **kwargs)
        self.add_argument("--dataset", required=True,
                          help="The name of the dataset as recognized by ap_verify.py.")
        self.add_argument("--drop-gen2", action="store_true",
                          help="Create a standalone Gen 3 repo instead of sharing files with Gen 2. "
                               "Intended for use only once ap_verify no longer supports Gen 2.")


def main():
    args = _Parser().parse_args()
    log = lsst.log.Log.getLogger("add_gen3_repo")

    # To convert consistently, don't use any previous output
    dataset = ap_verify.dataset.Dataset(args.dataset)
    gen3_repo = os.path.join(dataset.datasetRoot, "preloaded")
    if os.path.exists(gen3_repo):
        log.warn("Clearing out %s and making it from scratch...", gen3_repo)
        shutil.rmtree(gen3_repo)
    os.makedirs(gen3_repo)

    mode = "copy" if args.drop_gen2 else "relsymlink"

    log.info("Converting templates...")
    gen2_templates = dataset.templateLocation
    _migrate_gen2_to_gen3(dataset, gen2_templates, None, gen3_repo, mode,
                          config_file="convertRepo_templates.py")

    log.info("Converting calibs...")
    with tempfile.TemporaryDirectory() as tmp:
        workspace = ap_verify.workspace.WorkspaceGen2(tmp)
        ap_verify.ingestion.ingestDataset(dataset, workspace)

        gen2_repo = workspace.dataRepo
        gen2_calibs = workspace.calibRepo
        # Files stored in the Gen 2 part of the dataset, can be safely linked
        _migrate_gen2_to_gen3(dataset, gen2_repo, gen2_calibs, gen3_repo, mode,
                              config_file="convertRepo_calibs.py")
        # Our refcats and defects are temporary files, and must not be linked
        _migrate_gen2_to_gen3(dataset, gen2_repo, gen2_calibs, gen3_repo, mode="copy",
                              config_file="convertRepo_copied.py")

    log.info("Exporting Gen 3 registry to configure new repos...")
    _export_for_copy(dataset, gen3_repo)


def _migrate_gen2_to_gen3(dataset, gen2_repo, gen2_calib_repo, gen3_repo, mode, config_file):
    """Convert a Gen 2 repository into a Gen 3 repository.

    Parameters
    ----------
    dataset : `lsst.ap.verify.dataset.Dataset`
        The dataset being migrated.
    gen2_repo, gen2_calib_repo : `str`
       The locations of the original repositories.
    gen3_repo : `str`
       The location of the Gen 3 repository. Must exist, but need not be
       initialized as a repository.
    mode : {'relsymlink', 'copy'}
       Whether the Gen 3 repo should contain symbolic links to the Gen 2
       datasets, or an independent copy.
    config_file : `str`
       The config file (in the dataset config directory) with a configuration
       for `~lsst.obs.base.gen2to3.ConvertRepoTask`
    """
    config = os.path.join(dataset.configLocation, config_file)

    # Call the script instead of calling ConvertRepoTask directly, to
    # avoid manually having to do a lot of setup that may change in the future.
    # <instrument>/calib, refcats, and skymaps collections created by default
    lsst.obs.base.script.convert(repo=gen3_repo, gen2root=gen2_repo,
                                 skymap_name=None, skymap_config=None, reruns=None,
                                 calibs=gen2_calib_repo,
                                 config_file=config,
                                 transfer=mode)


def _export_for_copy(dataset, repo):
    """Export a Gen 3 repository so that a dataset can make copies later.

    Parameters
    ----------
    dataset : `lsst.ap.verify.dataset.Dataset`
        The dataset needing the ability to copy the repository.
    repo : `str`
        The location of the Gen 3 repository.
    """
    butler = daf_butler.Butler(repo)
    with butler.export(directory=dataset.configLocation, format="yaml") as contents:
        contents.saveDatasets(butler.registry.queryDatasets(datasetType=..., collections=..., expand=True))


if __name__ == "__main__":
    main()
