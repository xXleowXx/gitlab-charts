---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Operator **(FREE SELF)**

GitLab Operator is an implementation of the [Operator pattern](https://www.openshift.com/blog)
for managing the lifecycle and upgrades of a GitLab instance. The GitLab Operator strengthens the support of OpenShift from GitLab, but is intended to be as native to Kubernetes as for OpenShift. The GitLab Operator provides a method of synchronizing and controlling various
stages of cloud-native GitLab installation/upgrade procedures. Using the Operator provides the ability to perform
rolling upgrades with minmal down time. The first goal is to support OpenShift, the subsequent goal will be for automation of day 2 operations like upgrades as noted.

The Operator offers the benefit of Day 2 operators to the GitLab installation, there are many automation benefits to utilizing the Operator vs Helm. The Operator utilizes the Helm Chart but the Operator will continously run making upgrading, backups, and more, automatic.

A GitLab Operator is now generally available. The documentation can be found in the [GitLab Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/tree/master/doc) project. To see what we are planning next for the operator please view our [next release epic](https://gitlab.com/groups/gitlab-org/cloud-native/-/epics/23).

The GitLab operator aims to manage the full lifecycle of GitLab instances in your Openshift container platforms.

The operator aims to:

* ease installation and configuration of GitLab instances
* offer seamless upgrades from version to version
* ease backup and restore of GitLab and its components
* aggregate and visualize metrics using Prometheus and Grafana
* setup auto-scaling

Note that this does not include the GitLab Runner. For more inforation, see the [GitLab Runner Operator repository](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator).

## Known limitations

Below are known limitations of the GitLab Operator.

### Multiple instances of Webservice not supported on OpenShift

Multiple Webservice instances are problematic on OpenShift. The Ingresses report "All hosts are taken by other resources" when using NGINX Ingress Operator.

Related: [#160](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/issues/160)

### Certain components not supported

Below is a list of unsupported components:

- Praefect: [#136](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/issues/136)
- KAS: [#139](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/issues/139)

# Installation

This document describes how to deploy the GitLab operator via manifests in your Kubernetes or OpenShift cluster.

If using OpenShift, these steps normally are handled by OLM (the Operator Lifecycle Manager) once an operator is bundle published. However, to test the most recent operator images, users may need to install the operator using the deployment manifests available in the operator repository.

## Prerequisites

1. [Create or use an existing Kubernetes or OpenShift cluster](#cluster)
2. Install pre-requisite services and software
    - [Ingress controller](#ingress-controller)
    - [Certificate manager](#tls-certificates)
    - [Metrics server](#metrics)
3. [Configure Domain Name Services](#configure-domain-name-services)

### Cluster

#### Kubernetes

To create a traditional Kubernetes cluster, consider using [official tooling](https://kubernetes.io/docs/tasks/tools/) or your preferred method of installation.

#### OpenShift

To create an OpenShift cluster, see the [OpenShift cluster setup docs](openshift-cluster-setup.md).

### Ingress controller

An ingress controller is required to provide external access to the application and secure communication between components.

The GitLab Operator will deploy our [forked NGINX chart from the GitLab Helm Chart](charts/charts/nginx.md) by default.

If you prefer to use an external ingress controller, we recommend [NGINX Ingress](https://kubernetes.github.io/ingress-nginx/deploy/) by the Kubernetes community to deploy an Ingress Controller. Follow the relevant instructions in the link based on your platform and preferred tooling. Take note of the ingress class value for later (it typically defaults to `nginx`).

When configuring the GitLab CR, be sure to set `nginx-ingress.enabled=false` to disable the NGINX objects from the GitLab Helm Chart.

### TLS certificates

We recommend [Cert Manager](https://cert-manager.io/docs/installation/) to create certificates used to secure the GitLab and Registry URLs. Follow the relevant instructions in the link based on your platform and preferred tooling.

### Metrics

#### Kubernetes

Install the [metrics server](https://github.com/kubernetes-sigs/metrics-server#installation) so the HorizontalPodAutoscalers can retrieve pod metrics.

#### OpenShift

OpenShift ships with [Prometheus Adapter](https://docs.openshift.com/container-platform/4.6/monitoring/understanding-the-monitoring-stack.html#default-monitoring-components_understanding-the-monitoring-stack) by default, so there is no manual action required here.

### Configure Domain Name Services

You will need an internet-accessible domain to which you can add a DNS record.

See our [networking and DNS documentation](charts/installation/deployment.html#networking-and-dns.md) for more details on connecting your domain to the GitLab components. You will use the configuration mentioned in this section when defining your GitLab custom resource (CR).

## Installing the GitLab Operator

1. Deploy the GitLab Operator.

    ```
    $ GL_OPERATOR_VERSION=0.0.1
    $ kubectl create namespace gitlab-system
    $ kubectl apply -f https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${GL_OPERATOR_VERSION}.yaml
    ```
    
    or more verbose (note double quotes):

    ```
    $ GL_OPERATOR_VERSION=0.0.1
    $ kubectl create namespace gitlab-system
    $ kubectl apply -f "https://gitlab.com/api/v4/projects/gitlab-org%2Fcloud-native%2Fgitlab-operator/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${GL_OPERATOR_VERSION}.yaml"
    ```

    This command first deploys the service accounts, roles and role bindings used by the operator, and then the operator itself.

  Note: by default, the Operator will only watch the namespace where it is deployed. If you would like it to watch at the cluster scope, modify [config/manager/kustomization.yaml](../config/manager/kustomization.yaml) by commenting out the `namesapce_scope.yaml` patch.

2. Create a GitLab custom resource (CR).

   Create a new file named something like `mygitlab.yaml`.

   Here is an example of the content to put in this file:

   ```YAML
   apiVersion: apps.gitlab.com/v1beta1
   kind: GitLab
   metadata:
     name: example
   spec:
     chart:
       version: "X.Y.Z" # select a version from the CHART_VERSIONS file in the root of this project
       values:
         global:
           hosts:
             domain: example.com # use a real domain here
           ingress:
             configureCertmanager: true
         certmanager-issuer:
           email: youremail@example.com # use your real email address here
   ```

   For more details on configuration options to use under `spec.chart.values`, see our [GitLab Helm Chart documentation](charts.md).

3. Deploy a GitLab instance using your new GitLab CR.

   ```
   $ kubectl -n gitlab-system apply -f mygitlab.yaml
   ```

   This command sends your GitLab CR up to the cluster for the GitLab Operator to reconcile. You can watch the progress by tailing the logs from the controller pod:

   ```
   $  kubectl -n gitlab-system logs deployment/gitlab-controller-manager -c manager -f
   ```

   You can also list GitLab resources and check their status:

   ```
   $ kubectl get gitlabs -n gitlab-system
   ```

   When the CR is reconciled (the status of the GitLab resource will be `RUNNING`), you can access GitLab in your browser at `https://gitlab.example.com`.

## Uninstall the GitLab Operator

Follow the steps below to remove the GitLab Operator and its associated resources.

Items to note prior to uninstalling the operator:

- The operator does not delete the Persistent Volume Claims or Secrets when a GitLab instance is deleted.
- When deleting the Operator, the namespace where it is installed (`gitlab-system` by default) will not be deleted automatically. This is to ensure persistent volumes are not lost unintentionally.

### Uninstall an instance of GitLab

```
$ kubectl -n gitlab-system delete -f mygitlab.yaml
```

This will remove the GitLab instance, and all associated objects except for (PVCs as noted above).

### Uninstall the GitLab Operator


```
$ GL_OPERATOR_VERSION=0.0.1
$ kubectl delete -f https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${GL_OPERATOR_VERSION}.yaml
```

More verbose version of above is (note double quotes):

```
$ GL_OPERATOR_VERSION=0.0.1
$ kubectl delete -f "https://gitlab.com/api/v4/projects/gitlab-org%2Fcloud-native%2Fgitlab-operator/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${GL_OPERATOR_VERSION}.yaml"
```


This will delete the Operator's resources, including the running Deployment of the Operator. This **will not** delete objects associated with a GitLab instance.
