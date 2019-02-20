#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

label: runSinglePointMerlin 
doc: |
     runSinglePointMerlin
        run single point merlin analysis  

requirements:
  ResourceRequirement:
    coresMax: 1
  InlineJavascriptRequirement: {}
  ShellCommandRequirement: {}  # add prefix '/bin/sh -c' at the beginning of the commandline

baseCommand: [] # runSinglePointMerlin.sh

inputs:
  dom_model:
    type: File
    inputBinding:
      prefix: -D
  rec_model:
    type: File
    inputBinding:
      prefix: -R
  lod_threshold:
    type: float
    inputBinding:
      prefix: -l
  chr_dat: 
    type: File
    inputBinding:
      prefix: -d
  chr_map: 
    type: File
    inputBinding:
      prefix: -m
  chr_ped: 
    type: File
    inputBinding:
      prefix: -p
  chromosome: 
    type: string
    inputBinding:
      prefix: -c

arguments:
 - mkdir
 - -p 
 - runSinglePointMerlin
 - $('runSinglePointMerlin/' + inputs.chromosome)
 - '&&'
 - ~/WMS-benchmark/LodSeq/scripts/runSinglePointMerlin.sh
 - -o
 - $('runSinglePointMerlin/' + inputs.chromosome)
 - -s
 - results_singlepoint_chr 

outputs:
  out_dom_txt:
    type: File
    outputBinding: { glob: runSinglePointMerlin/$(inputs.chromosome)/results_singlepoint_chr$(inputs.chromosome)_dominant.txt }
  out_rec_txt:
    type: File
    outputBinding: { glob: runSinglePointMerlin/$(inputs.chromosome)/results_singlepoint_chr$(inputs.chromosome)_recessive.txt }
  out_dom_signif_txt:
    type: File
    outputBinding: { glob: runSinglePointMerlin/$(inputs.chromosome)/results_singlepoint_chr$(inputs.chromosome)_dominant_LODsignif.txt }
  out_rec_signif_txt:
    type: File
    outputBinding: { glob: runSinglePointMerlin/$(inputs.chromosome)/results_singlepoint_chr$(inputs.chromosome)_recessive_LODsignif.txt }
  out_dom_woheader_txt:
    type: File
    outputBinding: { glob: runSinglePointMerlin/$(inputs.chromosome)/results_singlepoint_chr$(inputs.chromosome)_dominant.woheader.txt }
  out_rec_woheader_txt:
    type: File
    outputBinding: { glob: runSinglePointMerlin/$(inputs.chromosome)/results_singlepoint_chr$(inputs.chromosome)_recessive.woheader.txt }
  out_dir_rsm:
    type: Directory
    outputBinding: { glob: runSinglePointMerlin }

stdout: runSinglePointMerlin/$(inputs.chromosome)/runSinglePointMerlin.o
stderr: runSinglePointMerlin/$(inputs.chromosome)/runSinglePointMerlin.e

