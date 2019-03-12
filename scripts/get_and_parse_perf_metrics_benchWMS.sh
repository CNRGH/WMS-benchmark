#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                          #
#          Jonathan MERCIER (jonathan.mercier@cea.fr)                          #
################################################################################

set -eo pipefail

OUTDIR=~/plots
mkdir -p $OUTDIR
SCRIPTS=~/WMS-benchmark/scripts

echo -e "Workflow\tB_ElapsedTime\tB_CPU_Percent\tB_Memory\tS_Max_CPU_Percent\tS_Mean_CPU_Percent\tS_Median_CPU_Percent\tS_Max_Memory\tS_Mean_Memory\tS_Median_Memory\tNode\tJob\tP_CPU_Percent\tP_Mean_CPU_Percent\tP_Median_CPU_Percent\tP_Max_MEM\tP_Mean_MEM\tP_Median_MEM\tP_KB_RD_S\tP_KB_WR_S\tP_KB_CCWR_S\tP_CSWCH_S\tP_NVCSWCH_S\tS_IOWAIT_TIME_PRCT\tS_IOWAIT_TIME_SEC\tS_IDLE_TIME_PRCT\tS_IDLE_TIME_MIN" \
  > $OUTDIR/workflow.values

cd ~/WMS-benchmark/workflows

pushd nextflow
    LABEL=nextflow_11slaves_nfs
    for JOB in {1219587..1219596}; do
        $SCRIPTS/extract_perf_metrics_benchWMS.sh $JOB $LABEL;
    done >> $OUTDIR/workflow.values
popd

pushd cromwell
    LABEL=cromwell_11slaves_nfs
    for JOB in {1219597..1219606}; do
        $SCRIPTS/extract_perf_metrics_benchWMS.sh $JOB $LABEL;
    done >> $OUTDIR/workflow.values
popd

pushd snakemake
    LABEL=snakemake_11slaves_nfs
    for JOB in {1219607..1219616}; do
        $SCRIPTS/extract_perf_metrics_benchWMS.sh $JOB $LABEL;
    done >> $OUTDIR/workflow.values
popd

pushd cwltoil
    LABEL=cwltoil_11slaves_nfs
    for JOB in {1219617..1219626}; do
        $SCRIPTS/extract_perf_metrics_benchWMS.sh $JOB $LABEL;
    done >> $OUTDIR/workflow.values
popd

pushd pegasus
    LABEL=pegasus_11slaves_nfs
    for JOB in {1219627..1219636}; do
        $SCRIPTS/extract_perf_metrics_benchWMS.sh $JOB $LABEL;
    done >> $OUTDIR/workflow.values
popd

awk 'BEGIN{
n=0;
cur_label="none";
prev_label="none";
B_ElapsedTime=0;
B_CPUPercent=0;
B_Memory=0;
S_MaxCPUPercent=0;
S_MeanCPUPercent=0;
S_Memory=0;
P_CPUP=0;
P_MEAN_CPUP=0;
P_MEM=0;
P_CSWCH_S=0;
P_NVCSWCH_S=0;
S_IOWAIT_TIME_PRCT=0;
S_IOWAIT_TIME_SEC=0;
S_IDLE_TIME_PRCT=0;
S_IDLE_TIME_MIN=0;
print "Workflow Elapsed_Time All_Max_CPU_Prct All_Median_CPU_Prct All_Max_Memory All_Median_Memory Process_Max_CPU_Prct Process_Median_CPU_Prct Process_Max_Memory Process_Median_Memory Process_CSWCH_S Process_NVCSWCH_S All_IOWAIT_TIME_SEC All_IDLE_TIME_MIN"
         }{
        cur_label=$1;
        if( (NR>1) && (prev_label == "none" || prev_label == cur_label) ){
            prev_label=$1;
            n+=1;
            B_ElapsedTime+=$2;
            S_Max_CPU_Percent+=$5;
            S_Median_CPU_Percent+=$7;
            S_Max_Memory+=$8;
            S_Median_Memory+=$10;
            P_Max_CPU_Percent+=$13;
            P_Median_CPU_Percent+=$15;
            P_Max_MEM+=$16;
            P_Median_MEM+=$18;
            P_CSWCH_S+=$22;
            P_NVCSWCH_S+=$23;
            S_IOWAIT_TIME_SEC+=$25;
            S_IDLE_TIME_MIN+=$27;
        }
        if ( (NR>1) && ( prev_label != cur_label )){
            printf "%s %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f\n", prev_label, B_ElapsedTime/n, S_Max_CPU_Percent/n, S_Median_CPU_Percent/n, S_Max_Memory/n, S_Median_Memory/n, P_Max_CPU_Percent/n, P_Median_CPU_Percent/n, P_Max_MEM/n, P_Median_MEM/n, P_CSWCH_S/n, P_NVCSWCH_S/n, S_IOWAIT_TIME_SEC/n, S_IDLE_TIME_MIN/n;
            prev_label=$1;
            n=1;
            B_ElapsedTime=$2;
            S_Max_CPU_Percent=$5;
            S_Median_CPU_Percent=$7;
            S_Max_Memory=$8;
            S_Median_Memory=$10;
            P_Max_CPU_Percent=$13;
            P_Median_CPU_Percent=$15;
            P_Max_MEM=$16;
            P_Median_MEM=$18;
            P_CSWCH_S=$22;
            P_NVCSWCH_S=$23;
            S_IOWAIT_TIME_SEC=$25;
            S_IDLE_TIME_MIN=$27;
         }
     }
    END{
        printf "%s %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f\n", prev_label, B_ElapsedTime/n, S_Max_CPU_Percent/n, S_Median_CPU_Percent/n, S_Max_Memory/n, S_Median_Memory/n, P_Max_CPU_Percent/n, P_Median_CPU_Percent/n, P_Max_MEM/n, P_Median_MEM/n, P_CSWCH_S/n, P_NVCSWCH_S/n, S_IOWAIT_TIME_SEC/n, S_IDLE_TIME_MIN/n;
 }' $OUTDIR/workflow.values > $OUTDIR/workflow.meanperlabel.values

SUFFIX=_11slaves_nfs
awk -v suffix=$SUFFIX '{if(NR>1){label=$1""suffix; printf "%s %.3f\n", label, $2}}' $OUTDIR/inodes_per_wf.txt \
  | sort -k 1 >  $OUTDIR/inodes_per_wf.txt.tmp

sed '1d' $OUTDIR/workflow.meanperlabel.values |sort -k 1  > $OUTDIR/workflow.meanperlabel.values.tmp

join $OUTDIR/workflow.meanperlabel.values.tmp $OUTDIR/inodes_per_wf.txt.tmp \
	> $OUTDIR/workflow.meanperlabel.values.tmp2

header=$(head -n 1 $OUTDIR/workflow.meanperlabel.values)
echo -e "$header NO_INODES_PER_TASK" > $OUTDIR/workflow.meanperlabel.values.tmp3
cat $OUTDIR/workflow.meanperlabel.values.tmp2 >> $OUTDIR/workflow.meanperlabel.values.tmp3

mv $OUTDIR/workflow.meanperlabel.values.tmp3 $OUTDIR/workflow.meanperlabel.values

rm $OUTDIR/workflow.meanperlabel.values.tmp
rm $OUTDIR/workflow.meanperlabel.values.tmp2
rm $OUTDIR/inodes_per_wf.txt.tmp

