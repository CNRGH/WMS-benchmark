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
#MSUB -E "--nodelist=lirac07 --exclusive"
#SBATCH -p normal
#SBATCH --nodelist=lirac07 --exclusive

set -eo pipefail

# input trioCEPH1463 data
# ~/trioCEPH1463/inputs 
#copy nextflow workflow and samplesheet, and bash scripts
cd ~/WMS-benchmark/ && git clone https://github.com/CNRGH/LodSeq.git lodseq
mv ~/WMS-benchmark/lodseq/scripts ~/WMS-benchmark/workflows/nextflow/.

cd ~/WMS-benchmark/workflows/nextflow/

#load nextflow dependency
module load java/oracle/1.8 || which java

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

#version 0.32.0
NEXTFLOW=nextflow

OUTPUTDIR=~/trioCEPH1463/nextflow
# directory of final results (symbolic links to workdir)
OUTDIR=$OUTPUTDIR/output
# directory of temp, intermediate and final results
WORKDIR=$OUTPUTDIR/work

rm -rf $OUTPUTDIR/*
mkdir -p $OUTDIR
mkdir -p $WORKDIR

WORKFLOW=lodseq.nf
INPUTS=nextflow.trioCEPH1463.config

#display nextflow version
$NEXTFLOW -v

rm -f ${WORKFLOW}.dag.svg

#start pidstat and display every 1 second
exec 3>&-
exec 3<> "pidstat_${SLURM_JOB_ID}.csv"
pidstat -urdw -h 1 | tr -s ' ' | awk 'BEGIN{ OFS=";"; print "number;Time;PID;%usr;%system;%guest;%CPU;CPU;minflt/s;majflt/s;VSZ;RSS;%MEM;kB_rd/s;kB_wr/s;kB_ccwr/s;cswch/s;nvcswch/s;Command"; number=0
}{ if ( /^#/ ){number+=1} else if ( /^ [0-9]+/ ){print number,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18}}' >&3 &
PIDSTATID=$!

#start fg_sar (sar)
fg_sar start -i 1
fg_sar mark -l "nextflow"

# run
# 3 possiblities to specify JVM options: 
#   (for the 3rd option, specify also the same java command as those that is output by the command 'ps <PID_java_nextflow>') 
# 1) export NXF_OPTS='-XX:ParallelGCThreads=2 -XX:CICompilerCount=2 -Xmx4g -Xms256m'
# 2) export JAVA_TOOLS_OPTIONS='-XX:ParallelGCThreads=2 -XX:CICompilerCount=2 -Xmx4g -Xms256m'
# 3) $JAVA -XX:ParallelGCThreads=2 -XX:CICompilerCount=2 -Xmx4g -Xms256m -jar ${NEXTFLOW_JAR} run [...]
# /usr/bin/time
export NXF_OPTS='-XX:ParallelGCThreads=2 -XX:CICompilerCount=2 -Xmx4g -Xms256m'
benchme \
 ${NEXTFLOW} \
 run ${WORKFLOW} \
 -queue-size 11 \
 -c ${INPUTS} \
 -work-dir ${WORKDIR} \
 -with-dag ${WORKFLOW}.dag.svg &
# -with-dag ${WORKFLOW}.dag.dot &
#dot -Tsvg ${WORKFLOW}.dag.dot > ${WORKFLOW}.dag.svg

BENCHME_PID=$!
sleep 10  #wait few seconds for starting of nextflow child process
NEXTFLOW_PID=$(pgrep -P "$BENCHME_PID" || echo 'unknown') # get child process of benchme process
pstree -p "$BENCHME_PID" || echo 'unknown pstree'
wait "$BENCHME_PID"

echo 'nextflow end'

#stop fg_sar
fg_sar stop

find $OUTPUTDIR -name '*.rtm' |xargs cat |sort >> "global-${SLURM_JOB_ID}.rtm"

#process sar output
fg_sar calc

echo "BENCHME_PID: ${BENCHME_PID}"
echo "NEXTFLOW_PID: ${NEXTFLOW_PID}"
echo "SLURM_JOB_ID: ${SLURM_JOB_ID}"
echo "HOST: $HOSTNAME"

mv .nextflow.log "${INPUTS}.nextflow.${SLURM_JOB_ID}.log"

source deactivate lodseq

#cp -p *${SLURM_JOB_ID}* ~/WMS-benchmark/nextflow/.

#stop pidstat
kill "$PIDSTATID"
exec 3>&-

