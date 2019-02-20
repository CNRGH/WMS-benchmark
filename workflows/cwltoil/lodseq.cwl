#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

label: LodSeq 
doc: |
     LodSeq performs the genetic linkage analysis across families, by computing
     lod-scores given a gvcf file and a related tfam pedigree file.

requirements:
  SubworkflowFeatureRequirement: {}
  ScatterFeatureRequirement: {}
  StepInputExpressionRequirement: {}

inputs:
  vcf:
    type: File
  tfam:
    type: File
  dom_model:
    type: File
  rec_model:
    type: File
  genetic_maps:
    type: Directory
  lod_threshold:
    type: float
  out_prefix:
    type: string
  chromosomes:
    type: {type: array, items: string}

#outputs that will be kept into the workdir/outdir directory
outputs:
  out_dir:
    type: Directory
    outputSource: prepareVCF/out_dir
  out_dir_pgm:
    type: Directory[]
    outputSource: prepareGeneticMaps/out_dir_pgm
  out_dir_sbc:
    type: Directory[]
    outputSource: splitByChrom/out_dir_sbc
  out_dir_psf:
    type: Directory[]
    outputSource: prepareSinglePointFiles/out_dir_psf
  out_dir_rsm:
    type: Directory[]
    outputSource: runSinglePointMerlin/out_dir_rsm
  out_dir_rmm:
    type: Directory[]
    outputSource: runMultiPointMerlin/out_dir_rmm
  out_dir_pmf:
    type: Directory[]
    outputSource: prepareMultiPointFiles/out_dir_pmf
  out_dir_mr:
    type: Directory
    outputSource: mergeResults/out_dir_m

steps:
  prepareVCF:
    run: prepareVCF.cwl
    requirements:
      ResourceRequirement:
        coresMin: 1
        coresMax: 12
    in:
       vcf: vcf
       tfam: tfam
       out_prefix: out_prefix 
    out:
       - out_map
       - out_ped
       - out_dir

  prepareGeneticMaps:
    run: prepareGeneticMaps.cwl
    in:
      genetic_maps: genetic_maps
      chromosome: chromosomes
    scatter: chromosome
    out:
      - out_genmap
      - out_dir_pgm

  splitByChrom:
    run: splitByChrom.cwl
    in:
      map: prepareVCF/out_map
      ped: prepareVCF/out_ped
      chromosome: chromosomes
      out_prefix: out_prefix 
    scatter: chromosome
    out:
      - out_chr_map
      - out_chr_ped
      - out_dir_sbc

  prepareSinglePointFiles:
    run: prepareSinglePointFiles.cwl
    in:
      chr_map: splitByChrom/out_chr_map
      chromosome: chromosomes
      out_prefix: out_prefix 
    scatter: 
      - chromosome
      - chr_map
    scatterMethod: dotproduct
    out:
      - out_chr_dat
      - out_chr_map
      - out_dir_psf


  runSinglePointMerlin:
    run: runSinglePointMerlin.cwl
    in:
      dom_model: dom_model 
      rec_model: rec_model
      lod_threshold: lod_threshold
      chr_dat: prepareSinglePointFiles/out_chr_dat
      chr_map: prepareSinglePointFiles/out_chr_map
      chr_ped: splitByChrom/out_chr_ped
      chromosome: chromosomes
    scatter: 
      - chromosome
      - chr_dat
      - chr_map
      - chr_ped
    scatterMethod: dotproduct
    out:
      - out_dom_txt 
      - out_rec_txt
      - out_dom_signif_txt
      - out_rec_signif_txt 
      - out_dom_woheader_txt
      - out_rec_woheader_txt
      - out_dir_rsm

  prepareMultiPointFiles:
    run: prepareMultiPointFiles.cwl
    in:
      chr_map: splitByChrom/out_chr_map
      chr_ped: splitByChrom/out_chr_ped
      chr_genmap: prepareGeneticMaps/out_genmap
      chromosome: chromosomes
      out_prefix: out_prefix
    scatter:
      - chr_map
      - chr_ped
      - chr_genmap
      - chromosome
    scatterMethod: dotproduct
    out:
      - out_chr_dat
      - out_chr_map
      - out_chr_ped
      - out_dir_pmf

  runMultiPointMerlin:
    run: runMultiPointMerlin.cwl
    in:
      dom_model: dom_model 
      rec_model: rec_model
      lod_threshold: lod_threshold
      chr_dat: prepareMultiPointFiles/out_chr_dat
      chr_map: prepareMultiPointFiles/out_chr_map
      chr_ped: prepareMultiPointFiles/out_chr_ped
      chromosome: chromosomes
    scatter: 
      - chromosome
      - chr_dat
      - chr_map
      - chr_ped
    scatterMethod: dotproduct
    out:
      - out_dom_txt 
      - out_rec_txt
      - out_dom_signif_txt
      - out_rec_signif_txt 
      - out_dom_woheader_txt
      - out_rec_woheader_txt
      - out_dir_rmm

  mergeResults:
    run: merge.cwl
    in:
      files_sgl_dom: runSinglePointMerlin/out_dom_woheader_txt
      files_sgl_rec: runSinglePointMerlin/out_rec_woheader_txt
      files_multi_dom: runMultiPointMerlin/out_dom_woheader_txt
      files_multi_rec: runMultiPointMerlin/out_rec_woheader_txt
    out: 
      - out_merged_sgl_dom_txt
      - out_merged_sgl_rec_txt
      - out_merged_multi_dom_txt
      - out_merged_multi_rec_txt
      - out_dir_m

