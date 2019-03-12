#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                          #
#          Jonathan MERCIER (jonathan.mercier@cea.fr)                          #
################################################################################

OUTDIR=~/plots
OUTFILE=$OUTDIR/inodes_per_wf.txt
mkdir -p $OUTDIR
TASKS=146

echo -e "workflow\tinodes_per_task" > $OUTFILE

echo 'cromwell'
SUM=0
for DIR in \
~/trioCEPH1463/cromwell/cromwell-workflow-logs/ \
~/trioCEPH1463/cromwell/cromwell-executions/ \
~/trioCEPH1463/cromwell/trioCEPH1463/cromwell/; do 
INODES=$(find $DIR -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n | awk 'BEGIN{sum=0};{sum+=$1}END{print sum}')
SUM=$((SUM+INODES))
echo "$DIR $INODES"
done
INODES_PER_TASK=$(echo "($SUM/$TASKS)" |bc -l)
echo -e "cromwell\t$INODES_PER_TASK" >> $OUTFILE

echo ''
echo 'nextflow'
SUM=0
for DIR in \
~/trioCEPH1463/nextflow/.nextflow/ \
~/trioCEPH1463/nextflow/trioCEPH1463/nextflow/; do
INODES=$(find $DIR -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n | awk 'BEGIN{sum=0};{sum+=$1}END{print sum}')
SUM=$((SUM+INODES))
echo "$DIR $INODES"
done
INODES_PER_TASK=$(echo "($SUM/$TASKS)" |bc -l)
echo -e "nextflow\t$INODES_PER_TASK" >> $OUTFILE

echo ''
echo 'snakemake'
SUM=0
for DIR in \
~/trioCEPH1463/snakemake/.snakemake/ \
~/trioCEPH1463/snakemake/trioCEPH1463/snakemake/; do
INODES=$(find $DIR -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n | awk 'BEGIN{sum=0};{sum+=$1}END{print sum}')
SUM=$((SUM+INODES))
echo "$DIR $INODES"
done
INODES_PER_TASK=$(echo "($SUM/$TASKS)" |bc -l)
echo -e "snakemake\t$INODES_PER_TASK" >> $OUTFILE

echo ''
echo 'toilcwl'
DIR=~/trioCEPH1463/toilcwl/trioCEPH1463/toilcwl/
INODES=$(find $DIR -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n | awk 'BEGIN{sum=0};{sum+=$1}END{print sum}')
echo "$DIR $INODES"
SUM=$INODES
INODES_PER_TASK=$(echo "($SUM/$TASKS)" |bc -l)
echo -e "toil\t$INODES_PER_TASK" >> $OUTFILE

echo ''
echo 'pegasus'
DIR=~/trioCEPH1463/pegasus/trioCEPH1463/pegasus/
INODES=$(find $DIR -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n | awk 'BEGIN{sum=0};{sum+=$1}END{print sum}')
echo "$DIR $INODES"
SUM=$INODES
INODES_PER_TASK=$(echo "($SUM/$TASKS)" |bc -l)
echo -e "pegasus\t$INODES_PER_TASK" >> $OUTFILE

echo ''
echo 'bash'
DIR=~/trioCEPH1463/bash/trioCEPH1463/bash/
INODES=$(find $DIR -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n | awk 'BEGIN{sum=0};{sum+=$1}END{print sum}')
echo "$DIR $INODES"
SUM=$INODES
INODES_PER_TASK=$(echo "($SUM/$TASKS)" |bc -l)
echo -e "bash\t$INODES_PER_TASK" >> $OUTFILE

