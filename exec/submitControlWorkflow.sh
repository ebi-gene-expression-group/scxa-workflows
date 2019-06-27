#!/usr/bin/env bash

usage() { echo "Usage: $0 [-e <experiment ID>] [-q <re-use existing quantifications where present, yes or no>] [-a <re-use existing aggregations where present, yes or no>] [-t <tertiary workflow>] [-w <overwrite exising results, yes or no>]"  1>&2; }  

e=
s=no
t=none
w=no

while getopts ":e:q:a:t:w:" o; do
    case "${o}" in
        e)
            e=${OPTARG}
            ;;
        q)
            q=${OPTARG}
            ;;
        a)
            a=${OPTARG}
            ;;
        t)
            t=${OPTARG}
            ;;
        w)
            w=${OPTARG}
            ;;
        *)
            usage
            exit 0
            ;;
    esac
done
shift $((OPTIND-1))

# Simple script to trigger SCXA workflow

expName=$e
skipQuantification=$q
skipAggregation=$a
tertiaryWorkflow=$t
overwrite=$w

workflow=scxa-control-workflow

# Change working dir for experiment-specific runs

workingDir="$SCXA_WORKFLOW_ROOT/work/${workflow}"
if [ -n "$expName" ]; then
    workingDir="${workingDir}_$expName"
fi

cd $SCXA_WORKFLOW_ROOT

# Are we prod or test?

scxaBranch='master'
if [ "$SCXA_ENV" == 'test' ]; then
    scxaBranch='develop'
fi

export SCXA_BRANCH=$scxaBranch

# Build the Nextflow command

expNamePart=
if [ -n "$expName" ]; then
    expNamePart="--expName $expName"
fi

skipQuantificationPart=
if [ -n "$skipQuantification" ]; then
    if [ "$skipQuantification" != 'yes' ] && [ "$skipQuantification" != 'no' ]; then
        echo "Skip quantification (-q) must be 'yes' or 'no', $skipQuantification provided." 1>&2
        exit 1
    fi

    skipQuantificationPart="--skipQuantification $skipQuantification"
fi

skipAggregationPart=
if [ -n "$skipAggregation" ]; then
    if [ "$skipAggregation" != 'yes' ] && [ "$skipAggregation" != 'no' ]; then
        echo "Skip aggregation (-a) must be 'yes' or 'no', $skipAggregation provided." 1>&2
        exit 1
    fi

    skipAggregationPart="--skipAggregation $skipAggregation"
fi

overwritePart=
if [ -n "$overwrite" ]; then
    if [ "$overwrite" != 'yes' ] && [ "$overwrite" != 'no' ]; then
        echo "Overwrite (-w) must be 'yes' or 'no', $overwrite provided" 1>&2
        exit 1
    fi

    overwritePart="--overwrite $overwrite"
fi

tertiaryWorkflowPart=
if [ -n "$tertiaryWorkflow" ]; then
    tertiaryWorkflowPart="--tertiaryWorkflow $tertiaryWorkflow"
fi

nextflowCommand="nextflow run -N $SCXA_REPORT_EMAIL -r $scxaBranch -resume ${workflow} $expNamePart $skipQuantificationPart $skipAggregationPart $tertiaryWorkflowPart $overwritePart --enaSshUser fg_atlas_sc --sdrfDir $SCXA_SDRF_DIR -work-dir $workingDir"

# Run the LSF submission if it's not already running

bjobs -w | grep "${SCXA_ENV}_$workflow" > /dev/null 2>&1

if [ $? -ne 0 ]; then

    # If workflow completed successfully we can clean up the work dir. If not,
    # then the caching from the work dir will be useful to resume

    successMarker="$SCXA_WORKFLOW_ROOT/work/.success"

    if [ -e "$successMarker" ]; then
        echo "Previous run succeeded, cleaning up $workingDir"
        mv $workingDir ${workingDir}_removing_$$ 
        nohup rm -rf ${workingDir}_removing_$$ &
        rm -rf $successMarker
    fi

    for subworkflow in scxa-droplet-quantification-workflow scxa-control-workflow scxa-smartseq-quantification-workflow scxa-aggregation-workflow scanpy-workflow scxa-bundle-workflow; do
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
