#!/bin/env bash
set -e

# This file runs the Galaxy smart-seq Scanpy clustering workflow

# Experiment related, needs to be inyected
export EXP_ID=${1:-$expName}
export EXP_SPECIE=${2:-$species}
export STATE_FILE=${3:-$state_file}

# GALAXY Related, needs to be inyected
export GALAXY_INSTANCE=${GALAXY_INSTANCE}
export GALAXY_CRED_FILE=${GALAXY_CRED_FILE}

export WORKDIR=${WORKDIR:-$(pwd)}

[ ! -z ${FLAVOUR+x} ] || ( echo "Env var FLAVOUR for the type of workflow to be run, matching one of the w_* directories" && exit 1 )
[ ! -z ${GALAXY_INSTANCE+x} ] || ( echo "Env var GALAXY_INSTANCE must be set." && exit 1 )
[ ! -z ${GALAXY_CRED_FILE+x} ] || ( echo "Env var GALAXY_CRED_FILE pointing to the credentials file must be set." && exit 1 )
[ ! -z ${EXP_SPECIE+x} ] || ( echo "Env var EXP_SPECIE for the species of the experiment needs to be defined." && exit 1 )
[ ! -z ${EXP_ID+x} ] || ( echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1 )
[ -z ${matrix_file+x} ] && echo "Env var matrix_file should be set." && exit 1
[ -z ${genes_file+x} ] && echo "Env var genes_file should be set." && exit 1
[ -z ${barcodes_file+x} ] && echo "Env var barcodes_file should be set." && exit 1
[ -z ${cell_meta_file+x} ] && echo "Env var cell_meta_file should be set." && exit 1
[ -z ${gtf_file+x} ] && echo "Env var gtf_file should be set." && exit 1
[ -z ${EXP_ID+x} ] && echo "Env var EXP_ID should be set." && exit 1

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export baseDir=$scriptDir/..

for mod in util util/galaxy-workflow-executor; do
  PATH=$baseDir/$mod:$PATH
done
export PATH

# Check galaxy-workflow-executor properly installed

which run_galaxy_workflow.py > /dev/null
if [ $? -gt 0 ]; then
  echo "run_galaxy_workflow.py is not in the path, please install galaxy-workflow-executor. Exiting"
  exit 1
fi

which choose_resolution_per_clustering.py > /dev/null
if [ $? -gt 0 ]; then
  echo "choose_resolution_per_clustering.py is not in the path, exiting"
  exit 1
fi

set -e
echo "Results will be available on $WORKDIR"

## Main clustering run

# This is where additional variables defined during the inputs_yaml setup will be left

inputs_yaml=$WORKDIR/scanpy_clustering_inputs_$EXP_ID\.yaml
parameters_yaml=$WORKDIR/scanpy_clustering_parameters_$EXP_ID\.yaml
flavor_dir=$baseDir/$FLAVOUR

# Run substitutions on the inputs template

sed "s+<MATRIX_PATH>+$matrix_file+" $flavor_dir/scanpy_clustering_inputs.yaml.template | \
    sed "s+<GENES_PATH>+$genes_file+" | \
    sed "s+<BARCODES_PATH>+$barcodes_file+" | \
    sed "s+<CELL_META_PATH>+$cell_meta_file+" | \
    sed "s+<GTF_PATH>+$gtf_file+" > $inputs_yaml

# Make any required parameter tweaks

cp $flavor_dir/scanpy_clustering_workflow_parameters.yaml $parameters_yaml
if [ -n "$cell_type_field" ]; then
    sed -i "s/CELL_TYPE_FIELD/$cell_type_field/" $parameters_yaml 
fi

# If the batch variable is set, then tell the workflow about it. Otherwise just
# unset it so any batch-adjustment steps just 'pass through'.

sed -i "s/BATCH_FIELD/$batch_field/" $parameters_yaml 

run_galaxy_workflow.py -C $GALAXY_CRED_FILE \
                       -i $inputs_yaml \
                       -o $WORKDIR \
                       -W $flavor_dir/scanpy_clustering_workflow.json \
                       -P $parameters_yaml \
                       -H scanpy-clustering-$EXP_ID \
                       -a $flavor_dir/scanpy_clustering_allowed_errors.yaml \
                       -G $GALAXY_INSTANCE $ADDITIONAL_GALAXY_WF_EXECUTOR_OPTION \
                       -s $STATE_FILE \
                       --parameters-yaml

mv $WORKDIR/software_versions_galaxy.txt $WORKDIR/clustering_software_versions.txt

choose_resolution_per_clustering.py --clusters-path $WORKDIR --output-dir $WORKDIR
