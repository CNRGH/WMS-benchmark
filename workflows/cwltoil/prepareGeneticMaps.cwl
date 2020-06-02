#!/usr/bin/env cwl-runner

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Author: Elise LARSONNEUR (elise.larsonneur@cea.fr)                           #
################################################################################

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


$namespaces:
  s: https://schema.org/

$schemas:
 - https://schema.org/version/latest/schema.rdf

s:author:
  - class: s:Person
    s:identifier: https://orcid.org/0000-0002-0929-8603
    s:email: mailto:elise.larsonneur@cea.fr
    s:name: Elise Larsonneur

s:citation: https://dx.doi.org/10.1109/BIBM.2018.8621141
s:codeRepository: https://github.com/CNRGH/WMS-benchmark
s:license: https://spdx.org/licenses/CECILL-2.1

