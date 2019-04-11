#!/usr/bin/env bash

conda_env_name=${1:-$CONDA_ENV}
conda_packages=${2:-$CONDA_PACKAGES}
conda_channels=${3:-$CONDA_CHANNELS}

conda env list | grep $conda_env_name

if [ $? -eq 1 ]; then
  # conda environment doesn't exist, create it
  if [ ! -z ${conda_channels+x} ]; then
    channels="-c $conda_channels"
  fi
  conda create -y $channels -n $conda_env_name $conda_packages
fi
# we currently trust that if the environment with that name is created, then it contains what we need.
