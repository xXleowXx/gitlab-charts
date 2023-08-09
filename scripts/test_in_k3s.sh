#!/bin/bash

curl -f k3s:8081?service=k3s > kubeconfig
export KUBECONFIG=kubeconfig

kubectl version
kubectl cluster-info

source scripts/ci/autodevops.sh
ensure_namespace
create_secret
deploy
wait_for_deploy
