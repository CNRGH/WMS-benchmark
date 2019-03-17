#!/usr/bin/env bash

################################################################################
# Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine) #
#                    <www.cnrgh.fr>                                            #
# Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                          #
################################################################################

# Description: resize fg_sar png plot.
# Requires: files *.plot and *.tsv

#example: change line:
#set terminal pngcairo size 840, 400 enhanced truecolor font "LiberationSans,10" fontscale 1.0
#by:
#set terminal pngcairo size 1920, 700 enhanced truecolor font "LiberationSans,10" fontscale 1.0
#in *.plot
#then 
# run gnuplot <.plot>

set -eo pipefail

which gnuplot || module load gnuplot
WIDTH=1920;
H=700;
NCPU=12; #number of allocated cores
for f in *.plot; do 
  prefix=$(basename $f .plot);
  #change resolution (840, 400) or (1024, 400) by (1920, 700)
  CUR_W="$(grep 'pngcairo' $f |cut -d ' ' -f 5 | cut -d ',' -f 1)"
  CUR_H="$(grep 'pngcairo' $f |cut -d ' ' -f 6)"
  sed -i "s/${CUR_W}/${WIDTH}/g" $f;
  sed -i "s/${CUR_H}/${H}/g" $f;
  gnuplot $f;
  XMAX="$(grep xrange $f |cut -d "'" -f 2)";
  HH="$(echo "$H/3*2" |bc)";
  #add additionnal legend 
  convert "$prefix.png" -gravity NorthWest -pointsize 12 -font Liberation-Sans-Bold \
    -annotate +$((WIDTH-150))+$HH "Elapsed time: ${XMAX}\nAllocated cores: ${NCPU}" "$prefix.png" 
done
#rename
#for f in global*.png; do mv $f "sar-${f}"; done
#display
#for f in *.png; do display $f & done
