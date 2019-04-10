#!/usr/bin/env bash

conda_env_name=${CONDA_ENV:-$1}
conda_packages=${CONDA_PACKAGES:-$2}

conda env list | grep $conda_env_name

if [ $? -eq 1 ]; then
  # conda environment doesn't exist, create it
  conda create -y -n $conda_env_name $conda_packages
fi
# we currently trust that if the environment with that name is created, then it contains what we need.
