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

#input trioCEPH1463 data
# ~/trioCEPH1463/inputs
#copy cwltoil workflow and samplesheet, and bash scripts
cd ~/WMS-benchmark/ && git clone https://github.com/CNRGH/LodSeq.git lodseq
cp -pr ~/WMS-benchmark/lodseq/scripts ~/WMS-benchmark/workflows/cwltoil/.


cd ~/WMS-benchmark/workflows/cwltoil


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

#load toil dependency (python2.7 not python3 !!!)
module load python/2.7.8 || which python
#cwltoil and cwltool executables
CWLTOOL=cwltool
CWLTOIL=cwltoil
# conda install -c javascript nodejs #requires nodejs
which node

WORKFLOW=lodseq.cwl
INPUTS=config_trioCEPH1463.yml
OUTDIR=~/trioCEPH1463/cwltoil

${CWLTOIL} --version
${CWLTOOL} --version

#validate a CWL file
#${CWLTOOL} --validate ${WORKFLOW}

#get dag
#${CWLTOOL} --print-dot ${WORKFLOW} > ${WORKFLOW}.dot
#dot -Tpdf ${WORKFLOW}.dot > ${WORKFLOW}.dot.pdf 

rm -rf $OUTDIR/*
mkdir -p $OUTDIR/WORKDIR
mkdir -p $OUTDIR/TMPDIR_PREFIX
mkdir -p $OUTDIR/TMP_OUTDIR_PREFIX

#start pidstat and display every 1 second
exec 3>&-
exec 3<> "pidstat_${SLURM_JOB_ID}.csv"
pidstat -urdw -h 1 | tr -s ' ' | awk 'BEGIN{ OFS=";"; print "number;Time;PID;%usr;%system;%guest;%CPU;CPU;minflt/s;majflt/s;VSZ;RSS;%MEM;kB_rd/s;kB_wr/s;kB_ccwr/s;cswch/s;nvcswch/s;Command"; number=0
}{ if ( /^#/ ){number+=1} else if ( /^ [0-9]+/ ){print number,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18}}' >&3 &
PIDSTATID=$!

#start fg_sar (sar)
fg_sar start -i 1
fg_sar mark -l "cwltoil"

#run
benchme ${CWLTOIL} \
  --preserve-environment USER SLURM_JOB_ID HOME OUTDIR \
  --workDir $OUTDIR/WORKDIR \
  --tmpdir-prefix $OUTDIR/TMPDIR_PREFIX \
  --tmp-outdir-prefix $OUTDIR/TMP_OUTDIR_PREFIX \
  --cleanWorkDir never \
  --clean never \
  --outdir $OUTDIR \
  --jobStore $OUTDIR/jobstore \
  --maxCores 11 \
  ${WORKFLOW} \
  ${INPUTS} \
  &> ~/WMS-benchmark/cwltoil/lodseq.cwltoil.trioCEPH1463."${SLURM_JOB_ID}".log &

BENCHME_PID=$!
sleep 10  #wait few seconds for starting of cwltoil child process (required to have an output with the command pgrep or pstree)
CWLTOIL_PID=$(pgrep -P "$BENCHME_PID" || echo 'unknown') # get child process of benchme process
pstree -p "$BENCHME_PID" || echo 'unknown pstree'
wait "$BENCHME_PID"

echo 'cwltoil end'

#stop fg_sar
fg_sar stop

find $OUTDIR -name '*.rtm' |xargs cat |sort >> "global-${SLURM_JOB_ID}.rtm"

#process sar output
fg_sar calc

echo "BENCHME_PID: ${BENCHME_PID}"
echo "CWLTOIL_PID: ${CWLTOIL_PID}"
echo "SLURM_JOB_ID: ${SLURM_JOB_ID}"
echo "HOST: $HOSTNAME"

source deactivate lodseq

#cp -p *${SLURM_JOB_ID}* ~/WMS-benchmark/cwltoil/.

#stop pidstat
kill "$PIDSTATID"
exec 3>&-

