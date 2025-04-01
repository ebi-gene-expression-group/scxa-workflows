# scxa-workflows v0.3.0

Higher level repo for aggregating all of Atlas workflow logic for Single Cell
towards execution purposes. v0.3.0 will be used to generate a future release of Single-Cell Expression Atlas.

Alignment and quantification workflows are developed in Nextflow and can be
found in the `w_*_quantification` directories, whereas the clustering and
downstream analysis can be found in `w_*_clustering`
directories. 

## Changes in latest version

### Workflow logic

#### Secondary (quantification)

Quantification workflows now take transcriptome indices as input rather than generating them dynamically. This reflects our in-house usage of [Refgenie](http://refgenie.databio.org/en/latest/) to produce libraries of all the index permutations we need (e.g. with/ without spikes).

#### Tertiary (post-quantification)

Some changes were added based on discussion with domain experts and some [semi-quantitative evaluation](https://github.com/ebi-gene-expression-group/scanpy-parameter-explorer) based on separation of known clusters in dimension reductions:

 * Filtering. Switch cell-wise filtering to filter based on counts only with count > 1500 (plate based) or 750 (droplet). Add mitochondrial content threshold of 35%. 
 * Scaling step added for droplet experiments specifically. 
 * Scrublet pre-filtering added to droplet workflow.
 * For batched experiments, supply batch to the highly-variable genes step in Scanpy.
 * Differential testing switched to Wilcoxon from the t-test used previously. 
 * Tertiary workflow now takes a simple tab-delimited file for gene annotations, replacing previous GTF.

 Tertiary analysis have been moved to nextflow, and can be found in `w_tertiary`.

### annData output

We now produce detailed [annData](https://anndata.readthedocs.io/en/latest/) files as a key output of the tertiary workflow, combining most workflow outputs into a single object. See below for discussion.

### Software

Software version updates are:

 - Scanpy updated to 1.8.1
 - Salmon (Alevin-fry, droplet pipeline) updated to 1.7.0
 - Kallisto (SMART-like pipeline) updated to 0.46.2
 - atlas-fastq-provider updated to 0.4.7

## Organization

Each workflow type will live in a `w_` prefixed directory, where the execution should fine everything needed to run it, with execution configuration being injectable. The content of the directory should include:

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

# Raw matrix file components
export matrix_file=$BUNDLE/raw/matrix.mtx.gz
export genes_file=$BUNDLE/raw/genes.tsv.gz
export barcodes_file=$BUNDLE/raw/barcodes.tsv.gz

# Cell and gene-wise additional metadata

export gene_meta_file=$BUNDLE/reference/gene_annotation.txt
export cell_meta_file=$BUNDLE/E-ENAD-15.cell_metadata.tsv

# Optional parameters 

export cell_type_field='inferred_cell_type_-_-ontology labels' # To calculate cell type markers
export batch_field='individual' # To run a batch correction using Harmony on a specific covariate

export create_conda_env=yes
export FLAVOUR=w_smart-seq_clustering
```

If `create_conda_env` is set to `no`, then the the following script should be executed
in an environment that has bioblend and Python 3. Then execute:

```
run_tertiary_workflow.sh
```

#### Extra metadata files

The gene and cell metadata files are simple tab-delimited files will be matched via their first column to the identifiers in genes.tsv and barcodes.tsv, respectively. 

The gene_metadata table can be derived from a GTF-format Ensembl-style annotation file using the [atlas-gene-annotation-manipulation](tool) we provide. It can be executed like:

```
gtf2featureAnnotation.R --gtf-file GTF_FILE --version-transcripts \
    --feature-type "gene" --mito --mito-biotypes \
    'mt_trna,mt_rrna,mt_trna_pseudogene,mt_dna' --mito-chr \
    'mt,mitochondrion_genome,mito,m,chrM,chrMt' --first-field "gene_id" \
    --output-file gene_annotation.txt
```

See the [documentation](https://github.com/ebi-gene-expression-group/atlas-gene-annotation-manipulation) of that script for information on the options available.

## annData-format output files

The tertiary workfow described above now provides an annData-format (.h5ad) summary object containing almost all analytical outputs, including:

 * Expression matrices (in .raw.X, .X and .layers)
 * Compreshensive gene and cell annotation tables (.obs and .var, respectively)
 * Dimension reductions (t-SNE and UMAP) in .obsm
 * Predicted marker genes (in .uns)

These files can be loaded with a tool like [cellxgene](https://chanzuckerberg.github.io/cellxgene/) to visualise the dimension reductions alongside the available metadata.

The files can be read into Python using the Scanpy module:

```
 >>> import scanpy as sc
 >>> adata = sc.read("E-HCAD-9.project.h5ad")
 ```

### Expression matrices

Expression matrices are stored in the following slots:

 * Raw, un-normalised expression matrices in **.raw.X**. Since .raw must match in terms of cells with .X, this is not quite 'fully raw', and some cells with low counts will have been removed. Historically, this slot was used to store normalised and transformed expression values prior to removal of genes at the 'highly variable genes' step, which is not longer the default behahaviour. We have repurposed it here to provide 'raw as possible' expression values.
 * Matrix with gene filtering applied, in **.layers['filtered']**.
 * Normalised matrix, without transformation in **.layers['normalised']**
 * Final matrix used in all dimenstion reduction and clustering, in **.X**. This will be scaled relative to the normalised matrix, and have an additional scaling transformation in the case of droplet experiments. 

The variants supplied are intended to allow users to undertake re-analyses from a variety of stages in our analysis with the mimumum of effort.

### Dimensionality reductions

The tertiary pipeline operates in parallel to produce variants of dimension reduction resulting from manipulation of key parameters (under review, but currently perplexity for t-SNE and number of neighbours for UMAP). As a consequence you will find multiple keyed alternative representations in .obsm:

 ```
 > adata.obsm
AxisArrays with keys: X_pca, X_pca_harmony, X_tsne_perplexity_1, X_tsne_perplexity_10, X_tsne_perplexity_15, X_tsne_perplexity_20, X_tsne_perplexity_25, X_tsne_perplexity_30, X_tsne_perplexity_35, X_tsne_perplexity_40, X_tsne_perplexity_45, X_tsne_perplexity_5, X_tsne_perplexity_50, X_umap_neighbors_n_neighbors_10, X_umap_neighbors_n_neighbors_100, X_umap_neighbors_n_neighbors_15, X_umap_neighbors_n_neighbors_20, X_umap_neighbors_n_neighbors_25, X_umap_neighbors_n_neighbors_3, X_umap_neighbors_n_neighbors_30, X_umap_neighbors_n_neighbors_5, X_umap_neighbors_n_neighbors_50
```
### Cell groups

Cell groupings including predicted clusters, annotated cell types and others are stored in .obs:

```
>>> adata.obs.columns
Index(['age', 'cause_of_death', 'developmental_stage', 'disease', 'individual',
       'organism_part', 'organism_status', 'organism', 'sampling_site', 'sex',
       'authors_cell_type_-_ontology_labels', 'authors_cell_type',
       'individual.1', 'age_ontology', 'cause_of_death_ontology',
       'developmental_stage_ontology', 'disease_ontology',
       'individual_ontology', 'organism_part_ontology',
       'organism_status_ontology', 'organism_ontology',
       'sampling_site_ontology', 'sex_ontology',
       'authors_cell_type_-_ontology_labels_ontology',
       'authors_cell_type_ontology', 'individual_ontology.1', 'n_genes',
       'doublet_score', 'predicted_doublet', 'n_genes_by_counts',
       'log1p_n_genes_by_counts', 'total_counts', 'log1p_total_counts',
       'total_counts_mito', 'log1p_total_counts_mito', 'pct_counts_mito',
       'n_counts', 'leiden_resolution_0.1', 'leiden_resolution_0.3',
       'leiden_resolution_0.5', 'leiden_resolution_0.7',
       'leiden_resolution_1.0', 'leiden_resolution_2.0',
       'leiden_resolution_3.0', 'leiden_resolution_4.0',
       'leiden_resolution_5.0'],
      dtype='object')
```

### Marker genes

Marker genes are currently stored in .uns alongside unstructured metadata, and are available for predicted clusters and selected cell groupings:

```
>>> list(filter(lambda x: 'marker' in x, adata.uns.keys()))
['markers_authors_cell_type_-_ontology_labels', 'markers_authors_cell_type_-_ontology_labels_filtered', 'markers_leiden_resolution_0.1', 'markers_leiden_resolution_0.1_filtered', 'markers_leiden_resolution_0.3', 'markers_leiden_resolution_0.3_filtered', 'markers_leiden_resolution_0.5', 'markers_leiden_resolution_0.5_filtered', 'markers_leiden_resolution_0.7', 'markers_leiden_resolution_0.7_filtered', 'markers_leiden_resolution_1.0', 'markers_leiden_resolution_1.0_filtered', 'markers_leiden_resolution_2.0', 'markers_leiden_resolution_2.0_filtered', 'markers_leiden_resolution_3.0', 'markers_leiden_resolution_3.0_filtered', 'markers_leiden_resolution_4.0', 'markers_leiden_resolution_4.0_filtered', 'markers_leiden_resolution_5.0', 'markers_leiden_resolution_5.0_filtered']
```
