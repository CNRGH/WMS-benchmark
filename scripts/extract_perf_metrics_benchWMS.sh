#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                          #
#          Jonathan MERCIER (jonathan.mercier@cea.fr)                          #
################################################################################

JOB=$1
LABEL=$2
CPUS=12
#NODE=$(ccc_macct $JOB |grep lirac|head -n 1 |awk -F= '{print $2}')
NODE=$HOSTNAME

# [ SAR METRICS ] => whole node
f=global-$JOB.tsv
#max user cpu %
S_CPUP=$(awk 'BEGIN{max=0}{if (NR>1  && $2>max){max=$2}}END {print max}' "$f") #max user cpu time %
#mean user cpu %
S_MEAN_CPUP=$(awk 'BEGIN{mean=0; sum=0; cpt=0}{if(NR>1){sum+=$2; cpt+=1}}END{mean=(sum/cpt); print mean}' "$f")
S_MED_CPUP=$(gawk 'BEGIN{
    n=0
}{
    if (NR>1){
        cpu[n++]=$2;
    }
}
END{
    asort(cpu)
    if (n % 2){
        print cpu[(n+1) / 2];
    }
    else{
         print (cpu[(n / 2)] + cpu[(n / 2) + 1]) / 2.0;
    }
}' "$f") #median cpu

#max memory
S_MEM=$(awk 'BEGIN{max=0}{if (NR>1  && $9>max){max=$9}}END {print max}' "$f") #max memory
S_MEAN_MEM=$(awk 'BEGIN{mem=0;n=0}{if (NR>1){mem+=$9;n++}}END {printf "%.6f\n", mem/n}' "$f") #mean memory
S_MED_MEM=$(awk 'BEGIN{
    n=0
}{
    if (NR>1){
        mem[n++]=$9;
    }
}
END{
    asort(mem)
    if (n % 2){
        print mem[(n+1) / 2];
    }
    else{
         print (mem[(n / 2)] + mem[(n / 2) + 1]) / 2.0;
    }
}' "$f") #median memory

#iowait $5
S_IOWAIT_VAL=$( awk -v cpus=$CPUS 'BEGIN{sum_iowait=0; nb_sec=0; time=""; mintime=0}{
                         if(NR>1 &&  $0 ~ /^[0-9]/ ){
                           sum_iowait+=$5;
                           time=$1;
                           if($5>0){
                             nb_sec+=1
                           }
                           split(time,a,":");
                           elapsed_time_sec_cur=((3600*a[1])+(60*a[2])+a[3]);
                           if(mintime==0){ mintime=elapsed_time_sec_cur };
                           if(elapsed_time_sec_cur < mintime){ mintime=elapsed_time_sec_cur };
                         }
                         }END{
                         split(time,a,":");
                         elapsed_time_sec_converted=(3600*a[1])+(60*a[2])+a[3];
                         elapsed_time_sec=(elapsed_time_sec_converted - mintime)
                         elapsed_time_min=elapsed_time_sec/60
                         iowaitmax=(100*cpus*elapsed_time_sec);
                         prct_iowait_time=(sum_iowait*100/iowaitmax);
                         iowait_time_min=(prct_iowait_time*elapsed_time_sec/100)/60;
                         iowait_time_sec=(prct_iowait_time*elapsed_time_sec/100);
                         printf "%.6f %.6f\n", prct_iowait_time, iowait_time_sec }' "$f" )
S_IOWAIT_TIME_PRCT=$(echo "$S_IOWAIT_VAL" |awk '{print $1}')
S_IOWAIT_TIME_SEC=$(echo "$S_IOWAIT_VAL" |awk '{print $2}')

#idle $7
##  the same command as for iowait but here we replace only $5 by $7,
##  and output idle time is expressed in minutes:
S_IDLE_VAL=$( awk -v cpus=$CPUS 'BEGIN{sum_iowait=0; nb_sec=0; time=""; mintime=0}{
                         if(NR>1 &&  $0 ~ /^[0-9]/ ){
                           sum_iowait+=$7;
                           time=$1;
                           if($7>0){
                             nb_sec+=1
                           }
                           split(time,a,":");
                           elapsed_time_sec_cur=((3600*a[1])+(60*a[2])+a[3]);
                           if(mintime==0){ mintime=elapsed_time_sec_cur };
                           if(elapsed_time_sec_cur < mintime){ mintime=elapsed_time_sec_cur };
                         }
                         }END{
                         split(time,a,":");
                         elapsed_time_sec_converted=(3600*a[1])+(60*a[2])+a[3];
                         elapsed_time_sec=(elapsed_time_sec_converted - mintime)
                         elapsed_time_min=elapsed_time_sec/60
                         iowaitmax=(100*cpus*elapsed_time_sec);
                         prct_iowait_time=(sum_iowait*100/iowaitmax);
                         iowait_time_min=(prct_iowait_time*elapsed_time_sec/100)/60;
                         printf "%.6f %.6f\n", prct_iowait_time, iowait_time_min }' "$f" )
S_IDLE_TIME_PRCT=$(echo "$S_IDLE_VAL" |awk '{print $1}')
S_IDLE_TIME_MIN=$(echo "$S_IDLE_VAL" |awk '{print $2}')



