#!/usr/bin/env bash

usage() { echo "Usage: $0 [-e <experiment ID>] [-s <skip quantification, yes or no>] [-t <tertiary workflow>] [-o <overwrite exising results, yes or no>]"  1>&2; }  

e=
s=no
t=none
o=no

while getopts ":e:s:t:o:" o; do
    case "${o}" in
        e)
            e=${OPTARG}
            ;;
        s)
            s=${OPTARG}
            ;;
        t)
            t=${OPTARG}
            ;;
        o)
            o=${OPTARG}
            ;;
        *)
            usage
            exit 0
            ;;
    esac
done
shift $((OPTIND-1))

# Trivially simple script to trigger SCXA workflow

expName=$e
skipQuantification=$s
tertiaryWorflow=$t
overwrite=$o

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
        echo "Skip quantification (-s) must be 'yes' or 'no'"
    fi

    skipQuantificationPart="--skipQuantification $skipQuantification"
fi

overwritePart=
if [ -n "$overwrite" ]; then
    if [ "$overwrite" != 'yes' ] && [ "$overwrite" != 'no' ]; then
        echo "Override (-o) must be 'yes' or 'no'"
    fi

    overwritePart="--overwrite $overwrite"
fi

tertiaryWorkflowPart=
if [ -n "$tertiaryWorkflow" ]; then
    tertiaryWorkflowPart="--tertiaryWorkflow $tertiaryWorkflow"
fi

nextflowCommand="NXF_VER=19.03.0-SNAPSHOT nextflow run -N $SCXA_REPORT_EMAIL -r $scxaBranch -resume ${workflow} $expNamePart $skipQuantificationPart $tertiaryWorkflowPart $overwritePart --enaSshUser fg_atlas_sc --sdrfDir $SCXA_SDRF_DIR -work-dir $workingDir"

# Run the LSF submission if it's not already running

bjobs -w | grep "${SCXA_ENV}_$workflow" > /dev/null 2>&1

if [ $? -ne 0 ]; then

    # If workflow completed successfully we can clean up the work dir. If not,
    # then the caching from the work dir will be useful to resume

    successMarker="$SCXA_WORKFLOW_ROOT/work/.success"

    if [ -e "$successMarker" ]; then
        rm -rf $workingDir
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
