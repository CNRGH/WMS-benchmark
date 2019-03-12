#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                          #
#          Jonathan MERCIER (jonathan.mercier@cea.fr)                          #
################################################################################

set -eo pipefail

SCRIPTS=~/WMS-benchmark/scripts
OUTDIR=~/plots
mkdir -p $OUTDIR

#get metrics table
#11 slaves
head -n 1 $OUTDIR/workflow.meanperlabel.values \
  |awk '{print $1,$2,$7,$8,$9,$10,$11,$12,$13,$14,$15}' \
  |sed -e 's/Elapsed_Time/Elapsed_time_min/' \
  -e 's/NO_INODES_PER_TASK/no_inodes_per_task/' \
  -e 's/All_IDLE_TIME_MIN/Idle_time_min/' \
  -e 's/All_IOWAIT_TIME_SEC/IO_wait_time_sec/' \
  -e 's/Process_NVCSWCH_S/no_involuntary_context_switches_per_second/' \
  -e 's/Process_CSWCH_S/no_context_switches_per_second/' \
  -e 's/Process_Median_Memory/Median_memory_Gb/' \
  -e 's/Process_Max_Memory/Max_memory_Gb/' \
  -e 's/Process_Median_CPU_Prct/Median_CPU_percent/' \
  -e 's/Process_Max_CPU_Prct/Max_CPU_percent/' \
  > $OUTDIR/workflow.meanperlabel.11slaves.nfs.values

grep '_11slaves_nfs' $OUTDIR/workflow.meanperlabel.values \
  |awk '{print $1,$2,$7,$8,$9,$10,$11,$12,$13,$14,$15}' \
  |sed -e 's/_11slaves_nfs//g' \
  |sed -e 's/pegasus/PMC/' \
  |sed -e 's/toil/cwltoil/' \
  >> $OUTDIR/workflow.meanperlabel.11slaves.nfs.values


#radar plot
module load r || which R
$SCRIPTS/radar_plot_benchWMS.R $OUTDIR/workflow.meanperlabel.11slaves.nfs.values

