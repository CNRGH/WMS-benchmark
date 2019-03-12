#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                          #
#          Jonathan MERCIER (jonathan.mercier@cea.fr)                          #
################################################################################

# get exclusive allocation of a full node with 12 cores
# please change node and partition names 
#MSUB -q normal
#MSUB -n 12 # number of tasks in parallel
#MSUB -c 1  # number of cores per task
#MSUB -E "--nodelist=lirac07 --exclusive"
#SBATCH -p normal
#SBATCH -n 12 # number of tasks in parallel
#SBATCH -c 1  # number of cores per task
#SBATCH --nodelist=lirac07 --exclusive

set -eo pipefail

mkdir -p ~/trioCEPH1463/pegasus/

#input trioCEPH1463 data
# ~/trioCEPH1463/inputs 
#copy pegasus workflow and samplesheet, and bash scripts
#cp -p ~/WMS-benchmark/pegasus/lodseq_DAG_trioCEPH1463.txt ~/WMS-benchmark/workflows/pegasus/.
mkdir -p ~/benchmarkWMS
cd ~/WMS-benchmark/ && git clone https://github.com/CNRGH/LodSeq.git lodseq
cp -pr ~/WMS-benchmark/lodseq/scripts ~/benchmarkWMS
cp ~/WMS-benchmark/workflows/pegasus/mergeResultsByDir.sh ~/benchmarkWMS/scripts

cd ~/WMS-benchmark/workflows/pegasus/

# load lodseq dependencies using conda
#conda env create -n lodseq --file ~/WMS-benchmark/lodseq/environment.yaml
#   see https://github.com/CNRGH/LodSeq for help about creating this conda environment
source activate lodseq

which merlin
which plink
which vcftools
plink --version
vcftools --version
merlin |grep MERLIN || echo 'merlin version'

#load pegasus
module load pegasus/4.8.2 || which pegasus-mpi-cluster

#display pegasus version
pegasus-mpi-cluster --version

#clean outdir
OUTDIR=~/trioCEPH1463/pegasus
rm -rf $OUTDIR/*

#create PMC dag
#CHROMOSOMES='1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y'
DAG=lodseq_DAG_trioCEPH1463.txt
#DOT=lodseq_DAG_trioCEPH1463.dot
#./get_pegasus_lodseq_DAG.sh \
#  -i ~/trioCEPH1463/inputs/trio_NA12878-NA12891-NA12892_hs37d5_dbsnp.vcf.gz \
#  -p ~/trioCEPH1463/inputs/pedigree_trioCEPH1463.tfam \
#  -g ~/data/inputs/genetic_map_HapMapII_GRCh37/ \
#  -D ~/data/inputs/parametric_dominant.model \
#  -R ~/data/inputs/parametric_recessive.model \
#  -c "${CHROMOSOMES}" \
#  -o ${OUTDIR} \
#  -s trioCEPH1463 \
#  -l 0.3 \
#  -t 1 \
#  -d ${DOT} \
#  > ${DAG}
# dot -Tpdf ${DOT} > ${DOT}.pdf

cp -p "$DAG" "lodseq_DAG_trioCEPH1463.${SLURM_JOB_ID}.txt"
DAG=lodseq_DAG_trioCEPH1463.${SLURM_JOB_ID}.txt

#start pidstat and display every 1 second
exec 3>&-
exec 3<> "pidstat_${SLURM_JOB_ID}.csv"
pidstat -urdw -h 1 | tr -s ' ' | awk 'BEGIN{ OFS=";"; print "number;Time;PID;%usr;%system;%guest;%CPU;CPU;minflt/s;majflt/s;VSZ;RSS;%MEM;kB_rd/s;kB_wr/s;kB_ccwr/s;cswch/s;nvcswch/s;Command"; number=0
}{ if ( /^#/ ){number+=1} else if ( /^ [0-9]+/ ){print number,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18}}' >&3 &
PIDSTATID=$!

#start fg_sar (sar)
fg_sar start -i 1
fg_sar mark -l "pegasus"

echo "mpirun -oversubscribe -n 12 pegasus-mpi-cluster ${DAG}"
benchme mpirun -oversubscribe -n 12 pegasus-mpi-cluster "$DAG" &

BENCHME_PID=$!
sleep 10  #wait few seconds for starting of pegasus child process
PEGASUS_PID=$(pgrep -P "$BENCHME_PID" || echo 'unknown') # get child process of benchme process
pstree -p "$BENCHME_PID" || echo 'unknown pstree'
wait "$BENCHME_PID"

echo 'pegasus end'

#stop fg_sar
fg_sar stop

#process sar output
fg_sar calc

echo "BENCHME_PID: ${BENCHME_PID}"
echo "PEGASUS_PID: ${PEGASUS_PID}"
echo "SLURM_JOB_ID: ${SLURM_JOB_ID}"
echo "HOST: $HOSTNAME"

source deactivate lodseq

#cp -p *${SLURM_JOB_ID}* ~/WMS-benchmark/workflows/pegasus/

#stop pidstat
kill "$PIDSTATID"
exec 3>&-

