#!/usr/bin/env bash

expName=${1:-''}

# Trivially simple script to trigger SCXA workflow

workflow=scxa-control-workflow
cd $SCXA_WORKFLOW_ROOT

# Are we prod or test?

scxaBranch='master'
if [ "$SCXA_ENV" == 'test' ]; then
    scxaBranch='develop'
fi

export SCXA_BRANCH=$scxaBranch

# Build the Nextflow command

if [ -n "$expName" ]; then
    expNamePart="--expName $expName"
fi
nextflowCommand="NXF_VER=19.03.0-SNAPSHOT nextflow run -N $SCXA_REPORT_EMAIL -r $scxaBranch -resume ${workflow} $expNamePart --enaSshUser fg_atlas_sc --sdrfDir $SCXA_SDRF_DIR -work-dir $SCXA_WORKFLOW_ROOT/work/$workflow"

# Run the LSF submission if it's not already running

bjobs -w | grep "test_$workflow" > /dev/null 2>&1

if [ $? -ne 0 ]; then

    # If workflow completed successfully we can clean up the work dir. If not,
    # then the caching from the work dir will be useful to resume

    successMarker="$SCXA_WORKFLOW_ROOT/work/.success"

    if [ -e "$successMarker" ]; then
        rm -rf $SCXA_WORKFLOW_ROOT/work/$workflow
        rm -rf $successMarker
    fi

    for subworkflow in scxa-control-workflow scxa-smartseq-quantification-workflow scxa-aggregation-workflow scanpy-workflow scxa-bundle-workflow; do
        nextflow pull $subworkflow  -r $scxaBranch
    done

    echo "Submitting job"
    rm -rf run.out run.err .nextflow.log*  
    bsub \
        -J ${SCXA_ENV}_$workflow \
        -M 4096 -R "rusage[mem=4096]" \
        -u $SCXA_REPORT_EMAIL \
        -o run.out \
        -e run.err \
        "$nextflowCommand" 
else
    echo "Workflow process already running" 
fi   
