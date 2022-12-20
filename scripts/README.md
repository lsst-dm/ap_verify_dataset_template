Dataset management script templates
===================================

This directory has example scripts for (re)creating an ap_verify dataset.
Adopting such scripts for your own datasets is highly recommended, to make it easy to update the pipeline inputs (in particular, calibs and templates) for pipeline improvements.
These scripts are *not* intended to be used as-is; they may require some fine-tuning to adapt to the specifics of your data set.

As with the rest of the ap_verify_dataset_template repository, there may be hard-coded references to the package in the scripts themselves.
Be sure to update any such references before proceeding.

Contents
--------
path                  | description
:---------------------|:-----------------------------
make_empty_repo.sh    | Replace `preloaded/` with a repo containing only dimension definitions and standard "curated" calibs.
import_templates.py   | Transfer templates from another repo (such as `repo/main`) and register them in `preloaded/`.
