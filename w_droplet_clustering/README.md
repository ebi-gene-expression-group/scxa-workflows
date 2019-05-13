# Parameters for droplet Scanpy clustering

Below we enumerate and explain the reasoning for deviating from default parameters at the different steps.

## Filter Cells (Scanpy)

- n_genes:
  - min: 400
  - max: Inf (very large number used in Galaxy)
- n_counts
  - min: 0
  - max: 10,000
  
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
  - max: 3.0
- dispersion of expression:
  - min: 0.5
  - max: Inf
- number of bins for binning the mean expression: 20
  
## Scale data (Scanpy)

