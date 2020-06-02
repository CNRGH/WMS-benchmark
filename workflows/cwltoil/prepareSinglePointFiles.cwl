#!/usr/bin/env cwl-runner

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Author: Elise LARSONNEUR (elise.larsonneur@cea.fr)                           #
################################################################################

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

