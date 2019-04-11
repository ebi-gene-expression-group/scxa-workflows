#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $scriptDir/../util/manifest_handling.sh

[ -z ${envs_for_workflow_run+x} ] && echo "Env var envs_for_workflow_run should be set by upstream script." && exit 1

# Create inputs.yaml based on MANIFEST
if [ -z ${EXP_BUNDLE+x} ]; then
  matrix_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_content' 'raw' )
  genes_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_rows' 'raw' )
  barcodes_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_cols' 'raw' )
  gtf_file=$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'reference_annotation' '' )
fi

[ -z ${matrix_file+x} ] && echo "Env var matrix_file should be set." && exit 1
[ -z ${genes_file+x} ] && echo "Env var genes_file should be set." && exit 1
[ -z ${barcodes_file+x} ] && echo "Env var barcodes_file should be set." && exit 1
[ -z ${gtf_file+x} ] && echo "Env var gtf_file should be set." && exit 1
[ -z ${EXP_ID+x} ] && echo "Env var EXP_ID should be set." && exit 1

inputs_yaml=$WORKDIR/scanpy_clustering_inputs_$EXP_ID\.yaml

sed "s+<MATRIX_PATH>+$matrix_file+" $scriptDir/scanpy_clustering_inputs.yaml.template | \
    sed "s+<GENES_PATH>+$genes_file+" | \
    sed "s+<BARCODES_PATH>+$barcodes_file+" | \
    sed "s+<GTF_PATH>+$gtf_file+" > $inputs_yaml

echo "export inputs_yaml=$inputs_yaml" > $envs_for_workflow_run

# Results potentially relevant for TPM filtering:
echo "export raw_filtered_genes=$WORKDIR/raw_filtered_genes.tsv" >> $envs_for_workflow_run
echo "export raw_filtered_barcodes=$WORKDIR/raw_filtered_barcodes.tsv" >> $envs_for_workflow_run

# See if we need to filter TPMs (in the future this could depend on the protocol)
if [ -z ${EXP_BUNDLE+x} ]; then
  tpm_matrix_file=$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_content' 'tpm' )
fi

tpm_filtering=False
if [ ${#tpm_matrix_file} -gt 0 ]; then
  # matrix file exists for tpm
  tpm_matrix_file=${tpm_matrix:-$EXP_BUNDLE/$tpm_matrix_file}
  tpm_genes_file=${tpm_genes:-$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_rows' 'tpm')}
  tpm_barcodes_file=${tpm_barcodes:-$EXP_BUNDLE/$( file_for_desc_param $EXP_BUNDLE/MANIFEST 'mtx_matrix_cols' 'tpm' )}
  tpm_filtering=True

  inputs_tpm_filtering_yaml=$WORKDIR/scanpy_tpm_filtering_inputs_$EXP_ID\.yaml
  sed "s+<MATRIX_PATH>+$tpm_matrix_file+" $scriptDir/scanpy_tpm_filtering_inputs.yaml.template | \
      sed "s+<GENES_PATH>+$tpm_genes_file+" | \
      sed "s+<BARCODES_PATH>+$tpm_barcodes_file+" | \
      sed "s+<FILTERED_GENES>+$raw_filtered_genes+" | \
      sed "s+<FILTERED_BARCODES>+$raw_filtered_barcodes+" > $inputs_tpm_filtering_yaml

  echo "export inputs_tpm_filtering_yaml=$inputs_tpm_filtering_yaml" >> $envs_for_workflow_run
  echo "export tpm_filtering_workflow_definition=$scriptDir/scanpy_tpm_filtering_workflow.json" >> $envs_for_workflow_run
  echo "export params_tpm_filtering_json=$scriptDir/scanpy_tpm_filtering_params.json" >> $envs_for_workflow_run
fi

echo "export tpm_filtering=$tpm_filtering" >> $envs_for_workflow_run
