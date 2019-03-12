#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                          #
#          Jonathan MERCIER (jonathan.mercier@cea.fr)                          #
################################################################################

cd ~/WMS-benchmark/workflows

#step 1 - run all the WMS ten times
#----------------------------------
./run_wms.sh


#step 2 - compute performance metrics
#------------------------------------

## get inode number
./get_inodes_benchWMS.sh

##get all WMS performance metrics
./get_and_parse_perf_metrics_benchWMS.sh

##draw radar plot
./get_radar_plot_benchWMS.sh

