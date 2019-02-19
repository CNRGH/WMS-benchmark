#!/usr/bin/env nextflow

/* 
 * LODSEQ WORKFLOW 
 */

/* 
 * DEFAULT PARAMETER VALUES
 */

params.vcf = "$baseDir/data/inputs/chr7_mdf.vcf.gz"
params.tfam = "$baseDir/data/inputs/pedigree_mdf.tfam"
params.dom_model = "$baseDir/data/inputs/parametric_dominant.model"
params.rec_model = "$baseDir/data/inputs/parametric_recessive.model"
params.genetic_maps = "$baseDir/data/inputs/genetic_map_HapMapII_GRCh37/"
params.out_dir = "$baseDir/output"
params.out_prefix = 'CEPH1463'
params.lod_threshold = 1.3

/* /!\ WARNING - Declare numbers as int and not as string
 * to obtain the expected sorting order, ie:
 * params.chromosomes = [1, 10, 'Y', 2,  'X'] => toSortedList() => OK - GOOD SORTING : [1, 2, 10, 'X', 'Y']
 * params.chromosomes = ['1', '10', 'Y', '2',  'X'] => toSortedList() => NOT OK - BAD SORTING : [1, 10, 2, 'X', 'Y']
 */
params.chromosomes = [7] 

vcf = file(params.vcf)
tfam = file(params.tfam)
out_dir = file(params.out_dir)
out_prefix = params.out_prefix
genetic_maps = file(params.genetic_maps)
chromosomes = params.chromosomes
dom_model = file(params.dom_model)
rec_model = file(params.rec_model)
lod_threshold = params.lod_threshold



/*
 * Get .ped and .map files from .vcf and .tfam files
 */
process prepareVCF {

  cpus 1

  publishDir "${out_dir}/prepareVCF", mode: 'copy', 
        saveAs: {filename ->
              if(filename.indexOf('.command.sh') > -1 ) "mergeResults.sh"
              else if(filename.indexOf('.command.out') > -1) "mergeResults.out"
              else if(filename.indexOf('.command.err') > -1) "mergeResults.err"
              else filename
        }

  input:
  file vcf
  file tfam

  output:
  file "*.ped" into ped
  file "*.map" into map
  file '.command.sh'
  file '.command.out'
  file '.command.err'

  """
  $baseDir/scripts/prepareVCF.sh \
    -i $vcf \
    -p $tfam \
    -o . \
    -s ${out_prefix}_vcftools_filled \
    -t ${task.cpus}
  """

}



/*
 * Prepare genetic maps (remove header lines)
 */
process prepareGeneticMaps {
  
  publishDir "${out_dir}/prepareGeneticMaps/${chr}", mode: 'copy', 
        saveAs: {filename ->
              if(filename.indexOf('.command.sh') > -1 ) "mergeResults.sh"
              else if(filename.indexOf('.command.out') > -1) "mergeResults.out"
              else if(filename.indexOf('.command.err') > -1) "mergeResults.err"
              else filename
        }
  
  tag { "chr: $chr" }

  input:
  file genetic_maps
  each chr from chromosomes
  /* val chr from chromosomes - same behaviour as 'each' input type */

  output:
  set val(chr), file("genetic_map_GRCh37_chr${chr}_wo_head.txt") into gen_map
  file '.command.sh'
  file '.command.out'
  file '.command.err'
     
  """
  #because there is no genetic map for the Y chromosome
  if [[ "$chr" != "Y" ]]; then
    $baseDir/scripts/prepareGeneticMaps.sh \
      -g $genetic_maps \
      -o . \
      -c $chr
  elif [[ "$chr" == "Y" ]]; then
    touch "genetic_map_GRCh37_chr${chr}_wo_head.txt"
  fi
  """
                       
}



/*
 * Split files (.ped .map) by chromosome
 */
process splitByChrom {

  cpus 1

  publishDir "${out_dir}/splitByChrom/${chr}", mode: 'copy', 
        saveAs: {filename ->
              if(filename.indexOf('.command.sh') > -1 ) "mergeResults.sh"
              else if(filename.indexOf('.command.out') > -1) "mergeResults.out"
              else if(filename.indexOf('.command.err') > -1) "mergeResults.err"
              else filename
        }

  tag { "chr: $chr" }

  input:
  file in_map from map
  file in_ped from ped
  each chr from chromosomes
  /* val chr from chromosomes - same behaviour as 'each' input type */

  output:
  set val(chr), file("${out_prefix}_vcftools_filled_chr${chr}.map") into split_chr_map
  set val(chr), file("${out_prefix}_vcftools_filled_chr${chr}.ped") into split_chr_ped
  file '.command.sh'
  file '.command.out'
  file '.command.err'

  """
  $baseDir/scripts/splitByChrom.sh \
    -m $in_map \
    -p $in_ped \
    -c $chr \
    -o . \
    -s ${out_prefix}_vcftools_filled_chr \
    -t ${task.cpus}
  """

}




/*
 * duplicate channels because one channel can be consumed only once
 */
split_chr_map.into{
  split_chr_map_sgl
  split_chr_map_multi
}


