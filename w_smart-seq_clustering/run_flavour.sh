#!/usr/bin/env bash

which run_galaxy_workflow.py
if [ $? -gt 0 ]; then
  echo "run_galaxy_workflow.py is not in the path, please install galaxy-workflow-executor. Exiting"
  exit 1
fi

which choose_resolution_per_clustering.py
if [ $? -gt 0 ]; then
  echo "choose_resolution_per_clustering.py is not in the path, exiting"
  exit 1
fi

set -e
echo "Results will be available on $WORKDIR"

# Main clustering run
run_galaxy_workflow.py -C $GALAXY_CRED_FILE \
                       -i $inputs_yaml \
                       -o $WORKDIR \
                       -W $workflow_definition \
                       -P $params_json \
                       -H scanpy-clustering-$EXP_ID \
                       -a $allowed_errors \
                       -G $GALAXY_INSTANCE $ADDITIONAL_GALAXY_WF_EXECUTOR_OPTION
mv $WORKDIR/software_versions_galaxy.txt $WORKDIR/clustering_software_versions.txt

choose_resolution_per_clustering.py --clusters-path $WORKDIR --output-dir $WORKDIR
