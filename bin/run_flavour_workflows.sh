#!/bin/env bash
set -e

# This file runs the Galaxy smart-seq Scanpy clustering workflow

# Experiment related, needs to be inyected
export EXP_ID=${1:-$expName}
export EXP_SPECIE=${2:-$species}
export EXP_BUNDLE=${BUNDLE_PATH}

# GALAXY Related, needs to be inyected
export GALAXY_INSTANCE=${GALAXY_INSTANCE}
export GALAXY_CRED_FILE=${GALAXY_CRED_FILE}

export WORKDIR=${WORKDIR:-./}

[ ! -z ${FLAVOUR+x} ] || ( echo "Env var FLAVOUR for the type of workflow to be run, matching one of the w_* directories" && exit 1 )
[ ! -z ${GALAXY_INSTANCE+x} ] || ( echo "Env var GALAXY_INSTANCE must be set." && exit 1 )
[ ! -z ${GALAXY_CRED_FILE+x} ] || ( echo "Env var GALAXY_CRED_FILE pointing to the credentials file must be set." && exit 1 )
[ ! -z ${EXP_SPECIE+x} ] || ( echo "Env var EXP_SPECIE for the species of the experiment needs to be defined." && exit 1 )
[ ! -z ${EXP_ID+x} ] || ( echo "Env var EXP_ID for the id/accession of the experiment needs to be defined." && exit 1 )
if [ ! -z ${BUNDLE_PATH+x} ]; then
  [ ! -z ${REF_DIR+x} ] || ( echo "Env var REF_DIR for the reference genome annot needs to be defined." && exit 1 )
fi

scriptDir=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export baseDir=$scriptDir/..

for mod in util util/galaxy-workflow-executor; do
  PATH=$baseDir/$mod:$PATH
done
export PATH

# This is where additional variables defined during the inputs_yaml setup will be left
export envs_for_workflow_run=$WORKDIR/envs_for_workflow_run.sh

bash $baseDir/$FLAVOUR/setup.sh
source $envs_for_workflow_run

bash $baseDir/$FLAVOUR/run_flavour.sh
