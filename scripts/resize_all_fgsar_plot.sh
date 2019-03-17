#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                          #
################################################################################

set -eo pipefail

SCRIPTS=~/WMS-benchmark/scripts

cd ~/WMS-benchmark/workflows

pushd nextflow
  $SCRIPTS/resize_fgsar_plot.sh;
popd

pushd cromwell
  $SCRIPTS/resize_fgsar_plot.sh;
popd

pushd snakemake
  $SCRIPTS/resize_fgsar_plot.sh;
popd

pushd cwltoil
  $SCRIPTS/resize_fgsar_plot.sh;
popd

pushd pegasus
  $SCRIPTS/resize_fgsar_plot.sh;
popd

