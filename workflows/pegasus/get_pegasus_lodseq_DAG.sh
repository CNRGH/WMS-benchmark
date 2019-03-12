#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Author: Elise LARSONNEUR (elise.larsonneur@cea.fr)                           #
################################################################################

set -eo pipefail

########################################################################################
# GLOBAL VARIABLES                                                                     #
########################################################################################

NAME="$(basename "$0")"
readonly NAME

## parameters initialization
CHROMOSOMES="$(echo {1..22}) X Y"  ## -c
VCF='N.O.F.I.L.E'                  ## -i
TFAM='N.O.F.I.L.E'                 ## -p
DOM_MODEL='N.O.F.I.L.E'            ## -D
REC_MODEL='N.O.F.I.L.E'            ## -R
GENMAPS='N.O.D.I.R'                ## -g
OUTDIR='N.O.D.I.R'                 ## -o
OUTPREFIX='cohort'                 ## -s
MINLODTH=2.0                       ## -l
THREADS=1                          ## -t
DAG='N.O.F.I.L.E'                  ## -d

## path of bash scripts
SCRIPT_PATH=$HOME/benchmarkWMS/scripts
## number_of_tasks
NB_TASKS=0


########################################################################################
# FUNCTIONS                                                                            #
########################################################################################

# display_usage
# This function displays the usage of this program.
# No parameters
function display_usage {
  cat - <<EOF
  USAGE :
    ${NAME} [options] -i <in_vcf> -p <in_tfam> -g <in_genetic_maps_dir> \
-D <in_dom_model> -R <in_rec_model> -c <string> -o <out_dir>
     -i <inFile>       input vcf variant file
     -p <inFile>       input tfam pedigree file
     -g <inDirectory>  input directory where are stored genetic map files
     -D <inFile>       input merlin dominant model file
     -R <inFile>       input merlin recessive model file
     -c <string>       input list of chromosomes (default : all (except the MT chromosome))
     -o <inDirectory>  directory where are stored output files
     -s <string>       prefix of output files (default: cohort)
     -l <float>        minimal lod-score threshold (default : 2.0)
     -t <int>          number of threads used by plink steps (default : 1)
     -d <outFile>      output dot file
     -h                print help
  
DESCRIPTION :
    ${NAME} generates a pegasus dag of the genetic linkage 'lodseq' workflow.

EXAMPLE :
    ${NAME} -i cohort.vcf -p pedigree.tfam -g genetic_map_HapMapII_GRCh37/ \
-D dominant.model -R recessive.model -c '21 X Y' -o outdir/ -s cohort_result \
-l 1.8 -t 2 -d dag.dot
EOF

  return 0
}


