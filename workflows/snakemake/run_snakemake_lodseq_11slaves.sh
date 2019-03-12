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

OUTDIR=~/trioCEPH1463/snakemake
rm -rf $OUTDIR/*

#input trioCEPH1463 data
# ~/trioCEPH1463/inputs
#copy snakemake workflow and samplesheet, and bash scripts
cd ~/WMS-benchmark/ && git clone https://github.com/CNRGH/LodSeq.git lodseq
mv ~/WMS-benchmark/lodseq/* ~/WMS-benchmark/workflows/snakemake/.


cd ~/WMS-benchmark/workflows/snakemake/

SNAKEIN=config_trioCEPH1463.yml
echo "config_file:${SNAKEIN}"

#load lodseq dependencies using conda
#conda env create -n lodseq --file ~/WMS-benchmark/lodseq/environment.yaml
#   see https://github.com/CNRGH/LodSeq for help about creating this conda environment
source activate lodseq

which merlin
which plink
which vcftools
plink --version
vcftools --version
merlin |grep MERLIN || echo 'merlin version'

module load snakemake/4.8.0 || which snakemake
#display snakemake version
snakemake --version 1>&2

#get dag
#snakemake --snakefile Snakefile --configfile "${SNAKEIN}" --dag > ${SNAKEIN}.dag.dot
#snakemake --snakefile Snakefile --configfile "${SNAKEIN}" --rulegraph > ${SNAKEIN}.rulegraph.dot
# for DOT in "${SNAKEIN}.dag.dot" "${SNAKEIN}.rulegraph.dot"; do dot -Tpdf ${DOT} > ${DOT}.pdf; done

#start pidstat and display every 1 second
exec 3>&-
exec 3<> "pidstat_${SLURM_JOB_ID}.csv"
pidstat -urdw -h 1 | tr -s ' ' | awk 'BEGIN{ OFS=";"; print "number;Time;PID;%usr;%system;%guest;%CPU;CPU;minflt/s;majflt/s;VSZ;RSS;%MEM;kB_rd/s;kB_wr/s;kB_ccwr/s;cswch/s;nvcswch/s;Command"; number=0
}{ if ( /^#/ ){number+=1} else if ( /^ [0-9]+/ ){print number,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18}}' >&3 &
PIDSTATID=$!

#start fg_sar (sar)
fg_sar start -i 1
fg_sar mark -l "snakemake"

#  If the number is omitted (i.e., only -j is given), the number of used cores is determined as the number of available CPU cores in the machine.
benchme snakemake \
 --snakefile Snakefile \
 --configfile "${SNAKEIN}" \
 --jobs 11 \
 --verbose --printshellcmds --timestamp --reason \
 --nolock \
 &> "${SNAKEIN}.local.conda.480.${SLURM_JOB_ID}.log" &

BENCHME_PID=$!
sleep 10  #wait few seconds for starting of snakemake child process
SNAKEMAKE_PID=$(pgrep -P "$BENCHME_PID" || echo 'unknown') # get child process of benchme process
pstree -p "$BENCHME_PID" || echo 'unknown pstree'
wait "$BENCHME_PID"

echo 'snakemake end'

#stop fg_sar
fg_sar stop

#process sar output
fg_sar calc

echo "BENCHME_PID: ${BENCHME_PID}"
echo "SNAKEMAKE_PID: ${SNAKEMAKE_PID}"
echo "SLURM_JOB_ID: ${SLURM_JOB_ID}"
echo "HOST: $HOSTNAME"

source deactivate lodseq

#cp -p *${SLURM_JOB_ID}* ~/WMS-benchmark/snakemake/.

#stop pidstat
kill "$PIDSTATID"
exec 3>&-

