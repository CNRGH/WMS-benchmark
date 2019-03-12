################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Author: Elise LARSONNEUR (elise.larsonneur@cea.fr)                           #
################################################################################


## This workflow computes LOD SCORES from an input gVCF file using MERLIN
workflow lodseq {

   # variable parameters - values of these parameters are defined by the user into the file 'params.json' 
   # ===================
   Int THREADS
   Float inLodThreshold
   File inGVCFPath
   File inTfamPath
   File inDomModelPath
   File inRecModelPath          #check whether the 'File' exists (it can not be a directory) 
   String inGeneticMapsDirPath  #do not check whether the 'String' exists (here a directory)
   String inScriptsDirPath      #do not check whether the 'String' exists (here a directory)
   String outDirPath
   String outPrefixPath
   String outLogPath
   ## Array[String] chromosomes = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","X","Y"]
   ## Array[String] chromosomes = ["21","X","Y"]
   Array [String] chromosomes

   # static parameters - defined in this '.wdl' workflow file
   # =================
   # Array [String] models = ["recessive","dominant"]
 
  
   # calling of tasks - in execution order
   # ================

   ## convert formats and check that input/output directories and input files exist 
   call prepareVCF {
      input: inLodTh=inLodThreshold,
         inGVCF=inGVCFPath,
         inTFAM=inTfamPath,
         outPrefix=outPrefixPath,
         outDir=outDirPath,
         outLog=outLogPath,
         inGeneticMapsDir=inGeneticMapsDirPath,
         inScriptsDir=inScriptsDirPath,
         inDomModel=inDomModelPath,
         inRecModel=inRecModelPath,
         THREADS=THREADS
   }


   ## prepare genetic maps
   scatter (chr in chromosomes){ 
       call prepareGeneticMaps {
         input: chrom=chr,
            outDir=outDirPath,
            outLog=outLogPath,
            inGeneticMapsDir=inGeneticMapsDirPath,
            inScriptsDir=inScriptsDirPath
       }
   }


   ## 1st LOOP
   ## Split Files by Chromosome
   scatter (chr in chromosomes){ 

    call splitByChrom {
      input: inMap=prepareVCF.map,
         inPed=prepareVCF.ped,
         inScriptsDir=inScriptsDirPath,
         chrom=chr,
         outPrefix=outPrefixPath,
         outDir=outDirPath,
         outLog=outLogPath,
         THREADS=THREADS
    }
   }


   ## 2nd LOOP
   ## Prepare files for Merlin Single Point 
   ##    Analysis and Run it
   scatter (chr in chromosomes){ 

    call prepareSinglePointFiles {
      input: chrom=chr,
         outPrefix=outPrefixPath,
         outDir=outDirPath,
         outLog=outLogPath,
         inMapFiles=splitByChrom.outMap,
         inScriptsDir=inScriptsDirPath
    }

    call runSinglePointMerlin {
        input: chrom=chr,
           outPrefix=outPrefixPath,
           outDir=outDirPath,
           outLog=outLogPath,
           inLodTh=inLodThreshold,
           inDat=prepareSinglePointFiles.outDat,
           inPedFiles=splitByChrom.outPed,
           inMap=prepareSinglePointFiles.outMap,
           inDomModel=inDomModelPath,
           inRecModel=inRecModelPath,
           inScriptsDir=inScriptsDirPath
    }
   } # end scatter


 

   ## 3rd LOOP
   ## Prepare files for Merlin MultiPoint Analysis and Run it
   scatter (chr in chromosomes){

     ## we add this 'if' statement because for chrY, the output of the task 'getSnpListWithGenDist', ie the file 'list_snp_chr${chr}_with_gendist.txt' is empty for AUDO data
     ## if it is also the case for some other chromosomes, instead of using this 'if' statement, remove problematic chromosomes from the array 'chromosomes' defined at the beginning of this workflow
     ## if (chr != "Y"){   
      call prepareMultiPointFiles {
        input: chrom=chr,
           outPrefix=outPrefixPath,
           outDir=outDirPath,
           outLog=outLogPath,
           inPedFiles=splitByChrom.outPed,
           inMapFiles=splitByChrom.outMap,
           inGeneticMapFiles=prepareGeneticMaps.outGenMap,
           inScriptsDir=inScriptsDirPath,
           THREADS=THREADS
      }
      call runMultiPointMerlin {
        input: chrom=chr,
           outPrefix=outPrefixPath,
           outDir=outDirPath,
           outLog=outLogPath,
           inLodTh=inLodThreshold,
           inDat=prepareMultiPointFiles.outDat,
           inPedFiles=splitByChrom.outPed,
           inMap=prepareMultiPointFiles.outMap,
           inDomModel=inDomModelPath,
           inRecModel=inRecModelPath,
           inScriptsDir=inScriptsDirPath
      }
   } # end scatter


 ## Merging output files of 2nd and 3rd 'scatter' loops
 call mergeLodScores {
        input: outDir=outDirPath,
           outLog=outLogPath,
           inSglDomLodScoreFiles=runSinglePointMerlin.outDomLodScoresWoHeader,  ## Array of files '${outDir}/results_singlepoint_chr${chrom}_${model}.woheader.txt'
           inSglRecLodScoreFiles=runSinglePointMerlin.outRecLodScoresWoHeader,  ## Array of files '${outDir}/results_singlepoint_chr${chrom}_${model}.woheader.txt'
           inMultiDomLodScoreFiles=runMultiPointMerlin.outDomLodScoresWoHeader,  ## Array of files '${outDir}/results_multipoint_chr${chrom}_${model}.woheader.txt'
           inMultiRecLodScoreFiles=runMultiPointMerlin.outRecLodScoresWoHeader  ## Array of files '${outDir}/results_multipoint_chr${chrom}_${model}.woheader.txt' 
 }


meta {
    author: "Elise Larsonneur"
    email: "elise.larsonneur@cea.fr"
 }


} # end workflow