/*
 * duplicate channels because one channel can be consumed only once
 */
split_chr_ped.into{
  split_chr_ped_sgl
  split_chr_ped_multi
}



/*
 * Prepare single point merlin analysis inputs
 */
process prepareSinglePointFiles {

  publishDir "${out_dir}/prepareSinglePointFiles/${chr}", mode: 'copy', 
        saveAs: {filename ->
              if(filename.indexOf('.command.sh') > -1 ) "mergeResults.sh"
              else if(filename.indexOf('.command.out') > -1) "mergeResults.out"
              else if(filename.indexOf('.command.err') > -1) "mergeResults.err"
              else filename
        }

  tag { "chr: $chr" }

  input:
  set val(chr), file(in_chr_map) from split_chr_map_sgl

  output:
  set val(chr), file("${out_prefix}_sgl_chr${chr}.dat"), file("${out_prefix}_sgl_chr${chr}.map") into sgl_chr_dat_map
  file '.command.sh'
  file '.command.out'
  file '.command.err'

  """
  $baseDir/scripts/prepareSinglePointFiles.sh \
    -m $in_chr_map \
    -c $chr \
    -o . \
    -s ${out_prefix}_sgl_chr
  """

}


/*
 * The join operator creates a channel that joins together the items emitted by
 * two channels for which exits a matching key. The key is defined, by default, 
 * as the first element in each item emitted. 
 */
sgl_chr_dat_map
  .join(split_chr_ped_sgl)
  .set { sgl_chr_dat_map_ped  }

split_chr_map_multi
  .join(split_chr_ped_multi)
  .join(gen_map)
  .set { multi_chr_map_ped_genmap  }



/*
 * Prepare multipoint merlin analysis inputs
 */
process prepareMultiPointFiles {

  publishDir "${out_dir}/prepareMultiPointFiles/${chr}", mode: 'copy', 
        saveAs: {filename ->
              if(filename.indexOf('.command.sh') > -1 ) "mergeResults.sh"
              else if(filename.indexOf('.command.out') > -1) "mergeResults.out"
              else if(filename.indexOf('.command.err') > -1) "mergeResults.err"
              else filename
        }

  tag { "chr: $chr" }

  input:
  set val(chr), file(in_chr_map), file(in_chr_ped), file(in_gen_map) from multi_chr_map_ped_genmap

  output:
  set val(chr), file("${out_prefix}_multi_chr${chr}.dat"), file("${out_prefix}_multi_chr${chr}.map"), file("${out_prefix}_multi_chr${chr}.ped") into multi_chr_dat_map_ped
  file '.command.sh'
  file '.command.out'
  file '.command.err'

  """
  #because there is no genetic map for the Y chromosome
  if [[ "$chr" != "Y" ]]; then
    $baseDir/scripts/prepareMultiPointFiles.sh \
      -m $in_chr_map \
      -p $in_chr_ped \
      -g . \
      -c $chr \
      -o . \
      -s ${out_prefix}_multi_chr
  elif [[ "$chr" == "Y" ]]; then
    touch "${out_prefix}_multi_chr${chr}.dat"
    touch "${out_prefix}_multi_chr${chr}.map"
    touch "${out_prefix}_multi_chr${chr}.ped"
  fi
  """

}



/*
 * Run singlepoint merlin analysis
 */
process runSinglePointMerlin {

  publishDir "${out_dir}/runSinglePointMerlin/${chr}", mode: 'copy', 
        saveAs: {filename ->
              if(filename.indexOf('.command.sh') > -1 ) "mergeResults.sh"
              else if(filename.indexOf('.command.out') > -1) "mergeResults.out"
              else if(filename.indexOf('.command.err') > -1) "mergeResults.err"
              else filename
        }
  
  tag { "chr: $chr" }

  input:
  file dom_model from dom_model
  file rec_model from rec_model
  set val(chr), file(in_chr_dat), file(in_chr_map), file(in_chr_ped) from sgl_chr_dat_map_ped

  output:
  file "results_singlepoint_chr${chr}_dominant.txt" into sgl_dom_txt
  file "results_singlepoint_chr${chr}_recessive.txt" into sgl_rec_txt
  file "results_singlepoint_chr${chr}_dominant_LODsignif.txt" into sgl_dom_signif_txt
  file "results_singlepoint_chr${chr}_recessive_LODsignif.txt" into sgl_rec_signif_txt
  set val(chr), file("results_singlepoint_chr${chr}_dominant.woheader.txt") into sgl_dom_woheader_txt
  set val(chr), file("results_singlepoint_chr${chr}_recessive.woheader.txt") into sgl_rec_woheader_txt
  file '.command.sh'
  file '.command.out'
  file '.command.err'

  """
  $baseDir/scripts/runSinglePointMerlin.sh \
          -D $dom_model \
          -R $rec_model \
          -m $in_chr_map \
          -d $in_chr_dat \
          -p $in_chr_ped \
          -c $chr \
          -o . \
          -s results_singlepoint_chr \
          -l $lod_threshold
  """

}



/*
 * Run multipoint merlin analysis
 */