########################################################################################
# MAIN FUNCTION                                                                        #
########################################################################################
# main
# Outputs .ped and .map files from input .vcf and .tfam files.
# Parameters : See 'getopts' part.
function main {

  # check whether user had supplied -h or --help . If yes display usage
  if [[ "$1" = "-?" ]] || [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]; then
    display_usage
    exit 0;
  fi

  # if less than seven arguments supplied, display usage
  if [[  $# -lt 7 ]]; then
    display_usage
    exit 1;
  fi


 ## catch option values
  while getopts :g:i:p:D:R:c:o:s:l:t:d: option
  do
    if [[ -z "${OPTARG}" ]]; then echo "[ERROR] Empty argument for option -${option}" 1>&2; exit 1; fi
    case "${option}" in
      g)
        GENMAPS="${OPTARG}";
        if [[ ! -d "${GENMAPS}" ]]; then echo "[ERROR] Input directory of genetic maps '${GENMAPS}' does not exist (option -g)." 1>&2; exit 1 ; fi
        ;; # -g <inDirectory>
      i)
        VCF="${OPTARG}";
        if [[ ! -f "${VCF}" ]]; then echo "[ERROR] Input VCF file '${VCF}' does not exist or is not a file (option -i)." 1>&2; exit 1 ; fi
        ;; # -i <inFile>
      p)
        TFAM="${OPTARG}";
        if [[ ! -f "${TFAM}" ]]; then echo "[ERROR] Input TFAM file '${TFAM}' does not exist or is not a file (option -p)." 1>&2; exit 1 ; fi
        ;; # -p <inFile>
      D)
        DOM_MODEL="${OPTARG}";
        if [[ ! -f "${DOM_MODEL}" ]]; then echo "[ERROR] Input dominant model '${DOM_MODEL}' does not exist or is not a file (option -D)." 1>&2; exit 1 ; fi
        ;; # -D <inFile>
      R)
        REC_MODEL="${OPTARG}";
        if [[ ! -f "${REC_MODEL}" ]]; then echo "[ERROR] Input recessive model '${REC_MODEL}' does not exist or is not a file (option -R)." 1>&2; exit 1 ; fi
        ;; # -R <inFile>
      c)
        CHROMOSOMES="${OPTARG}";
        chrarray=($CHROMOSOMES)
        for chr in "${chrarray[@]}"; do
          if [[ "${chr}" =~ ^[0-9]+$ ]]; then
             if [[ ${chr} -lt 1 ]] || [[ ${chr} -gt 22 ]]; then echo "[ERROR] invalid chromosome '""${chr}""' (option -c)." 1>&2; exit 1 ; fi
          else
             if [[ "${chr}" != "X" ]] && [[ "${chr}" != "Y" ]]; then echo "[ERROR] invalid chromosome '""${chr}""' (option -c)." 1>&2; exit 1 ; fi
          fi
        done
        ;;
      o)
        OUTDIR="${OPTARG}";
        if [[ ! -d "${OUTDIR}" ]]; then echo "[ERROR] Output directory '${OUTDIR}' does not exist (option -o). Please create it." 1>&2; exit 1 ; fi
        ;; # -o <inDirectory>
      s)
        OUTPREFIX="${OPTARG}";
        ;; # -s <string>
      l)
        MINLODTH="${OPTARG}"
        if ! [[ "${MINLODTH}" =~ ^[0-9]+\.?[0-9]*$ ]] || \
          [[ "$(echo "${MINLODTH}<=0" | bc -l)" -eq 1 ]]; then
          echo '[ERROR] The lod-score threshold must be greater than 0 (option -l).' >&2
          exit 1
        fi
        ;; # -l <float>
      t)
        THREADS="${OPTARG}";
        if ! [[ "${THREADS}" =~ ^[0-9]+$ ]] || [[ $THREADS -lt 1 ]]; then echo '[ERROR] the number of threads must be greater than 0 (option -t).' 1>&2 ; exit 1 ; fi;
        ;; # -t <number of threads>
      d)
        DAG="${OPTARG}";
        DAGDIR=$(dirname "$DAG");
        if [[ ! -d "${DAGDIR}" ]]; then echo "[ERROR] Output directory of .dot file '${DAGDIR}' does not exist (option -d). Please create it." 1>&2; exit 1 ; fi
        ;; # -d <outFile>
      :)
        echo "[ERROR] option ${OPTARG} : missing argument" 1>&2 ; exit 1
        ;;
      \?)
        echo "[ERROR] ${OPTARG} : invalid option" 1>&2 ; exit 1
        ;;
    esac
  done

  readonly VCF TFAM DOM_MODEL REC_MODEL GENMAPS OUTDIR CHROMOSOMES THREADS MINLODTH
 
  ### checking input directories and files
  if [[ "${VCF}" = 'N.O.F.I.L.E' ]]; then echo '[ERROR] Input VCF file was not supplied (mandatory option -i)' 1>&2; exit 1 ; fi
  if [[ "${TFAM}" = 'N.O.F.I.L.E' ]]; then echo '[ERROR] Input TFAM file was not supplied (mandatory option -p)' 1>&2; exit 1 ; fi
  if [[ "${DOM_MODEL}" = 'N.O.F.I.L.E' ]]; then echo '[ERROR] Input dominant model was not supplied (mandatory option -D)' 1>&2; exit 1 ; fi
  if [[ "${REC_MODEL}" = 'N.O.F.I.L.E' ]]; then echo '[ERROR] Input recessive model was not supplied (mandatory option -R)' 1>&2; exit 1 ; fi
  if [[ "${DAG}" = 'N.O.F.I.L.E' ]]; then echo '[ERROR] Output dot file was not supplied (mandatory option -d)' 1>&2; exit 1 ; fi
  if [[ "${GENMAPS}" = 'N.O.D.I.R' ]]; then echo '[ERROR] Directory of genetic maps was not supplied (mandatory option -g)' 1>&2; exit 1 ; fi
  if [[ "${OUTDIR}" = 'N.O.D.I.R' ]]; then echo '[ERROR] Output directory was not supplied (mandatory option -o)' 1>&2; exit 1 ; fi


  ### print used parameters
  cat - 1>&2 <<EOF
    ${NAME}
    Parameters as interpreted:
      -i ${VCF}
      -p ${TFAM}
      -g ${GENMAPS}
      -D ${DOM_MODEL}
      -R ${REC_MODEL}
      -c ${CHROMOSOMES}
      -o ${OUTDIR}
      -s ${OUTPREFIX}
      -l ${MINLODTH}
      -t ${THREADS}
      -d ${DAG}

