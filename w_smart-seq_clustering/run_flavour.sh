#!/usr/bin/env bash

# Create needed conda environments if not available
if [ ! -z ${create_conda_env+x} ]; then
  create_conda_env.sh _bioblend@0.12.0_py3 'bioblend=0.12.0 requests-toolbelt=0.9.1' bioconda
  source activate _bioblend@0.12.0_py3
fi

which run_galaxy_workflow.py
if [ $? -gt 0 ]; then
  echo "run_galaxy_workflow.py is not in the path, exiting"
  exit 1
fi

which choose_resolution_per_clustering.py
if [ $? -gt 0 ]; then
  echo "choose_resolution_per_clustering.py is not in the path, exiting"
  exit 1
fi

echo "Results will be available on $WORKDIR"
# Main clustering run
run_galaxy_workflow.py -C $GALAXY_CRED_FILE \
                       -i $inputs_yaml \
                       -o $WORKDIR \
                       -W $workflow_definition \
                       -P $params_json \
                       -H scanpy-clustering-$EXP_ID \
                       -a $allowed_errors \
                       -G $GALAXY_INSTANCE
mv $WORKDIR/software_versions_galaxy.txt $WORKDIR/clustering_software_versions.txt
# Filter TPM if needed
if [ $tpm_filtering = "True" ]; then
  run_galaxy_workflow.py -C $GALAXY_CRED_FILE \
                         -i $inputs_tpm_filtering_yaml \
                         -o $WORKDIR \
                         -W $tpm_filtering_workflow_definition \
                         -P $params_tpm_filtering_json \
                         -H scanpy-tpm-filtering-$EXP_ID \
                         -G $GALAXY_INSTANCE
fi
mv $WORKDIR/software_versions_galaxy.txt $WORKDIR/filter_tpms_software_versions.txt

choose_resolution_per_clustering.py --clusters-path $WORKDIR --output-dir $WORKDIR
