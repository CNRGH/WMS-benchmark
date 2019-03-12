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
#copy cromwell workflow and samplesheet, and bash scripts
cd ~/WMS-benchmark/ && git clone https://github.com/CNRGH/LodSeq.git lodseq
cp -pr ~/WMS-benchmark/lodseq/scripts ~/WMS-benchmark/workflows/cromwell/.


cd ~/WMS-benchmark/workflows/cromwell/

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

#load cromwell environment
## do not use 'module load java' if you want to load different java versions into a command of the WDL script:
module load java/1.8 || which java
## allow to load, into a command of the WDL script, a java version different of the java version used for running cromwell:
JAVA=java
#cromwell_version=36
#curl -LO https://github.com/broadinstitute/cromwell/releases/download/${cromwell_version}/cromwell-${cromwell_version}.jar
#curl -LO https://github.com/broadinstitute/cromwell/releases/download/${cromwell_version}/womtool-${cromwell_version}.jar
WOMTOOL=~/WMS-benchmark/workflows/cromwell/womtool-36.jar #replace wdltool
CROMWELL=~/WMS-benchmark/workflows/cromwell/cromwell-36.jar

#config file to run cromwell using SLURM
LOCAL_BACKEND=$PWD/backends/local_12cpus_cromwell29.conf

#path of cromwell logs 
OUTDIR=~/trioCEPH1463/cromwell 
mkdir -p $OUTDIR
rm -rf $OUTDIR/*

#display cromwell and womtool version
$JAVA -jar $CROMWELL --version
$JAVA -jar $WOMTOOL --version

#path of the cromwell workflow (.wdl) and linked sample sheet (.json)
WDL=$PWD/lodseq.wdl
JSON=$PWD/lodseq_inputs_trioCEPH1463.json

#validate the wdl workflow
# $JAVA -jar $WOMTOOL validate ${WDL}
#validate workflow and inputs
# $JAVA -jar $WOMTOOL validate --inputs ${JSON} ${WDL}

#get dag
# DOT=${WDL}.dot
# $JAVA -jar $WOMTOOL graph ${WDL} > ${DOT}
# dot -Tpdf ${DOT} > ${DOT}.pdf

#start pidstat and display every 1 second
exec 3>&-
exec 3<> "pidstat_${SLURM_JOB_ID}.csv"
pidstat -urdw -h 1 | tr -s ' ' | awk 'BEGIN{ OFS=";"; print "number;Time;PID;%usr;%system;%guest;%CPU;CPU;minflt/s;majflt/s;VSZ;RSS;%MEM;kB_rd/s;kB_wr/s;kB_ccwr/s;cswch/s;nvcswch/s;Command"; number=0
}{ if ( /^#/ ){number+=1} else if ( /^ [0-9]+/ ){print number,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18}}' >&3 &
PIDSTATID=$!

#start fg_sar (sar)
fg_sar start -i 1
fg_sar mark -l "cromwell"


#run cromwell using the LOCAL backend
benchme $JAVA \
  -XX:ParallelGCThreads=2 -XX:CICompilerCount=2 -Xmx4g -Xms256m \
  -Dconfig.file="$LOCAL_BACKEND" \
  -jar $CROMWELL run "$WDL" \
  -i "$JSON" \
  &> "$PWD/lodseq.wdl.local.trioCEPH1463.${SLURM_JOB_ID}.log" &

BENCHME_PID=$!
sleep 10  #wait few seconds for starting of cromwell child process
CROMWELL_PID=$(pgrep -P "$BENCHME_PID" || echo 'unknown') # get child process of benchme process
pstree -p "$BENCHME_PID" || echo 'unknown pstree'
wait "$BENCHME_PID"

echo 'cromwell end'

#stop fg_sar
fg_sar stop

find ./cromwell-executions -name '*.rtm' |xargs cat |sort >> global-${SLURM_JOB_ID}.rtm

#process sar output
fg_sar calc

echo "BENCHME_PID: ${BENCHME_PID}"
echo "CROMWELL_PID: ${CROMWELL_PID}"
echo "SLURM_JOB_ID: ${SLURM_JOB_ID}"
echo "HOST: $HOSTNAME"

source deactivate lodseq

#cp -p *${SLURM_JOB_ID}* ~/WMS-benchmark/cromwell/.

#stop pidstat
kill "$PIDSTATID"
exec 3>&-