##TASKS

## format and sort genetic maps
task prepareGeneticMaps {
   String chrom
   String inGeneticMapsDir
   String inScriptsDir
   String outDir
   String outLog

   command <<<
     bash -ce -o pipefail "
      mkdir -p ${outDir}/prepareGeneticMaps/${chrom}
      if [[ \"${chrom}\" != \"Y\" ]]; then
        ${inScriptsDir}/prepareGeneticMaps.sh \
          -g ${inGeneticMapsDir} \
          -o ${outDir}/prepareGeneticMaps/${chrom} \
          -c ${chrom}
      elif [[ \"${chrom}\" == \"Y\" ]]; then 
        touch ${outDir}/prepareGeneticMaps/${chrom}/genetic_map_GRCh37_chr${chrom}_wo_head.txt; 
      fi
     "
   >>>
 
   output {
      File outGenMap = "${outDir}/prepareGeneticMaps/${chrom}/genetic_map_GRCh37_chr${chrom}_wo_head.txt"
   }
}

## convert a gVCF file to tped and tfam files and check that input directories exist
## then convert tped and tfam files to ped and map files
task prepareVCF {

   Int THREADS
   Float inLodTh
   File inGVCF
   File inTFAM
   File inDomModel
   File inRecModel
   String outDir
   String outPrefix
   String inGeneticMapsDir
   String inScriptsDir
   String outLog

   command <<<
     bash -ce "
       if [[ ! -d $(dirname ${outLog}) ]]; then echo -e \"Directory of log file does not exist; Program exit\" 1>&2; exit 1; fi
       echo \"\" 1> ${outLog};
       if [[ ! -d ${inGeneticMapsDir} ]]; then echo -e \"Directory ${inGeneticMapsDir} does not exist. Program exit\" 1>&2; exit 1; fi
       if [[ ! -d ${inScriptsDir} ]]; then echo -e \"Directory ${inScriptsDir} does not exist. Program exit\" 1>&2; exit 1; fi
       if [[ ! -d ${outDir} ]]; then echo -e \"Directory ${outDir} does not exist. Program exit\" 1>&2; exit 1; fi
       # touch ${outDir}/checkInDirOk;
       if [[ ! -f ${inDomModel} ]]; then echo -e \"Dominant model file ${inDomModel} does not exist. Program exit\" 1>&2; exit 1; fi
       if [[ ! -f ${inRecModel} ]]; then echo -e \"Recessive model file ${inRecModel} does not exist. Program exit\" 1>&2; exit 1; fi
       if ! [[ ${inLodTh} =~ ^[0-9]+\.?[0-9]*$ ]] || [[ $(echo ${inLodTh} '<='0 | bc -l) -eq 1 ]]; then \
          echo -e 'The lod-score threshold must be greater than 0.' 1>&2; exit 1; fi;

       mkdir -p ${outDir}/prepareVCF
       ${inScriptsDir}/prepareVCF.sh \
         -i ${inGVCF} \
         -p ${inTFAM} \
         -o ${outDir}/prepareVCF \
         -s ${outPrefix}_vcftools_filled \
         -t ${THREADS} 
    "
   >>>
   output {
      #File checkInDirOk = "${outDir}/checkInDirOk"
      File ped = "${outDir}/prepareVCF/${outPrefix}_vcftools_filled.ped"
      File map = "${outDir}/prepareVCF/${outPrefix}_vcftools_filled.map"
   }
   runtime {
      # String ou Int ne marche pas pour ces differents cas commentes
      #cpu: "${THREADS}"
      #cpu: ${THREADS}
      #cpu: THREADS 
      #cpu: "" + THREADS
      cpu: 1
   }
}


## split ped and map files by chromosome
task splitByChrom {
   Int THREADS
   File inMap
   File inPed
   String chrom
   String outDir
   String outPrefix
   String outLog
   String inScriptsDir

   command <<<
     bash -ce '  
       mkdir -p ${outDir}/splitByChrom/${chrom}
       ${inScriptsDir}/splitByChrom.sh \
         -m ${inMap} \
         -p ${inPed} \
         -c ${chrom} \
         -o ${outDir}/splitByChrom/${chrom} \
         -s ${outPrefix}_vcftools_filled_chr \
         -t ${THREADS}
    '
   >>>
   output {
     File outPed = "${outDir}/splitByChrom/${chrom}/${outPrefix}_vcftools_filled_chr${chrom}.ped"
     File outMap = "${outDir}/splitByChrom/${chrom}/${outPrefix}_vcftools_filled_chr${chrom}.map"
   }
   runtime {
      cpu: 1
   }
}



## prepare files for merlin singlepoint analysis

## convert map file to dat file
## get map file as input of merlin single point analysis
task prepareSinglePointFiles {
   String chrom
   ## Array of files ${outPrefix}_vcftools_filled_chr${chrom}.map 
   Array[File] inMapFiles  
   String outDir
   String outPrefix
   String outLog
   String inScriptsDir
   
   command <<<
     bash -ce "
       mkdir -p ${outDir}/prepareSinglePointFiles/${chrom}
       ${inScriptsDir}/prepareSinglePointFiles.sh \
         -m ${outDir}/splitByChrom/${chrom}/${outPrefix}_vcftools_filled_chr${chrom}.map \
         -c ${chrom} \
         -o ${outDir}/prepareSinglePointFiles/${chrom} \
         -s ${outPrefix}_sgl_chr
     "
   >>>
   output {
     File outDat = "${outDir}/prepareSinglePointFiles/${chrom}/${outPrefix}_sgl_chr${chrom}.dat"
     File outMap = "${outDir}/prepareSinglePointFiles/${chrom}/${outPrefix}_sgl_chr${chrom}.map"
  }
}


## run single point merlin analysis
## and get significant lod scores from singlepoint merlin output file
task runSinglePointMerlin {
   String chrom
   Float inLodTh
   File inDomModel
   File inRecModel
   File inDat ## ${outPrefix}_sgl_chr${chrom}.dat
   Array[File] inPedFiles ## Array of files ${outPrefix}_vcftools_filled_chr${chrom}.ped
   File inMap ## ${outPrefix}_sgl_chr${chrom}.map
   String outDir
   String outPrefix
   String outLog
   String inScriptsDir

   command <<<
     bash -ce '
       echo "RUN SINGLEPOINT MERLIN ANALYSIS - CHROMOSOME ${chrom}" 1>> ${outLog}
       mkdir -p ${outDir}/runSinglePointMerlin/${chrom}
       ${inScriptsDir}/runSinglePointMerlin.sh \
          -D ${inDomModel} \
          -R ${inRecModel} \
          -m ${inMap} \
          -d ${inDat} \
          -p ${outDir}/splitByChrom/${chrom}/${outPrefix}_vcftools_filled_chr${chrom}.ped \
          -c ${chrom} \
          -o ${outDir}/runSinglePointMerlin/${chrom} \
          -s results_singlepoint_chr \
          -l ${inLodTh}
     '
   >>>
   output {
      File outDomLodScores = "${outDir}/runSinglePointMerlin/${chrom}/results_singlepoint_chr${chrom}_dominant.txt"
      File outRecLodScores = "${outDir}/runSinglePointMerlin/${chrom}/results_singlepoint_chr${chrom}_recessive.txt"
      File outDomSignificantLodScores = "${outDir}/runSinglePointMerlin/${chrom}/results_singlepoint_chr${chrom}_dominant_LODsignif.txt"
      File outRecSignificantLodScores = "${outDir}/runSinglePointMerlin/${chrom}/results_singlepoint_chr${chrom}_recessive_LODsignif.txt"
      File outDomLodScoresWoHeader = "${outDir}/runSinglePointMerlin/${chrom}/results_singlepoint_chr${chrom}_dominant.woheader.txt"
      File outRecLodScoresWoHeader = "${outDir}/runSinglePointMerlin/${chrom}/results_singlepoint_chr${chrom}_recessive.woheader.txt"
   }
}


## merge .txt files
task mergeLodScores {
   String outDir
   Array[File] inSglDomLodScoreFiles  ## Array of Files '${outDir}/results_chr${chrom}_${model}.woheader.txt'
   Array[File] inSglRecLodScoreFiles  ## Array of Files '${outDir}/results_chr${chrom}_${model}.woheader.txt'
   Array[File] inMultiDomLodScoreFiles  ## Array of Files '${outDir}/results_chr${chrom}_${model}.woheader.txt'
   Array[File] inMultiRecLodScoreFiles  ## Array of Files '${outDir}/results_chr${chrom}_${model}.woheader.txt'
   String outLog

   command <<<
     bash -ce "
       #fg_sar mark -l '--------------------------mergeResults'
       mkdir -p ${outDir}/mergeResults/
       cat ${sep=' ' inSglDomLodScoreFiles} > ${outDir}/mergeResults/results_singlepoint_merged_dominant.txt 
       cat ${sep=' ' inSglRecLodScoreFiles} > ${outDir}/mergeResults/results_singlepoint_merged_recessive.txt 
       cat ${sep=' ' inMultiDomLodScoreFiles} > ${outDir}/mergeResults/results_multipoint_merged_dominant.txt 
       cat ${sep=' ' inMultiRecLodScoreFiles} > ${outDir}/mergeResults/results_multipoint_merged_recessive.txt 
     "
   >>>
   output {
      File outMergedSglDomLodScoreFiles = "${outDir}/mergeResults/results_singlepoint_merged_dominant.txt"
      File outMergedSglRecLodScoreFiles = "${outDir}/mergeResults/results_singlepoint_merged_recessive.txt"
      File outMergedMultiDomLodScoreFiles = "${outDir}/mergeResults/results_multipoint_merged_dominant.txt"
      File outMergedMultiRecLodScoreFiles = "${outDir}/mergeResults/results_multipoint_merged_recessive.txt"
   }
}



## prepare files for merlin multipoint analysis
task prepareMultiPointFiles {
   Int THREADS
   String chrom
   Array[File] inPedFiles  ## ${outPrefix}_vcftools_filled_chr${chrom}.ped 
   Array[File] inMapFiles  ## ${outPrefix}_vcftools_filled_chr${chrom}.map
   Array [File] inGeneticMapFiles  ## Array of files "${outDir}/genetic_map_GRCh37_chr${chrom}_wo_head.txt"
   String outDir
   String outPrefix
   String outLog
   String inScriptsDir

   command <<<
     bash -ce '  
       mkdir -p ${outDir}/prepareMultiPointFiles/${chrom}
       if [[ ${chrom} != "Y" ]]; then 
         ${inScriptsDir}/prepareMultiPointFiles.sh \
           -m ${outDir}/splitByChrom/${chrom}/${outPrefix}_vcftools_filled_chr${chrom}.map \
           -p ${outDir}/splitByChrom/${chrom}/${outPrefix}_vcftools_filled_chr${chrom}.ped \
           -c ${chrom} \
           -g ${outDir}/prepareGeneticMaps/${chrom} \
           -o ${outDir}/prepareMultiPointFiles/${chrom} \
           -s ${outPrefix}_multi_chr \
           -t ${THREADS}
       elif [[ ${chrom} == "Y" ]]; then
         touch ${outDir}/prepareMultiPointFiles/${chrom}/${outPrefix}_multi_chr${chrom}.ped 
         touch ${outDir}/prepareMultiPointFiles/${chrom}/${outPrefix}_multi_chr${chrom}.map
         touch ${outDir}/prepareMultiPointFiles/${chrom}/${outPrefix}_multi_chr${chrom}.dat
       fi
     '
     ## plink/1.90.b
   >>>
   output {
      File outPed = "${outDir}/prepareMultiPointFiles/${chrom}/${outPrefix}_multi_chr${chrom}.ped"
      File outMap = "${outDir}/prepareMultiPointFiles/${chrom}/${outPrefix}_multi_chr${chrom}.map"
      File outDat = "${outDir}/prepareMultiPointFiles/${chrom}/${outPrefix}_multi_chr${chrom}.dat"
   }
   runtime {
      cpu: 1 
   }
}



## run multipoint merlin analysis
## and get significant lod scores from multipoint merlin output file
task runMultiPointMerlin {
   String chrom
   Float inLodTh
   File inDomModel
   File inRecModel
   File inDat ## ${outPrefix}_multi_chr${chrom}.dat
   Array[File] inPedFiles  ## ${outPrefix}_vcftools_filled_chr${chrom}.ped 
   File inMap ## ${outPrefix}_multi_chr${chrom}.map
   String outDir
   String outPrefix
   String outLog
   String inScriptsDir

   command <<<
     bash -ce '
       mkdir -p ${outDir}/runMultiPointMerlin/${chrom}
       if [[ ${chrom} != "Y" ]]; then
        echo "RUN MULTIPOINT MERLIN ANALYSIS - CHROMOSOME ${chrom}" 1>> ${outLog}
        ${inScriptsDir}/runMultiPointMerlin.sh \
          -D ${inDomModel} \
          -R ${inRecModel} \
          -m ${inMap} \
          -d ${inDat} \
          -p ${outDir}/prepareMultiPointFiles/${chrom}/${outPrefix}_multi_chr${chrom}.ped \
          -c ${chrom} \
          -o ${outDir}/runMultiPointMerlin/${chrom} \
          -s results_multipoint_chr \
          -l ${inLodTh}
       elif [[ ${chrom} == "Y" ]]; then
         echo "Ignoring merlin multipoint analysis of the chromosome ${chrom}." 1>> ${outLog};
         touch ${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_dominant.txt
         touch ${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_recessive.txt
         touch ${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_dominant_LODsignif.txt
         touch ${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_recessive_LODsignif.txt
         touch ${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_dominant.woheader.txt
         touch ${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_recessive.woheader.txt
       fi
     '
   >>>
   output {
      File outDomLodScores = "${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_dominant.txt"
      File outRecLodScores = "${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_recessive.txt"
      File outDomSignificantLodScores = "${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_dominant_LODsignif.txt"
      File outRecSignificantLodScores = "${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_recessive_LODsignif.txt"
      File outDomLodScoresWoHeader = "${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_dominant.woheader.txt"
      File outRecLodScoresWoHeader = "${outDir}/runMultiPointMerlin/${chrom}/results_multipoint_chr${chrom}_recessive.woheader.txt"
   }
}

