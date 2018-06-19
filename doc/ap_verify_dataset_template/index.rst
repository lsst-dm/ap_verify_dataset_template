.. _ap_verify_dataset_template-package:

##########################
ap_verify_dataset_template
##########################

The ``ap_verify_dataset_template`` package is used to create :ref:`datasets<ap-verify-datasets>` for `lsst.ap.verify`.
It is not itself a valid dataset.

Project info
============

Repository
   https://github.com/lsst-dm/ap_verify_dataset_template

.. Datasets do not have their own (or a collective) Jira components; by convention we include them in ap_verify

Jira component
   `ap_verify <https://jira.lsstcorp.org/issues/?jql=project %3D DM %20AND%20 component %3D ap_verify %20AND%20 text ~ "dataset template">`_

Dataset Contents
================

This package provides a number of demonstration files copied from `obs_test <https://github.com/lsst/obs_test/>`_.
See that package for detailed file and provenance information.

This package contains only raw files, with no calibration information or difference imaging templates.
It contains a small Gaia DR1 reference catalog for illustrating the catalog format.
The catalog is not guaranteed to overlap with the footprint of the raw data.

Intended Use
============

This package provides an example for how a dataset package can be put together.
It is not guaranteed to be ingestible using ``ap_verify``, nor are the individual files guaranteed to be usable with each other.
The package provides some instructions on how to create a new dataset; more information can be found in :ref:`ap-verify-datasets-creation`.
