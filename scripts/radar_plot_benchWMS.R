#!/usr/bin/env Rscript

" Copyright 2018 CEA CNRGH (Centre National de Recherche en Genomique Humaine)
                     <www.cnrgh.fr>                                           
  Authors: Elise LARSONNEUR (elise.larsonneur@cea.fr)                         
           Jonathan MERCIER (jonathan.mercier@cea.fr)                          "

library(fmsb) 

args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  stop("At least one argument must be supplied (input file).", call.=FALSE)
}

filein=args[1]

fileoutsvg=paste(filein,'_radarplot.svg', sep="")
fileoutpng=paste(filein,'_radarplot.png', sep="")
fileoutmaxpng=paste(filein,'_radarplot_maxval.png', sep="")
fileouttiff=paste(filein,'_radarplot.tiff', sep="")
fileoutmaxtiff=paste(filein,'_radarplot_maxval.tiff', sep="")

#header of filein:
# Workflow        B_Elapsed_Time  B_CPU_Prct      B_Max_Memory    S_Max_CPU_Prct  S_Mean_CPU_Prct S_Max_Memory    P_Max_CPU_Prct  P_Mean_CPU_Prct P_Max_Memory    P_CSWCH_S       P_NVCSWCH_S     S_IOWAIT_TIME_PRCT      S_IOWAIT_TIME_SECS_IDLE_TIME_PRCT S_IDLE_TIME_MIN

d = read.table(filein, header=TRUE)

e = as.data.frame(d[,2:ncol(d)]) 

rownames(e) = d[,1]

#sapply(e, as.double)
#f = sapply(e, as.double)
#data = rbind(apply(f, 2, max),apply(f, 2, min),f) 
data = rbind(apply(e, 2, max),apply(e, 2, min),e) 

color_labels <- c("#C0504D","#9BBB59","#8064A2","#4BACC6","#F79646","#1F497D","#4F81BD")

#svg
svg(filename = fileoutsvg, width = 10, height = 10, pointsize = 4,
    onefile = TRUE, family = "sans", bg = "white")
radarchart(data, pcol=color_labels, plty=1, cglcol="grey", axistype=0)
legend(x=1.2, y=1, legend = rownames(data[-c(1,2),]), bty = "n", pch=20  , text.col = "black", cex=1.2, pt.cex=3, col=color_labels) 
dev.off()

#save the plot to a png file
png(fileoutpng, height = 4, width = 5, units = "in", res=300, pointsize=4)
radarchart(data, pcol=color_labels, plty=1, cglcol="grey", axistype=0)
legend(x=1.2, y=1, legend = rownames(data[-c(1,2),]), bty = "n", pch=20  , text.col = "black", cex=1.2, pt.cex=3, col=color_labels) 
dev.off()

#save the plot to a png file
png(fileoutmaxpng, height = 4, width = 5, units = "in", res=300, pointsize=4)
#specify max value on each plot axis (axistype=2):
radarchart(data, pcol=color_labels, plty=1, cglcol="grey", axistype=2)
legend(x=1.2, y=1, legend = rownames(data[-c(1,2),]), bty = "n", pch=20  , text.col = "black", cex=1.2, pt.cex=3, col=color_labels) 
dev.off()

#save the plot to a tiff file
png(fileouttiff, height = 4, width = 5, units = "in", res=300, pointsize=4)
#specify max value on each plot axis (axistype=2):
radarchart(data, pcol=color_labels, plty=1, cglcol="grey", axistype=0)
legend(x=1.2, y=1, legend = rownames(data[-c(1,2),]), bty = "n", pch=20  , text.col = "black", cex=1.2, pt.cex=3, col=color_labels) 
dev.off()
#save the plot to a tiff file
png(fileoutmaxtiff, height = 4, width = 5, units = "in", res=300, pointsize=4)
#specify max value on each plot axis (axistype=2):
radarchart(data, pcol=color_labels, plty=1, cglcol="grey", axistype=2)
legend(x=1.2, y=1, legend = rownames(data[-c(1,2),]), bty = "n", pch=20  , text.col = "black", cex=1.2, pt.cex=3, col=color_labels) 
dev.off()
