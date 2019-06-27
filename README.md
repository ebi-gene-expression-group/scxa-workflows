# scxa-workflows v0.1.0

Higher level repo for aggregating all of Atlas workflow logic for Single Cell towards execution purposes. Version 0.1.0 was used to run all data analysis for the Spring 2019 Release of Single Cell Expression Atlas.

Alignment and quantification workflows are developed in NextFlow and can be found in the
`w_*_quantification` directories, whereas the clustering and downstream analysis was built
on Galaxy and can be found in `w_*_clustering` directories. All of the Galaxy tools used here
are available from the [Galaxy Toolshed](https://toolshed.g2.bx.psu.edu/view/ebi-gxa) to be installed on any instance. The tools are available for direct use as well on the [Human Cell Atlas Euopean Galaxy](https://humancellatlas.usegalaxy.eu/) instance.

## Organization

Each workflow type will live in a `w_` prefixed directory, where the execution should fine everything needed to run it, with execution configuration being inyectable. The content of the directory should include:

- Parameters
- Workflow definition
- Any software requisites (ie. do you need to install a conda package for the executor of the workflow?)

The definition for fulfilling this is rather flexible (it could be either the file itself or something that links to that information, provided it can be followed by the automatic executor).

### Technology

The `w_` prefix is followed by a technology name. The name should not use underscores, but dashes instead if needed. Current technologies supported will be:

- smart-seq
- smart-seq2
- smarter
- smart-like
- 10xv1*
- 10xv1a*
- 10xv1i*
- 10xv2
- drop-seq

 \* Not to be supported in first droplet Alevin-based pipeline

### Phase of analysis

Given that we currently have separation between quantification and clustering, the `w_technology_` prefix will be followed by a phase of analysis section. Currently:

- quantification
- clustering

### Running the clustering part manually

To run the clustering part manually, define the following environment variables
in the environment (example below for E-ENAD-15):

```
export species=mus_musculus
export expName=E-ENAD-15

export matrix_file=$BUNDLE/raw/matrix.mtx.gz
export genes_file=$BUNDLE/raw/genes.tsv.gz
export barcodes_file=$BUNDLE/raw/barcodes.tsv.gz
export gtf_file=$REF/$species/Mus_musculus.GRCm38.95.gtf.gz

export tpm_matrix_file=$BUNDLE/tpm/matrix.mtx.gz
export tpm_genes_file=$BUNDLE/tpm/genes.tsv.gz
export tpm_barcodes_file=$BUNDLE/tpm/barcodes.tsv.gz

export create_conda_env=yes
export GALAXY_CRED_FILE=../galaxy_credentials.yaml
export GALAXY_INSTANCE=ebi_cluster

export FLAVOUR=w_smart-seq_clustering
```

If `create_conda_env` is set to `no`, then the the following script should be executed
in an environment that has bioblend and Python 3. Then execute:

```
run_flavour_workflows.sh
```
