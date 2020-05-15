# scxa-workflows v0.2.0

Higher level repo for aggregating all of Atlas workflow logic for Single Cell
towards execution purposes. Version 0.2.0 was used to run all data analysis for
the [Release 10](https://www.ebi.ac.uk/gxa/sc/release-notes.html) of
[Single Cell Expression Atlas](https://www.ebi.ac.uk/gxa/sc/home).

Alignment and quantification workflows are developed in NextFlow and can be
found in the `w_*_quantification` directories, whereas the clustering and
downstream analysis was built on Galaxy and can be found in `w_*_clustering`
directories. All of the Galaxy tools used here are available from the
[Galaxy Toolshed](https://toolshed.g2.bx.psu.edu/view/ebi-gxa) to be installed
on any instance. The tools are available for direct use as well on the
[Human Cell Atlas European Galaxy](https://humancellatlas.usegalaxy.eu/) instance
and the workflow itself available directly [there](https://humancellatlas.usegalaxy.eu/u/pmoreno/w/ebi-sc-expression-atlas-release-10-analysis-pipeline-scanpy-143).
Details of all of the Single Cell tools that we have available in this setup can be found in our [pre-print](https://www.biorxiv.org/content/10.1101/2020.04.08.032698v1).

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

# Setting up access to a Galaxy instance

To run the Galaxy part, you will need a running Galaxy instance with all tools installed. Below we explain with [Human Cell Atlas use-galaxy.eu](https://humancellatlas.usegalaxy.eu/) as an example which already has the tools, but the same holds for another instance where the Galaxy tools are installed.

## Using Human Cell Atlas use-galaxy.eu instance

The [Human Cell Atlas use-galaxy.eu](https://humancellatlas.usegalaxy.eu/) Galaxy instance already has all the tools required installed there, and can be used to reproduce the Expression Atlas clustering pipeline available here. For this you need to:
- Create an account at https://humancellatlas.usegalaxy.eu/ by clicking on **Login or Register**
![image](https://user-images.githubusercontent.com/368478/62038201-35d49300-b1ed-11e9-9c87-571cf539cb8c.png)
- Retrieve your user's API Key for programmatic access:
![image](https://user-images.githubusercontent.com/368478/62038291-5f8dba00-b1ed-11e9-864a-aa2d27f69e91.png)
  - Click on Manage API Key
  ![image](https://user-images.githubusercontent.com/368478/62038697-1c801680-b1ee-11e9-9bb0-e7b1d1cd6439.png)
  - Click on create API Key if not available, and copy it, to use in in the credentials file needed of the Galaxy workflow executor module (galaxy_credentials.yaml file, as the one [here](https://github.com/ebi-gene-expression-group/galaxy-workflow-executor/blob/b36dcb1eeb546f0b34566e95fb55202d92a34520/galaxy_credentials.yml.sample))
  ![image](https://user-images.githubusercontent.com/368478/62038543-d6c34e00-b1ed-11e9-9aae-8d0647e9ea13.png)

Make sure that environment variable `GALAXY_CRED_FILE` points to the file where you put the API key, and that `GALAXY_INSTANCE` env variable is accordingly set to match what it is in that file.
