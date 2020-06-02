#!/usr/bin/env cwl-runner

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Author: Elise LARSONNEUR (elise.larsonneur@cea.fr)                           #
################################################################################

cwlVersion: v1.0
class: CommandLineTool

label: runMultiPointMerlin 
doc: |
     runMultiPointMerlin
        run multi point merlin analysis  

requirements:
  ResourceRequirement:
    coresMax: 1
  InlineJavascriptRequirement: {}
  ShellCommandRequirement: {}  # add prefix '/bin/sh -c' at the beginning of the commandline

baseCommand: [] # runMultiPointMerlin.sh

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

#runMultiPointMerlin.sh successful if (chr != Y) #because there is no genetic map for the Y chromosome
arguments:
 - mkdir 
 - -p
 - runMultiPointMerlin
 - $('runMultiPointMerlin/' + inputs.chromosome)
 - '&&'
 - ~/WMS-benchmark/LodSeq/scripts/runMultiPointMerlin.sh
 - -o
 - $('runMultiPointMerlin/' + inputs.chromosome)
 - -s
 - results_multipoint_chr 

outputs:
  out_dom_txt:
    type: File
    outputBinding: { glob: runMultiPointMerlin/$(inputs.chromosome)/results_multipoint_chr$(inputs.chromosome)_dominant.txt }
  out_rec_txt:
    type: File
    outputBinding: { glob: runMultiPointMerlin/$(inputs.chromosome)/results_multipoint_chr$(inputs.chromosome)_recessive.txt }
  out_dom_signif_txt:
    type: File
    outputBinding: { glob: runMultiPointMerlin/$(inputs.chromosome)/results_multipoint_chr$(inputs.chromosome)_dominant_LODsignif.txt }
  out_rec_signif_txt:
    type: File
    outputBinding: { glob: runMultiPointMerlin/$(inputs.chromosome)/results_multipoint_chr$(inputs.chromosome)_recessive_LODsignif.txt }
  out_dom_woheader_txt:
    type: File
    outputBinding: { glob: runMultiPointMerlin/$(inputs.chromosome)/results_multipoint_chr$(inputs.chromosome)_dominant.woheader.txt }
  out_rec_woheader_txt:
    type: File
    outputBinding: { glob: runMultiPointMerlin/$(inputs.chromosome)/results_multipoint_chr$(inputs.chromosome)_recessive.woheader.txt }
  out_dir_rmm:
    type: Directory
    outputBinding: { glob: runMultiPointMerlin }

stdout: runMultiPointMerlin/$(inputs.chromosome)/runMultiPointMerlin.o
stderr: runMultiPointMerlin/$(inputs.chromosome)/runMultiPointMerlin.e


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

