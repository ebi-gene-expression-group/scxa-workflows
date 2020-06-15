#!/usr/bin/env bash

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

[ -z ${envs_for_workflow_run+x} ] && echo "Env var envs_for_workflow_run should be set by upstream script." && exit 1

[ -z ${matrix_file+x} ] && echo "Env var matrix_file should be set." && exit 1
[ -z ${genes_file+x} ] && echo "Env var genes_file should be set." && exit 1
[ -z ${barcodes_file+x} ] && echo "Env var barcodes_file should be set." && exit 1
[ -z ${cell_meta_file+x} ] && echo "Env var cell_meta_file should be set." && exit 1
[ -z ${gtf_file+x} ] && echo "Env var gtf_file should be set." && exit 1
[ -z ${EXP_ID+x} ] && echo "Env var EXP_ID should be set." && exit 1

inputs_yaml=$WORKDIR/scanpy_clustering_inputs_$EXP_ID\.yaml

sed "s+<MATRIX_PATH>+$matrix_file+" $scriptDir/scanpy_clustering_inputs.yaml.template | \
    sed "s+<GENES_PATH>+$genes_file+" | \
    sed "s+<BARCODES_PATH>+$barcodes_file+" | \
    sed "s+<CELL_META_PATH>+$cell_meta_file+" | \
    sed "s+<GTF_PATH>+$gtf_file+" > $inputs_yaml

echo "export inputs_yaml=$inputs_yaml" > $envs_for_workflow_run
echo "export workflow_definition=$scriptDir/scanpy_clustering_workflow.json" >> $envs_for_workflow_run
echo "export params_json=$scriptDir/scanpy_clustering_workflow_parameters.yaml" >> $envs_for_workflow_run
echo "export allowed_errors=$scriptDir/scanpy_clustering_allowed_errors.yaml" >> $envs_for_workflow_run
