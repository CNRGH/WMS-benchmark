#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

label: prepareVCF 
doc: |
     prepareVCF
        get .ped and .map files from .vcf and .tfam files
        and check that all input files and directories exist

requirements:
  ResourceRequirement:
    coresMax: 1
  InlineJavascriptRequirement: {}
  ShellCommandRequirement: {}  # add prefix '/bin/sh -c' at the beginning of the commandline

baseCommand: [] # prepareVCF.sh

inputs:
  vcf: 
    type: File
    inputBinding:
      prefix: -i
  tfam: 
    type: File
    inputBinding:
      prefix: -p
  out_prefix: 
    type: string

arguments:
 - mkdir
 - -p 
 - prepareVCF
 - '&&'
 - ~/WMS-benchmark/LodSeq/scripts/prepareVCF.sh
 - -o
 - prepareVCF
 - -s
 - $(inputs.out_prefix)_vcftools_filled
 - -t
 - $(runtime.cores)

outputs:
  out_map:
    type: File
    outputBinding: { glob: prepareVCF/$(inputs.out_prefix)_vcftools_filled.map }
  out_ped:
    type: File
    outputBinding: { glob: prepareVCF/$(inputs.out_prefix)_vcftools_filled.ped }
  out_dir:
    type: Directory
    outputBinding: { glob: prepareVCF }

stdout: prepareVCF/prepareVCF.o
stderr: prepareVCF/prepareVCF.e

