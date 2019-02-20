#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

label: prepareSinglePointFiles 
doc: |
     prepareSinglePointFiles
        prepare single point merlin analysis inputs  

requirements:
  ResourceRequirement:
    coresMax: 1
  InlineJavascriptRequirement: {}
  ShellCommandRequirement: {}  # add prefix '/bin/sh -c' at the beginning of the commandline

baseCommand: [] # prepareSinglePointFiles.sh

inputs:
  chr_map: 
    type: File
    inputBinding:
      prefix: -m
  out_prefix: 
    type: string
  chromosome: 
    type: string
    inputBinding:
      prefix: -c

arguments:
 - mkdir 
 - -p
 - prepareSinglePointFiles
 - $('prepareSinglePointFiles/' + inputs.chromosome)
 - '&&'
 - ~/WMS-benchmark/LodSeq/scripts/prepareSinglePointFiles.sh
 - -o
 - $('prepareSinglePointFiles/' + inputs.chromosome)
 - -s
 - $(inputs.out_prefix + '_sgl_chr')

outputs:
  out_chr_dat:
    type: File
    outputBinding: { glob: prepareSinglePointFiles/$(inputs.chromosome)/$(inputs.out_prefix)_sgl_chr$(inputs.chromosome).dat }
  out_chr_map:
    type: File
    outputBinding: { glob: prepareSinglePointFiles/$(inputs.chromosome)/$(inputs.out_prefix)_sgl_chr$(inputs.chromosome).map }
  out_dir_psf:
    type: Directory
    outputBinding: { glob: prepareSinglePointFiles }

stdout: prepareSinglePointFiles/$(inputs.chromosome)/prepareSinglePointFiles.o
stderr: prepareSinglePointFiles/$(inputs.chromosome)/prepareSinglePointFiles.e

