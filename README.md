`ap_verify_dataset_template`
============================

Template repo for developing datasets for use with ap_verify.

This repo is designed to be used as a template for developing new datasets for integration into `ap_verify`.

Datasets must link to the corresponding instrument's obs package; this template is currently set up for using [`obs_test`](https://github.com/lsst/obs_test/) as a placeholder.

Relevant Files and Directories
------------------------------
path                  | description
:---------------------|:-----------------------------
`doc`                 | Contains Sphinx package documentation for the dataset. This documentation may be linked to from other packages, such as `ap_verify`.
`raw`                 | To be populated with raw data. Data files do not need to follow a specific subdirectory structure. Currently contains a single small fits file (taken from `obs_test`) to test `git-lfs` functionality.
`calib`               | To be populated with master calibs. Calibration files do not need to follow a specific subdirectory structure. Currently empty.
`config`              | To be populated with dataset-specific configs. Currently contains an example file corresponding to the contents of `raw` and `refcats`.
`templates`           | To be populated with `TemplateCoadd` images produced by a compatible version of the LSST pipelines. Must be organized as a filesystem-based Butler repo. Currently empty.
`repo`                | A template for a Butler raw data repository. This directory must never be written to; instead, it should be copied to a separate location, and data ingested into the copy (this is handled automatically by `ap_verify`, see below). Note that the `_mapper` file will require updating for other instruments.
`refcats`             | To be populated with tarball(s) of HTM shards from relevant reference catalogs. Currently contains a small (useless) example tarball.
`dataIds.list`        | List of dataIds in this repo. For use in running Tasks. Currently set to run all Ids.


Git LFS
-------

To clone and use this repository, you'll need Git Large File Storage (LFS).

Our [Developer Guide](http://developer.lsst.io/en/latest/tools/git_lfs.html) explains how to setup Git LFS for LSST development.

Usage
-----

<!-- TODO: replace with just links to Sphinx labels `ap-verify-datasets-install` and `ap-verify-running` once those docs are published -->

Datasets must be cloned (with Git LFS) and set up with [EUPS](https://developer.lsst.io/stack/eups-tutorial.html) before they can be processed with `ap_verify`.
Then, run `ap_verify` to ingest and process the dataset through the AP pipeline:

    ap_verify.py --dataset <DATASET> --id "<DATA ID FOR SINGLE IMAGE>" --output /my_output_dir/ --silent

or, instead, run `ingest_dataset` to create standard Butler repositories for other purposes:

    ingest_dataset.py --dataset <DATASET> --output /my_output_dir/

See the [`ap_verify`](https://github.com/lsst-dm/ap_verify/) documentation for more details.
