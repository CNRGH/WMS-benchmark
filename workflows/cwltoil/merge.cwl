#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

requirements:
  InlineJavascriptRequirement: {}  # to propagate the file format
  ShellCommandRequirement: {}  # add prefix '/bin/sh -c' at the beginning of the commandline
  ResourceRequirement:
    coresMax: 1

baseCommand: [] # cat 

inputs:
  files_sgl_dom:
    type: File[]
    streamable: true
  files_sgl_rec:
    type: File[]
    streamable: true
  files_multi_dom:
    type: File[]
    streamable: true
  files_multi_rec:
    type: File[]
    streamable: true

arguments:
  #- fg_sar 
  #- mark 
  #- -l 
  #- '--------------------------mergeResults'
  #- '&&'
  - mkdir
  - -p
  - mergeResults
  - '&&'
  - cat
  - $(inputs.files_sgl_dom)
  - '>'
  - mergeResults/results_singlepoint_merged_dominant.txt
  - '&&'
  - cat
  - $(inputs.files_sgl_rec)
  - '>'
  - mergeResults/results_singlepoint_merged_recessive.txt
  - '&&'
  - cat 
  - $(inputs.files_multi_dom)
  - '>'
  - mergeResults/results_multipoint_merged_dominant.txt
  - '&&'
  - cat 
  - $(inputs.files_multi_rec)
  - '>'
  - mergeResults/results_multipoint_merged_recessive.txt 

outputs:
  out_merged_sgl_dom_txt:
    type: File
    outputBinding: { glob: mergeResults/results_singlepoint_merged_dominant.txt }
  out_merged_sgl_rec_txt:
    type: File
    outputBinding: { glob: mergeResults/results_singlepoint_merged_recessive.txt }
  out_merged_multi_dom_txt:
    type: File
    outputBinding: { glob: mergeResults/results_multipoint_merged_dominant.txt }
  out_merged_multi_rec_txt:
    type: File
    outputBinding: { glob: mergeResults/results_multipoint_merged_recessive.txt }
  out_dir_m:
    type: Directory
    outputBinding: { glob: mergeResults }

stdout: mergeResults/mergeResults.o
stderr: mergeResults/mergeResults.e