process runMultiPointMerlin {

  publishDir "${out_dir}/runMultiPointMerlin/${chr}", mode: 'copy', 
        saveAs: {filename ->
              if(filename.indexOf('.command.sh') > -1 ) "mergeResults.sh"
              else if(filename.indexOf('.command.out') > -1) "mergeResults.out"
              else if(filename.indexOf('.command.err') > -1) "mergeResults.err"
              else filename
        }

  tag { "chr: $chr" }

  input:
  file dom_model from dom_model
  file rec_model from rec_model
  set val(chr), file(in_chr_dat), file(in_chr_map), file(in_chr_ped) from multi_chr_dat_map_ped

  output:
  file "results_multipoint_chr${chr}_dominant.txt" into multi_dom_txt
  file "results_multipoint_chr${chr}_recessive.txt" into multi_rec_txt
  file "results_multipoint_chr${chr}_dominant_LODsignif.txt" into multi_dom_signif_txt
  file "results_multipoint_chr${chr}_recessive_LODsignif.txt" into multi_rec_signif_txt
  set val(chr), file("results_multipoint_chr${chr}_dominant.woheader.txt") into multi_dom_woheader_txt
  set val(chr), file("results_multipoint_chr${chr}_recessive.woheader.txt") into multi_rec_woheader_txt
  file '.command.sh'
  file '.command.out'
  file '.command.err'

  """
  #because there is no genetic map for the Y chromosome
  if [[ "$chr" != "Y" ]]; then
    $baseDir/scripts/runMultiPointMerlin.sh \
      -D $dom_model \
      -R $rec_model \
      -m $in_chr_map \
      -d $in_chr_dat \
      -p $in_chr_ped \
      -c $chr \
      -o . \
      -s results_multipoint_chr \
      -l $lod_threshold
  elif [[ "$chr" == "Y" ]]; then
    touch "results_multipoint_chr${chr}_dominant.txt"
    touch "results_multipoint_chr${chr}_recessive.txt"
    touch "results_multipoint_chr${chr}_dominant_LODsignif.txt"
    touch "results_multipoint_chr${chr}_recessive_LODsignif.txt"
    touch "results_multipoint_chr${chr}_dominant.woheader.txt"
    touch "results_multipoint_chr${chr}_recessive.woheader.txt"
  fi
  """

}



/*
 * Sort each list of files by chromosome id
 * - example:
 *       Channel
 *           .from([10, 'chr10.txt'], [1, 'chr1.txt'], [2, 'chr2.txt'], ['Y', 'chrY.txt'], ['X', 'chrX.txt'])
 *           .toSortedList { entry -> entry[0] }
 *           .map { allPairs -> allPairs.collect{ chr, file -> file } }
 *           .view()
 *  displays: 
 *       [chr1.txt, chr2.txt, chr10.txt, chrX.txt, chrY.txt] 
 */
sgl_dom_woheader_txt
    .toSortedList { entry -> entry[0] }
    .map { allPairs -> allPairs.collect{ chr, file -> file } }
    .set { sorted_sgl_dom_txt } 

sgl_rec_woheader_txt
    .toSortedList { entry -> entry[0] }
    .map { allPairs -> allPairs.collect{ chr, file -> file } }
    .set { sorted_sgl_rec_txt } 

multi_dom_woheader_txt
    .toSortedList { entry -> entry[0] }
    .map { allPairs -> allPairs.collect{ chr, file -> file } }
    .set { sorted_multi_dom_txt } 

multi_rec_woheader_txt
    .toSortedList { entry -> entry[0] }
    .map { allPairs -> allPairs.collect{ chr, file -> file } }
    .set { sorted_multi_rec_txt } 



/*
 * Merge files
 * from a list of files sorted by chromosome name
 */
process mergeResults {
    publishDir "${out_dir}/mergeResults", mode: 'copy', 
        saveAs: {filename ->
              if(filename.indexOf('.command.sh') > -1 ) "mergeResults.sh"
              else if(filename.indexOf('.command.out') > -1) "mergeResults.out"
              else if(filename.indexOf('.command.err') > -1) "mergeResults.err"
              else filename
        }

    input:
    file sgl_dom from sorted_sgl_dom_txt
    file sgl_rec from sorted_sgl_rec_txt
    file multi_dom from sorted_multi_dom_txt
    file multi_rec from sorted_multi_rec_txt

    output:
    file 'results_singlepoint_merged_dominant.txt'
    file 'results_singlepoint_merged_recessive.txt'
    file 'results_multipoint_merged_dominant.txt'
    file 'results_multipoint_merged_recessive.txt'
    file '.command.sh'
    file '.command.out'
    file '.command.err'
    file '.command.log'
    file '.command.run'
    file '.command.begin'

    """
    #fg_sar mark -l "--------------------------mergeResults"
    cat $sgl_dom > results_singlepoint_merged_dominant.txt
    cat $sgl_rec > results_singlepoint_merged_recessive.txt
    cat $multi_dom > results_multipoint_merged_dominant.txt
    cat $multi_rec > results_multipoint_merged_recessive.txt
    """
}

workflow.onComplete { 
	println ( workflow.success ? "Success!" : "Oops .. workflow failed" )
}