EOF



  ### main process

  ## FIRST, PRINT TASKS OF THE DAG
  echo '#NODES OF THE DAG' #COMMENTS MUST BE PRECEDED BY A '#' IN THE DAG FILE

  #1-prepareVCF
  OUTPREF=${OUTPREFIX}_prep
  LOGPREF=$OUTDIR/prepareVCF/prepareVCF
  cat - <<EOF
TASK prepareVCF \
-c $THREADS \
bash -c "mkdir -p $OUTDIR/prepareVCF \
&& $SCRIPT_PATH/prepareVCF.sh \
-i $VCF \
-p $TFAM \
-o $OUTDIR/prepareVCF \
-s $OUTPREF \
-t 1 \
1>${LOGPREF}.out \
2>${LOGPREF}.err \
&& echo \$? > ${LOGPREF}.rc \
|| echo \$? > ${LOGPREF}.rc ; \
exit \$(cat ${LOGPREF}.rc)"
EOF
  NB_TASKS=$((NB_TASKS + 1))

  #2-run next steps for each chromosome
  for CHROM in $CHROMOSOMES; do 

    LOGPREF=$OUTDIR/prepareGeneticMaps/${CHROM}/prepareGeneticMaps
    cat - <<EOF
TASK prepareGeneticMapsChr${CHROM} \
bash -c "mkdir -p $OUTDIR/prepareGeneticMaps/${CHROM} \
&& $SCRIPT_PATH/prepareGeneticMaps.sh \
-g $GENMAPS \
-o $OUTDIR/prepareGeneticMaps/${CHROM} \
-c $CHROM \
1>${LOGPREF}.out \
2>${LOGPREF}.err \
&& echo \$? > ${LOGPREF}.rc \
|| echo \$? > ${LOGPREF}.rc ; \
exit \$(cat ${LOGPREF}.rc)"
EOF

    MAP=$OUTDIR/prepareVCF/${OUTPREFIX}_prep.map
    PED=$OUTDIR/prepareVCF/${OUTPREFIX}_prep.ped
    OUTPREF=${OUTPREFIX}_chr
    LOGPREF=$OUTDIR/splitByChrom/${CHROM}/splitByChrom
    cat - <<EOF
TASK splitByChromChr${CHROM} \
-c $THREADS \
bash -c "mkdir -p $OUTDIR/splitByChrom/${CHROM} \
&& $SCRIPT_PATH/splitByChrom.sh \
-m $MAP \
-p $PED \
-c $CHROM \
-o $OUTDIR/splitByChrom/${CHROM} \
-s $OUTPREF \
-t 1 \
1>${LOGPREF}.out \
2>${LOGPREF}.err \
&& echo \$? > ${LOGPREF}.rc \
|| echo \$? > ${LOGPREF}.rc ; \
exit \$(cat ${LOGPREF}.rc)"
EOF

    MAP=$OUTDIR/splitByChrom/${CHROM}/${OUTPREFIX}_chr${CHROM}.map
    OUTPREF=${OUTPREFIX}_sgl_chr
    LOGPREF=$OUTDIR/prepareSinglePointFiles/${CHROM}/prepareSinglePointFiles
    cat - <<EOF
