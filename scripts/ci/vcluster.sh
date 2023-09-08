#!/bin/bash

function cluster_connect() {
  if [ -z ${AGENT_NAME+x} ] || [ -z ${AGENT_PROJECT_PATH+x} ]; then
    echo "No AGENT_NAME or AGENT_PROJECT_PATH set, using the default"
  else
    kubectl config get-contexts
    kubectl config use-context ${AGENT_PROJECT_PATH}:${AGENT_NAME}
  fi
}

function vcluster_create() {
  vcluster create ${VCLUSTER_NAME} \
    --upgrade \
    --namespace=${VCLUSTER_NAME} \
    --kubernetes-version=${VCLUSTER_K8S_VERSION} \
    --connect=false \
    --update-current=false
}

function vcluster_connect() {
  vcluster connect ${VCLUSTER_NAME}
}

function vcluster_deploy() {
  helm dependency update

  cat << CIVALUES > ci.yaml
  global:
    hosts:
      https: false
    image:
      pullPolicy: Always
    ingress:
      configureCertmanager: false
      tls:
        enabled: false
    appConfig:
      initialDefaults:
        signupEnabled: false
  gitlab:
    webservice:
      minReplicas: 1    # 2
      maxReplicas: 3    # 10
      resources:
        requests:
          cpu: 500m     # 900m
          memory: 1500M # 2.5G
    sidekiq:
      minReplicas: 1    # 1
      maxReplicas: 2    # 10
      resources:
        requests:
          cpu: 500m     # 900m
          memory: 1000M # 2G
    gitlab-shell:
      minReplicas: 1    # 2
      maxReplicas: 2    # 10
    toolbox:
      enabled: true
  gitlab-runner:
    certsSecretName: gitlab-wildcard-tls-chain
  certmanager:
    install: false
  nginx-ingress:
    controller:
      replicaCount: 1   # 2
  redis:
    resources:
      requests:
        cpu: 100m
  minio:
    resources:
      requests:
        cpu: 100m
CIVALUES

  helm upgrade --install \
    gitlab \
    --wait --timeout 600s \
    -f ci.yaml \
    .
}

function vcluster_delete() {
  vcluster delete ${VCLUSTER_NAME}
}
