#!/bin/bash

# Checks that appropriate gke params are set and
# that gcloud and kubectl are properly installed and authenticated
function need_tool(){
  local tool="${1}"
  local url="${2}"

  echo >&2 "${tool} is required. Please follow ${url}"
  exit 1
}

function need_gcloud(){
  need_tool "gcloud" "https://cloud.google.com/sdk/downloads"
}

function need_kubectl(){
  need_tool "kubectl" "https://kubernetes.io/docs/tasks/tools/install-kubectl"
}

function need_helm(){
  need_tool "helm" "https://github.com/helm/helm/#install"
}

function need_eksctl(){
  need_tool "eksctl" "https://eksctl.io"
}

function need_az(){
  need_tool "az" "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
}

function need_jq(){
  need_tool "jq" "https://stedolan.github.io/jq/download/"
}

function validate_tools(){
  for tool in "$@"
  do
    # Basic check for installation
    command -v "${tool}" > /dev/null 2>&1 || "need_${tool}"

    # Additional  checks if validating gcloud binary
    if [ "$tool" == 'gcloud' ]; then
      if [ -z "$PROJECT" ]; then
        echo "\$PROJECT needs to be set to your project id";
        exit 1;
      fi

      gcloud container clusters list --project $PROJECT >/dev/null 2>&1 || { echo >&2 "Gcloud seems to be configured incorrectly or authentication is unsuccessfull"; exit 1; }
    fi
  done
}

function check_helm_3(){
  set +e
  helm version --short --client | grep -q '^v3\.[0-9]\{1,\}'
  IS_HELM_3=$?
  set -e

  echo $IS_HELM_3
}

function set_helm_name_flag(){

  IS_HELM_3=$(check_helm_3)

  if [[ "$IS_HELM_3" -eq "0" ]]; then
    name_flag=''
  else
    name_flag='--name'
  fi

  echo $name_flag
}

function set_helm_purge_flag(){

  IS_HELM_3=$(check_helm_3)

  if [[ "$IS_HELM_3" -eq "0" ]]; then
    purge_flag=''
  else
    purge_flag='--purge'
  fi

  echo $purge_flag
}

function cluster_admin_password_gke(){
  gcloud container clusters describe $CLUSTER_NAME --zone $ZONE --project $PROJECT --format='value(masterAuth.password)';
}

# Function to compare versions in a semver compatible way
# https://gist.github.com/Ariel-Rodriguez/9e3c2163f4644d7a389759b224bfe7f3
# Author Ariel Rodriguez
# License MIT
function semver_compare() {
  local version_a version_b pr_a pr_b
  # strip word "v" and extract first subset version (x.y.z from x.y.z-foo.n)
  version_a=$(echo "${1//v/}" | awk -F'-' '{print $1}')
  version_b=$(echo "${2//v/}" | awk -F'-' '{print $1}')

  if [ "$version_a" \= "$version_b" ]
  then
    # check for pre-release
    # extract pre-release (-foo.n from x.y.z-foo.n)
    pr_a=$(echo "$1" | awk -F'-' '{print $2}')
    pr_b=$(echo "$2" | awk -F'-' '{print $2}')

    ####
    # Return 0 when A is equal to B
    [ "$pr_a" \= "$pr_b" ] && echo 0 && return 0

    ####
    # Return 1

    # Case when A is not pre-release
    if [ -z "$pr_a" ]
    then
      echo 1 && return 0
    fi

    ####
    # Case when pre-release A exists and is greater than B's pre-release

    # extract numbers -rc.x --> x
    number_a=$(echo ${pr_a//[!0-9]/})
    number_b=$(echo ${pr_b//[!0-9]/})
    [ -z "${number_a}" ] && number_a=0
    [ -z "${number_b}" ] && number_b=0

    [ "$pr_a" \> "$pr_b" ] && [ -n "$pr_b" ] && [ "$number_a" -gt "$number_b" ] && echo 1 && return 0

    ####
    # Retrun -1 when A is lower than B
    echo -1 && return 0
  fi
  arr_version_a=(${version_a//./ })
  arr_version_b=(${version_b//./ })
  cursor=0
  # Iterate arrays from left to right and find the first difference
  while [ "$([ "${arr_version_a[$cursor]}" -eq "${arr_version_b[$cursor]}" ] && [ $cursor -lt ${#arr_version_a[@]} ] && echo true)" == true ]
  do
    cursor=$((cursor+1))
  done
  [ "${arr_version_a[$cursor]}" -gt "${arr_version_b[$cursor]}" ] && echo 1 || echo -1
}