TASK prepareSinglePointFilesChr${CHROM} \
bash -c "mkdir -p $OUTDIR/prepareSinglePointFiles/${CHROM} \
&& $SCRIPT_PATH/prepareSinglePointFiles.sh \
-m $MAP \
-c $CHROM \
-o $OUTDIR/prepareSinglePointFiles/${CHROM} \
-s $OUTPREF \
1>${LOGPREF}.out \
2>${LOGPREF}.err \
&& echo \$? > ${LOGPREF}.rc \
|| echo \$? > ${LOGPREF}.rc ; \
exit \$(cat ${LOGPREF}.rc)"
EOF

    MAP=$OUTDIR/splitByChrom/${CHROM}/${OUTPREFIX}_chr${CHROM}.map
    PED=$OUTDIR/splitByChrom/${CHROM}/${OUTPREFIX}_chr${CHROM}.ped
    OUTMAPS=$OUTDIR/prepareGeneticMaps/${CHROM}
    OUTPREF=${OUTPREFIX}_multi_chr
    LOGPREF=$OUTDIR/prepareMultiPointFiles/${CHROM}/prepareMultiPointFiles
    cat - <<EOF
TASK prepareMultiPointFilesChr${CHROM} \
-c $THREADS \
bash -c "mkdir -p $OUTDIR/prepareMultiPointFiles/${CHROM} \
&& $SCRIPT_PATH/prepareMultiPointFiles.sh \
-m $MAP \
-p $PED \
-c $CHROM \
-g $OUTMAPS \
-o $OUTDIR/prepareMultiPointFiles/${CHROM} \
-s $OUTPREF \
-t 1 \
1>${LOGPREF}.out \
2>${LOGPREF}.err \
&& echo \$? > ${LOGPREF}.rc \
|| echo \$? > ${LOGPREF}.rc ; \
exit \$(cat ${LOGPREF}.rc)"
EOF

    MAP=$OUTDIR/prepareSinglePointFiles/${CHROM}/${OUTPREFIX}_sgl_chr${CHROM}.map
    DAT=$OUTDIR/prepareSinglePointFiles/${CHROM}/${OUTPREFIX}_sgl_chr${CHROM}.dat
    PED=$OUTDIR/splitByChrom/${CHROM}/${OUTPREFIX}_chr${CHROM}.ped
    OUTPREF=results_singlepoint_chr
    LOGPREF=$OUTDIR/runSinglePointMerlin/${CHROM}/runSinglePointMerlin
    cat - <<EOF
TASK runSinglePointMerlinChr${CHROM} \
bash -c "mkdir -p $OUTDIR/runSinglePointMerlin/${CHROM} \
&& $SCRIPT_PATH/runSinglePointMerlin.sh \
-D $DOM_MODEL \
-R $REC_MODEL \
-m $MAP \
-d $DAT \
-p $PED \
-c $CHROM \
-o $OUTDIR/runSinglePointMerlin/${CHROM} \
-s $OUTPREF \
-l ${MINLODTH} \
1>${LOGPREF}.out \
2>${LOGPREF}.err \
&& echo \$? > ${LOGPREF}.rc \
|| echo \$? > ${LOGPREF}.rc ; \
exit \$(cat ${LOGPREF}.rc)"
EOF

    MAP=$OUTDIR/prepareMultiPointFiles/${CHROM}/${OUTPREFIX}_multi_chr${CHROM}.map
    DAT=$OUTDIR/prepareMultiPointFiles/${CHROM}/${OUTPREFIX}_multi_chr${CHROM}.dat
    PED=$OUTDIR/prepareMultiPointFiles/${CHROM}/${OUTPREFIX}_multi_chr${CHROM}.ped
    OUTPREF=results_multipoint_chr
    LOGPREF=$OUTDIR/runMultiPointMerlin/${CHROM}/runMultiPointMerlin
    cat - <<EOF