# [ BENCHME METRICS ]
B_TIME=$(ls ./*"${JOB}"* |grep -v pdf |xargs grep 'ElapsedTime' |awk '{print $2}')
B_CPUP=$(ls ./*"${JOB}"* |grep -v pdf |xargs grep 'CPU_(U+S)/E' |awk '{print $2}')
BB_MEM=$(ls ./*"${JOB}"* |grep -v pdf |xargs grep 'PeakMemory' |awk '{print $2}')
B_MEM=$(awk "BEGIN {printf \"%.6f\",${BB_MEM}/(1024*1024)}") #float division - convert kilobytes into gbytes



# [ PIDSTAT METRICS ] => per (master?) process
PID_WF=$(grep PID ./*"${JOB}"* |grep -v 'Binary'| grep -v 'BENCHME_PID' | grep -v 'PID_Command' | grep -v 'PID;'|awk '{print $NF}')
f=pidstat_${JOB}.csv
grep ";$PID_WF;" "$f" > "$f.tmp"
#max cpu %
P_CPUP=$(awk -F";" 'BEGIN{max=0}{if(NF==19 && $7>max){max=$7}}END{print max}' "$f.tmp")
#mean cpu %
P_MEAN_CPUP=$(awk -F";" 'BEGIN{mean=0; sum=0; cpt=0}{if(NF==19){sum+=$7; cpt+=1}}END{mean=(sum/cpt); print mean}' "$f.tmp")
# mediane cpu %
P_MED_CPUP=$(gawk -F";" 'BEGIN{
    n=0
}{
    if (NF==19){
        cpu[n++]=$7;
    }
}
END{
    asort(cpu)
    if (n % 2){
        print cpu[(n+1) / 2];
    }
    else{
         print (cpu[(n / 2)] + cpu[(n / 2) + 1]) / 2.0;
    }
}' "$f.tmp") #median cpu

#max rss (memory) (kb)
PP_MEM=$(awk -F";" 'BEGIN{max=0}{if(NF==19 && $12>max){max=$12}}END{print max}' "$f.tmp")
P_MEM=$(awk "BEGIN {printf \"%.6f\",${PP_MEM}/(1024*1024)}") #float division - convert kilobytes into gbytes
#mean rss
P_MEAN_MEM=$(awk -F";" 'BEGIN{mean=0; sum=0; cpt=0}{if(NF==19){sum+=$12; cpt+=1;}}END{mean=(sum/cpt); print mean/(1024*1024)}' "$f.tmp")
#median rss
P_MED_MEM=$(gawk  -F";" 'BEGIN{
    n=0
}{
    if (NF==19){
        mem[n++]=$12;
    }
}
END{
    asort(mem)
    if (n % 2){
        result = mem[(n+1) / 2];
    }
    else{
         result = (mem[(n / 2)] + cpu[(n / 2) + 1]) / 2.0;
    }
    printf "%.6f", result/(1024*1024);
}' "$f.tmp")
#max kB_rd/s - Number of kilobytes the task has caused to be read from disk per second.
P_KB_RD_S=$(awk -F";" 'BEGIN{max=0}{if(NF==19 && $14>max){max=$14}}END{printf "%.6f",max/1024}' "$f.tmp") #convert into megaBytes
#max kB_wr/s - Number of kilobytes the task has caused, or shall cause to be written to disk per second.
P_KB_WR_S=$(awk -F";" 'BEGIN{max=0}{if(NF==19 && $15>max){max=$15}}END{printf "%.6f",max/1024}' "$f.tmp") #convert into megaBytes
#max kB_ccwr/s - Number  of  kilobytes  whose  writing  to disk has been cancelled by the task.
#            This may occur when the task truncates some dirty pagecache.
#            In this case, some IO which another task has been accounted for will not be happening.
P_KB_CCWR_S=$(awk -F";" 'BEGIN{max=0}{if(NF==19 && $16>max){max=$16}}END{printf "%.6f",max/1024}' "$f.tmp") #convert into megaBytes
#max cswch/s - Total number of voluntary context switches the task made per second.
#          A voluntary context switch occurs when a task blocks because it requires a resource that is unavailable.
P_CSWCH_S=$(awk -F";" 'BEGIN{max=0}{if(NF==19 && $17>max){max=$17}}END{print max}' "$f.tmp")
#max nvcswch/s - Total number of non voluntary context switches the task made per second.
#            A involuntary context switch takes place when a task executes for
#            the duration of its time slice and then is forced to relinquish the processor.
P_NVCSWCH_S=$(awk -F";" 'BEGIN{max=0}{if(NF==19 && $18>max){max=$18}}END{print max}' "$f.tmp")
rm "$f.tmp"


#all memory values expressed in Gigabytes
echo -e "$LABEL\t$B_TIME\t$B_CPUP\t$B_MEM\t$S_CPUP\t$S_MEAN_CPUP\t$S_MEM\t$S_MEAN_MEM\t$S_MED_CPUP\t$S_MED_MEM\t$NODE\t$JOB\t$P_CPUP\t$P_MEAN_CPUP\t$P_MED_CPUP\t$P_MEM\t$P_MEAN_MEM\t$P_MED_MEM\t$P_KB_RD_S\t$P_KB_WR_S\t$P_KB_CCWR_S\t$P_CSWCH_S\t$P_NVCSWCH_S\t$S_IOWAIT_TIME_PRCT\t$S_IOWAIT_TIME_SEC\t$S_IDLE_TIME_PRCT\t$S_IDLE_TIME_MIN"

