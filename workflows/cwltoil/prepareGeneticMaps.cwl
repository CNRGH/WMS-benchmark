#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

label: prepareGeneticMaps 
doc: |
     prepareGeneticMaps
        removes header from genetic map file(s) 

requirements:
  ResourceRequirement:
    coresMax: 1
  InlineJavascriptRequirement: {}
  ShellCommandRequirement: {}  # add prefix '/bin/sh -c' at the beginning of the commandline

baseCommand: [] # prepareGeneticMaps.sh

inputs:
  genetic_maps: 
    type: Directory
    inputBinding:
      prefix: -g
  chromosome: 
    type: string
    inputBinding:
      prefix: -c

arguments:
 - mkdir
 - -p 
 - prepareGeneticMaps
 - prepareGeneticMaps/$(inputs.chromosome)
 - '&&'
 - ~/WMS-benchmark/LodSeq/scripts/prepareGeneticMaps.sh
 - -o
 - prepareGeneticMaps/$(inputs.chromosome)

outputs:
  out_genmap:
    type: File
    outputBinding: { glob: prepareGeneticMaps/$(inputs.chromosome)/genetic_map_GRCh37_chr$(inputs.chromosome)_wo_head.txt }
  out_dir_pgm:
    type: Directory
    #outputBinding: { glob: prepareGeneticMaps/$(inputs.chromosome) } # only the last directory (ie inputs.chromosome) is conserved, ie the tree view is not conserved (prepareGeneticMaps not kept)
    #outputBinding: { glob: prepareGeneticMaps/ } # do not keep the character '/' !!!
    outputBinding: { glob: prepareGeneticMaps }

stdout: prepareGeneticMaps/$(inputs.chromosome)/prepareGeneticMaps.o
stderr: prepareGeneticMaps/$(inputs.chromosome)/prepareGeneticMaps.e