TASK runMultiPointMerlinChr${CHROM} \
bash -c "mkdir -p $OUTDIR/runMultiPointMerlin/${CHROM} \
&& $SCRIPT_PATH/runMultiPointMerlin.sh \
-D $DOM_MODEL \
-R $REC_MODEL \
-m $MAP \
-d $DAT \
-p $PED \
-c $CHROM \
-o $OUTDIR/runMultiPointMerlin/${CHROM} \
-s $OUTPREF \
-l ${MINLODTH} \
1>${LOGPREF}.out \
2>${LOGPREF}.err \
&& echo \$? > ${LOGPREF}.rc \
|| echo \$? > ${LOGPREF}.rc ; \
exit \$(cat ${LOGPREF}.rc)"
EOF
  done

  LOGPREF=$OUTDIR/mergeResults/mergeResults
  cat - <<EOF
TASK mergeResults \
bash -c "mkdir -p $OUTDIR/mergeResults \
&& $SCRIPT_PATH/mergeResultsByDir.sh $OUTDIR \
1>${LOGPREF}.out \
2>${LOGPREF}.err \
&& echo \$? > ${LOGPREF}.rc \
|| echo \$? > ${LOGPREF}.rc ; \
exit \$(cat ${LOGPREF}.rc)"
EOF

  NB_TASKS=$((NB_TASKS + 1))



  #SECOND, PRINT EDGES OF THE DAG 
  #        AND PRINT DOT FILE OF THE DAG
  echo ''
  echo '#EDGES OF THE DAG' #COMMENTS MUST BE PRECEDED BY A '#' IN THE DAG FILE
  echo 'digraph geneticLinkage {' > "${DAG}"
  for CHROM in $CHROMOSOMES; do
    echo "EDGE prepareVCF splitByChromChr${CHROM}"
    echo "\"prepareVCF\" -> \"splitByChromChr${CHROM}\"" >> "${DAG}"
    echo "EDGE splitByChromChr${CHROM} prepareSinglePointFilesChr${CHROM}"
    echo "\"splitByChromChr${CHROM}\" -> \"prepareSinglePointFilesChr${CHROM}\"" >> "${DAG}"
    echo "EDGE splitByChromChr${CHROM} runSinglePointMerlinChr${CHROM}"
    echo "\"splitByChromChr${CHROM}\" -> \"runSinglePointMerlinChr${CHROM}\"" >> "${DAG}"
    echo "EDGE prepareSinglePointFilesChr${CHROM} runSinglePointMerlinChr${CHROM}"
    echo "\"prepareSinglePointFilesChr${CHROM}\" -> \"runSinglePointMerlinChr${CHROM}\"" >> "${DAG}"
    echo "EDGE splitByChromChr${CHROM} prepareMultiPointFilesChr${CHROM}"
    echo "\"splitByChromChr${CHROM}\" -> \"prepareMultiPointFilesChr${CHROM}\"" >> "${DAG}"
    echo "EDGE prepareGeneticMapsChr${CHROM} prepareMultiPointFilesChr${CHROM}"
    echo "\"prepareGeneticMapsChr${CHROM}\" -> \"prepareMultiPointFilesChr${CHROM}\"" >> "${DAG}"
    echo "EDGE prepareMultiPointFilesChr${CHROM} runMultiPointMerlinChr${CHROM}"
    echo "\"prepareMultiPointFilesChr${CHROM}\" -> \"runMultiPointMerlinChr${CHROM}\"" >> "${DAG}"
    echo "EDGE runSinglePointMerlinChr${CHROM} mergeResults"
    echo "\"runSinglePointMerlinChr${CHROM}\" -> \"mergeResults\"" >> "${DAG}"
    echo "EDGE runMultiPointMerlinChr${CHROM} mergeResults"
    echo "\"runMultiPointMerlinChr${CHROM}\" -> \"mergeResults\"" >> "${DAG}"
    NB_TASKS=$((NB_TASKS + 6))
  done

  echo "Number of tasks: $NB_TASKS" 1>&2
  echo "}" >> "${DAG}"

}

main "$@"

