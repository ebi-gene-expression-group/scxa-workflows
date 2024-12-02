#!/bin/env bash
set -e

# This file runs the tertiary workflow

# Experiment related, needs to be inyected
export EXP_ID=${1:-$expName}
export EXP_SPECIE=${2:-$species}

export WORKDIR=${WORKDIR:-$(pwd)}

[ ! -z ${FLAVOUR+x} ] || ( echo "Env var FLAVOUR for the type of workflow to be run, matching one of the w_* directories" && exit 1 )
[ ! -z ${EXP_SPECIE+x} ] || ( echo "Env var EXP_SPECIE for the species of the experiment needs to be defined." && exit 1 )
[ ! -z ${EXP_ID+x} ] || ( echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1 )
[ -z ${matrix_file+x} ] && echo "Env var matrix_file should be set." && exit 1
[ -z ${genes_file+x} ] && echo "Env var genes_file should be set." && exit 1
[ -z ${barcodes_file+x} ] && echo "Env var barcodes_file should be set." && exit 1
[ -z ${cell_meta_file+x} ] && echo "Env var cell_meta_file should be set." && exit 1
[ -z ${gene_meta_file+x} ] && echo "Env var gene_meta_file should be set." && exit 1
[ -z ${EXP_ID+x} ] && echo "Env var EXP_ID should be set." && exit 1

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export baseDir=$scriptDir/..

for mod in util; do
   PATH=$baseDir/$mod:$PATH
done
export PATH


which choose_resolution_per_clustering.py > /dev/null
if [ $? -gt 0 ]; then
  echo "choose_resolution_per_clustering.py is not in the path, exiting"
  exit 1
fi



set -e
echo "Results will be available on $WORKDIR"

## Main clustering run

# This is where additional variables defined during the inputs_yaml setup will be left


flavor_dir=$baseDir/$FLAVOUR

# If the batch variable is set, then tell the workflow about it, and also
# adjust the representation used by PCA-consuming workflow steps.


# If we have cell type fields or batch, set those in the params

cell_type_field=${cell_type_field:-'NO_CELLTYPE_FIELD'}
representation='X_pca'
if [ -n "$batch_field" ]; then
    representation='X_pca_harmony'
fi
    


FLAVOUR_NF=''
if [ "$FLAVOUR" = 'w_droplet_clustering' ]; then
    export FLAVOUR_NF='droplet'
elif [ "$FLAVOUR" = 'w_smart-seq_clustering' ]; then
    export FLAVOUR_NF='smartseq'
else
    echo "Unknown FLAVOUR $FLAVOUR"
    exit 1
fi

# Prepare input data for tertiary workflow stores them in $SCXA_WORKDIR 
# bash $baseDir/w_tertiary/scripts/data_prep.sh $EXP_ID $SCXA_WORKDIR

mkdir -p $SCXA_WORKDIR/$EXP_ID/$EXP_SPECIE/tertiary_data
cp $matrix_file $genes_file $barcodes_file $cell_meta_file $gene_meta_file $SCXA_WORKDIR/$EXP_ID/$EXP_SPECIE/tertiary_data/

# Run the workflow
nextflow run $baseDir/w_tertiary/main.nf \
    --dir_path $SCXA_WORKDIR/$EXP_ID/$EXP_SPECIE/tertiary_data \
    --workdir $WORKDIR \
    --flavour $FLAVOUR_NF \
    --batch_field $batch_field \
    --representation $representation \
    --output_path $SCXA_WORKFLOW_ROOT/results/$EXP_ID/$EXP_SPECIE/scanpy

# software_versions_galaxy.txt to be renamed software_versions_tertiary.txt
# To clean up this code later

echo "Analysis  Software  Version  Citation" > $WORKDIR/software_versions_tertiary.txt
echo "Tertiary  scanpy-scripts  v1.1.6  quay.io/biocontainers/scanpy-scripts:1.1.6--pypyhdfd78af_0" >> $WORKDIR/software_versions_tertiary.txt
mv $WORKDIR/software_versions_tertiary.txt $WORKDIR/clustering_software_versions.txt

choose_resolution_per_clustering.py --clusters-path $WORKDIR --output-dir $WORKDIR
