#!/bin/env bash

# This file runs the Galaxy smart-seq Scanpy clustering workflow

# Experiment related, needs to be inyected
export EXP_ID=${ACCESSION}
export EXP_SPECIE=${SPECIE}
export EXP_BUNDLE=${BUNDLE_PATH}

# GALAXY Related, needs to be inyected
export GALAXY_INSTANCE=${GALAXY_INSTANCE}
export GALAXY_CRED_FILE=${GALAXY_CRED_FILE}

export WORKDIR=${./:-$WORKDIR}

[ ! -z ${EXP_SPECIE+x} ] || ( echo "Env var EXP_SPECIE for the species of the experiment needs to be defined." && exit 1 )
[ ! -z ${BUNDLE_PATH+x} ] || ( echo "Env var EXP_BUNDLE for the bundle of the experiment needs to be defined." && exit 1 )
[ ! -z ${EXP_ID+x} ] || ( echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1 )

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $scriptDir/../util/manifest_handing.sh
baseDir=$scriptDir/..

for mod in util util/galaxy-workflow-executor; do
  PATH=$baseDir/$mod:$PATH
done

# Paths for intermediate files:
inputs_yaml=$WORKDIR/scanpy_clustering_inputs_$EXP_ID\.yaml
workflow_definition=$scriptDir/scanpy_clustering_workflow.json
params_json=$scriptDir/scanpy_clustering_params.json

# Create inputs.yaml
matrix_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_content' 'raw' )
genes_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_rows' 'raw' )
barcodes_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_cols' 'raw' )
gtf_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'reference_annotation' '' )

sed "s+<MATRIX_PATH>+$matrix_file+" $scriptDir/scanpy_clustering_inputs.yaml.template | \
    sed "s+<GENES_PATH>+$genes_file+" | \
    sed "s+<BARCODES_PATH>+$barcodes_file+" | \
    sed "s+<GTF_PATH>+$gtf_file+" > $inputs_yaml

# Results potentially relevant for TPM filtering:
raw_filtered_genes=$EXP_BUNDLE/raw_filtered_genes.tsv
raw_filtered_barcodes=$EXP_BUNDLE/raw_filtered_barcodes.tsv

# See if we need to filter TPMs (in the future this could depend on the protocol)
tpm_matrix_file=$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_content' 'tpm' )
tpm_filtering=False
if [ ${#tpm_matrix_file} -gt 0 ]; then
  # matrix file exists for tpm
  tpm_matrix_file=$EXP_BUNDLE/$tpm_matrix_file
  tpm_genes_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_rows' 'tpm')
  tpm_barcodes_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_cols' 'tpm' )
  tpm_filtering=True

  inputs_tpm_filtering_yaml=$WORKDIR/scanpy_tpm_filtering_inputs_$EXP_ID\.yaml
  sed "s+<MATRIX_PATH>+$tpm_matrix_file+" $scriptDir/scanpy_tpm_filtering_inputs.yaml.template | \
      sed "s+<GENES_PATH>+$tpm_genes_file+" | \
      sed "s+<BARCODES_PATH>+$tpm_barcodes_file+" | \
      sed "s+<FILTERED_GENES>+$raw_filtered_genes+" | \
      sed "s+<FILTERED_BARCODES>+$raw_filtered_barcodes+" > $inputs_tpm_filtering_yaml

  tpm_filtering_workflow_definition=$scriptDir/scanpy_tpm_filtering_workflow.json
  params_tpm_filtering_json=$scriptDir/scanpy_tpm_filtering_params.json
fi

# Create needed conda environments if not available
create_conda_env.sh _bioblend@0.12.0_py3 bioblend=0.12.0
conda activate _bioblend@0.12.0_py3

# Main clustering run
run_galaxy_workflow.py -C $GALAXY_CRED_FILE \
                       -i $inputs_yaml \
                       -o $EXP_BUNDLE \
                       -W $workflow_definition \
                       -P $params_json \
                       -H scanpy-clustering-$EXP_ID \
                       -G $GALAXY_INSTANCE

# Filter TPM if needed
if [ $tpm_filtering = "True" ]; then
  run_galaxy_workflow.py -C $GALAXY_CRED_FILE \
                         -i $inputs_tpm_filtering_yaml \
                         -o $EXP_BUNDLE \
                         -W $tpm_filtering_workflow_definition \
                         -P $params_tpm_filtering_json \
                         -H scanpy-tpm-filtering-$EXP_ID \
                         -G $GALAXY_INSTANCE
fi

choose_resolution_per_clustering.py --clusters-path $EXP_BUNDLE --output-dir
