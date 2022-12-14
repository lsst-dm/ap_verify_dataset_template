`ap_verify_dataset_template`
============================

Template repo for developing datasets for use with ap_verify.

This repo is designed to be used as a template for developing new datasets for integration into [`ap_verify`](https://github.com/lsst/ap_verify/).

Datasets must link to the corresponding instrument's obs package; this template is currently set up for using [`obs_lsst`](https://github.com/lsst/obs_lsst/) as a placeholder.

NOTE: many files have hardcoded references to the package name; do a search-and-replace for "ap_verify_dataset_template" before attempting other customizations for your dataset.

Relevant Files and Directories
------------------------------
path                  | description
:---------------------|:-----------------------------
`doc`                 | Contains Sphinx package documentation for the dataset. This documentation may be linked to from other packages, such as `ap_verify`.
`raw`                 | To be populated with raw data. Data files do not need to follow a specific subdirectory structure. Currently contains a single small fits file (taken from `obs_test`) to test `git-lfs` functionality.
`config`              | To be populated with dataset-specific configs. Currently empty.
`pipelines`           | To be populated with dataset-specific pipelines. Currently contains three example files specialized for ImSim data.
`preloaded`           | To be populated with a Gen 3 Butler repository (see below). This repository must never be written to; instead, it should be copied to a separate location before use (this is handled automatically by `ap_verify`, see below).
`dataIds.list`        | List of dataIds in this repo. For use in running Tasks. Currently set to run all Ids.


Gen 3 Collections
-----------------

The Gen 3 repository in `preloaded/` must contain the following collections; these may be chained collections containing arbitrarily-named runs.

collection              | description
:-----------------------|:-----------------------------
`<instrument>/calib`    | Master calibration files for the data in the `raw` directory.
`refcats`               | Level 7 HTM shards from relevant reference catalogs.
`skymaps`               | Skymaps for the template coadds.
`templates/<type>`      | Coadd images produced by a compatible version of the LSST pipelines. For example, `deepCoadd` images go in a `templates/deep` collection.
`<instrument>/defaults` | A chained collection linking all of the above.

Git LFS
-------

To clone and use this repository, you'll need Git Large File Storage (LFS).

Our [Developer Guide](http://developer.lsst.io/en/latest/tools/git_lfs.html) explains how to setup Git LFS for LSST development.

Usage
-----

Datasets are designed to be run using [`ap_verify`](https://pipelines.lsst.io/modules/lsst.ap.verify/), which is distributed as part of the `lsst_distrib` package of the [LSST Science Pipelines](https://pipelines.lsst.io/).

This dataset is not included in `lsst_distrib` and is not available through `newinstall.sh`.
However, it can be installed explicitly with the [LSST Software Build Tool](https://developer.lsst.io/stack/lsstsw.html) or by cloning directly:

    git clone https://github.com/lsst/<dataset>/
    setup -r <dataset>

See the Science Pipelines documentation for more detailed instructions on [installing datasets](https://pipelines.lsst.io/modules/lsst.ap.verify/datasets-install.html) and [running `ap_verify`](https://pipelines.lsst.io/modules/lsst.ap.verify/running.html).
