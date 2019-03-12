[![License: CeCILL](https://img.shields.io/badge/license-CeCILL-blue.svg)](http://www.cecill.info/)

WMS-benchmark
=============
WMS-benchmark reports the code used to benchmark workflow
management systems (WMS) on a bioinformatics use case, [LodSeq](https://github.com/CNRGH/LodSeq).

The following WMS were tested:
- [pegasus-mpi-cluster](https://pegasus.isi.edu/documentation/cli-pegasus-mpi-cluster.php)
- [snakemake](https://snakemake.readthedocs.io/en/stable/)
- [nextflow](https://www.nextflow.io/)
- [cromwell-WDL](https://software.broadinstitute.org/wdl/)
- [toil-CWL (cwltoil)](http://toil.ucsc-cgl.org/)


CITATION
--------
Please cite WMS-benchmark using this citation:

E. Larsonneur, J. Mercier, N. Wiart, E. Le Floch, O. Delhomme and V. Meyer, "Evaluating Workflow Management Systems: A Bioinformatics Use Case," 2018 IEEE International Conference on Bioinformatics and Biomedicine (BIBM), Madrid, Spain, 2018, pp. 2773-2775.
[doi: 10.1109/BIBM.2018.8621141](https://dx.doi.org/10.1109/BIBM.2018.8621141).

A supplementary table and a corrected figure are available in `figures/`.

HOW TO RUN THE BENCHMARK
------------------------
See `script/all.sh` for details.

The full dataset is available [here](https://www.cnrgh.fr/download/96203eab325de3c0bda48009aaa15fd7cf339b26/) or [here](https://dx.doi.org/10.5281/zenodo.2592064).<br>

We proposed ten metrics for evaluating the efficiency of workflow management systems,
they were extracted from [pidstat](https://linux.die.net/man/1/pidstat), `fg_sar` and `benchme` output files. `fg_sar` uses [sar](https://linux.die.net/man/1/sar), and `benchme` uses [time](https://linux.die.net/man/1/time) to compute metrics. `fg_sar` and `benchme` are a part of `fgtools` toolkit and can be found in the directory `./fgtools`. `fg_sar` requires [sysstat<=11.5.2](http://sebastien.godard.pagesperso-orange.fr/).

<br>
To know how to run the workflow management systems with a toy dataset,
please see the `gitlab-ci.yml` file.

AUTHORS
-------
Elise Larsonneur, Centre National de Recherche en Génomique Humaine, CEA, Evry, France, elise.larsonneur@cea.fr<br>
Edith Le Floch, Centre National de Recherche en Génomique Humaine, CEA, Evry, France, edith.le-floch@cea.fr<br>
Jonathan Mercier, Centre National de Recherche en Génomique Humaine, CEA, Evry, France, jonathan.mercier@cea.fr<br>
Nicolas Wiart, Centre National de Recherche en Génomique Humaine, CEA, Evry, France, nicolas.wiart@cea.fr<br>

LICENSING
---------
WMS-benchmark is released under the terms of the CeCILL license,
a free software license agreement adapted to both international and French legal matters
that is fully compatible with the GNU GPL, GNU Affero GPL and/or EUPL license.

For further details see LICENSE file or check out http://www.cecill.info/.
