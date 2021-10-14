# Parameters for droplet Scanpy clustering

Below we enumerate and explain the reasoning for deviating from default parameters at the different steps.

## Filter Cells (Scanpy)

- n_counts:
  - min: 1500
  - max: Inf (very large number used in Galaxy)
  
## Filter Genes (Scanpy)

- n_cells:
  - min: 3
  - max: Inf

## Normalise Data (Scanpy)

No deviations from defaults.

## Find variable genes (Scanpy)

- flavour: Seurat
- mean of expression:
  - min: 0.0125
  - max: Inf
- dispersion of expression:
  - min: 0.5
  - max: 50
- number of bins for binning the mean expression: 20
  
## Scale data (Scanpy)

- log1p scaling: yes

(no other scaling)

## Run PCA (Scanpy)

- number of PCs: 50
- incremental PCA by chunks: no
- Zero center: no
- SVD soler: arpack

## Compute Graph / neighbours (Scanpy)

- max neighbours: 15
- use indicated: x_pca use PCs
- hard threshold on neighbourhood: yes
- method for connectivity: UMAP
- distance: Euclidian

## Find clusters (Scanpy)

- representation: vtraag
- use weights from knn graph: false

## Run t-SNE (Scanpy)

No deviations

## UMAP (Scanpy)

No deviations

## Find markers (Scanpy)

- number of top genes: 100
