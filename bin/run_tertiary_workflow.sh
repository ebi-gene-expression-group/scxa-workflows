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


which choose_resolution_per_clustering.py > /dev/null
if [ $? -gt 0 ]; then
  echo "choose_resolution_per_clustering.py is not in the path, exiting"
  exit 1
fi

set -e
echo "Results will be available on $WORKDIR"

## Main clustering run

# This is where additional variables defined during the inputs_yaml setup will be left

parameters_yaml=$WORKDIR/scanpy_clustering_parameters_$EXP_ID\.yaml  # do we need this?
flavor_dir=$baseDir/$FLAVOUR

# If the batch variable is set, then tell the workflow about it, and also
# adjust the representation used by PCA-consuming workflow steps.

function sub_in_params {
    param=$1
    value=$2

    sed -i "s/$param: '.*'/$param: '$value'/" $parameters_yaml
}

cp $flavor_dir/scanpy_clustering_workflow_parameters.yaml $parameters_yaml

# If we have cell type fields or batch, set those in the params

cell_type_field=${cell_type_field:-'NO_CELLTYPE_FIELD'}
representation='X_pca'
if [ -n "$batch_field" ]; then
    representation='X_pca_harmony'
fi
    
sub_in_params 'cell_type_field' "$cell_type_field"
sub_in_params 'batch_variable' "$batch_field"
sub_in_params 'representation' "$representation"


FLAVOUR_NF=''
if [ "$FLAVOUR" = 'w_droplet_clustering' ]; then
    export FLAVOUR_NF='droplet'
elif [ "$FLAVOUR" = 'w_smart-seq_clustering' ]; then
    export FLAVOUR_NF='smartseq'
else
    echo "Unknown FLAVOUR $FLAVOUR"
    exit 1
fi

# Prepare input data for tertiary workflow stores them in $SCXA_WORK 
bash $baseDir/scxa-tertiary-workflow/scripts/dataprep.sh $EXP_ID $SCXA_WORK

# Run the workflow
nextflow run $baseDir/scxa-tertiary-workflow/main.nf \
    --exp_id $EXP_ID \
    --workdir $WORKDIR \
    --flavour $FLAVOUR_NF \
    --batch_field $batch_field \
    --representation $representation


mv $WORKDIR/software_versions_galaxy.txt $WORKDIR/clustering_software_versions.txt

choose_resolution_per_clustering.py --clusters-path $WORKDIR --output-dir $WORKDIR
