#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Author: Elise LARSONNEUR (elise.larsonneur@cea.fr)                           #
################################################################################

set -eo pipefail

#fg_sar mark -l "--------------------------mergeResults" || echo 'ignore fg_sar mark'

OUTDIR=$1

LST="$(set -eo pipefail && ls -1 "${OUTDIR}"/runSinglePointMerlin/*/results_singlepoint_chr*_dominant.woheader.txt | \
  awk -v RS=' ' 1 | \
  sort -V | \
  xargs)"
cat "$LST" > "${OUTDIR}/mergeResults/results_singlepoint_merged_dominant.txt" || exit 1

LST="$(set -eo pipefail && ls -1 "${OUTDIR}"/runSinglePointMerlin/*/results_singlepoint_chr*_recessive.woheader.txt | \
  awk -v RS=' ' 1 | \
  sort -V | \
  xargs)"
cat "$LST" > "${OUTDIR}/mergeResults/results_singlepoint_merged_recessive.txt" || exit 1

LST="$(set -eo pipefail && ls -1 "${OUTDIR}"/runMultiPointMerlin/*/results_multipoint_chr*_dominant.woheader.txt | \
  awk -v RS=' ' 1 | \
  sort -V | \
  xargs)" 
cat "$LST" > "${OUTDIR}/mergeResults/results_multipoint_merged_dominant.txt" || exit 1

LST="$(set -eo pipefail && ls -1 "${OUTDIR}"/runMultiPointMerlin/*/results_multipoint_chr*_recessive.woheader.txt | \
  awk -v RS=' ' 1 | \
  sort -V | \
  xargs)"
cat "$LST" > "${OUTDIR}/mergeResults/results_multipoint_merged_recessive.txt" || exit 1

