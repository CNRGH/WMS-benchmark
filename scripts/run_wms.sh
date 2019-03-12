#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Author: Elise LARSONNEUR (elise.larsonneur@cea.fr)                           #
################################################################################

#runs data trioCEPH1463 
#======================

#runs 11 slaves
#==============

cd ~/WMS-benchmark/workflows/

#default is bridge (SLURM wrapper)
BATCH_EXE=ccc_msub
which ccc_msub
RC_CCCMSUB=$?
which sbatch
RC_SBATCH=$?
if [[ $RC_CCCMSUB != 0 ]] && [[ $RC_SBATCH == 0 ]]; then
  BATCH_EXE=sbatch;
elif [[ $RC_CCCMSUB != 0 ]] && [[ $RC_SBATCH != 0 ]]; then
  BATCH_EXE=bash;
fi
echo $BATCH_EXE;

#NEXTFLOW
cd nextflow
for i in {1..10}; do $BATCH_EXE run_nextflow_lodseq_11slaves.sh; done
cd ..
#SLURM_JOB_IDS: 1219587..1219596

#CROMWELL
cd cromwell
for i in {1..10}; do $BATCH_EXE run_cromwell_lodseq_11slaves.sh; done
cd ..
#SLURM_JOB_IDS: 1219597..1219606

#SNAKEMAKE
cd snakemake
for i in {1..10}; do $BATCH_EXE run_snakemake_lodseq_11slaves.sh; done
cd ..
#SLURM_JOB_IDS: 1219607..1219616

#CWLTOIL
cd cwltoil
for i in {1..10}; do $BATCH_EXE run_cwltoil_lodseq_11slaves.sh; done
cd ..
#SLURM_JOB_IDS: 1219617..1219626

#PEGASUS
cd pegasus
for i in {1..10}; do $BATCH_EXE run_pegasus_lodseq_11slaves.sh; done
cd ..
#SLURM_JOB_IDS: 1219627..1219636

