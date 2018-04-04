`ap_verify_dataset_template`
============================

Template repo for developing datasets for use with ap_verify.

This repo is designed to be used as a template for developing new datasets for integration into `ap_verify`.

Datasets must link to the corresponding instrument's obs package; this template is currently set up for using [`obs_test`](https://github.com/lsst/obs_test/) as a placeholder.

Relevant Files and Directories
------------------------------
path                  | description
:---------------------|:-----------------------------
`raw`                 | To be populated with raw data. Data files do not need to follow a specific subdirectory structure. Currently contains a single small fits file (taken from `obs_test`) to test `git-lfs` functionality.
`calib`               | To be populated with master calibs. Calibration files do not need to follow a specific subdirectory structure. Currently empty.
`config`              | To be populated with dataset-specific configs. Currently contains an example file corresponding to the contents of `raw` and `refcats`.
`templates`           | To be populated with `TemplateCoadd` images produced by a compatible version of the LSST pipelines. Must be organized as a filesystem-based Butler repo. Currently empty.
`repo`                | Butler repo into which raw data can be ingested.  This should be copied to an appropriate location before ingestion.  Note that the `_mapper` file will require updating for other instruments.
`refcats`             | To be populated with tarball(s) of HTM shards from relevant reference catalogs. Currently contains a small (useless) example tarball.
`dataIds.list`        | List of dataIds in this repo. For use in running Tasks. Currently set to run all Ids.


Git LFS
-------

To clone and use this repository, you'll need Git Large File Storage (LFS).

Our [Developer Guide](http://developer.lsst.io/en/latest/tools/git_lfs.html) explains how to setup Git LFS for LSST development.

