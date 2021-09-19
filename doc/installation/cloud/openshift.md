---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Installing GitLab on OpenShift

## GitLab Operator

The recommended method for installing GitLab on OpenShift is by using the GitLab Operator.

The GitLab operator aims to manage the full lifecycle of GitLab instances in your Openshift container platforms.
The operator aims to:

* ease installation and configuration of GitLab instances
* offer seamless upgrades from version to version
* ease backup and restore of GitLab and its components
* aggregate and visualize metrics using Prometheus and Grafana
* setup auto-scaling

Note that this does not include the GitLab Runner. The GitLab Runner is a lightweight, highly-scalable agent that picks up a CI job through the coordinator API of GitLab CI/CD, runs the job, and sends the result back to the GitLab instance. If you would like to use Runners to pick up CI jobs in your OpenShift apps, and host GitLab outside of an OpenShift cluster see more information on [installing GitLab Runners](https://docs.gitlab.com/runner/). For more inforation on the GitLab Runner Operator, see the [GitLab Runner Operator repository](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/blob/master/README.md).

If you do not current have an OpenShift cluster, you can check out this guide to [setup and OpenShift cluster](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/blob/master/doc/openshift-cluster-setup.md).

## Known Limitations

The GitLab Operator is still being developed so before getting started here are a few known limitations.

### Object storage must use in-cluster MinIO

Currently, the Operator deploys an in-cluster instance of MinIO. This instance must be used for object storage. External object storage providers are not supported at this time.

Related: [#137](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues/137)

### Multiple instances of Webservice, Sidekiq, or Gitaly are not supported

In the GitLab Helm chart, multiple instances of Webservice, Sidekiq, and Gitaly are supported.

The Operator only expects one instance of these components at this time.

Related: [#128](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues/128)

### Installation assumes an OpenShift environment

Portions of the documenation, scripts, and code assume an OpenShift environment.
The plan is for the GitLab Operator to be supported on both OpenShift and "vanilla"
Kubernetes environments.

Progress toward proper support for "vanilla" Kubernetes environments can be tracked
in [#119](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues/119).

### Certain components not supported

Below is a list of unsupported components:

- GitLab Shell [#58](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues/58) is unable to provide SSH access.
- Praefect: [#136](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues/136)
- Pages: [#138](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues/138)
- KAS: [#139](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues/139)
- Mailroom: [#140](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues/140)

# Installing operator from source

This document describes how to deploy the GitLab operator via manifests in your Kubernetes or Openshift cluster.

These steps normally are handled by OLM, the Operator Lifecycle Manager, once an operator is bundle published. However, to test the most recent operator images, users may need to install the operator using the deployment manifests available in the operator repository.

## Requirements

0. Create an OpenShift cluster, see [openshift-cluster-setup.md](openshift-cluster-setup.md).

1. Clone the GitLab operator repository to your local system

    ```
    $ git clone https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator.git
    $ cd gitlab-operator
    ```

2. Ensure the operators it depends on are present. These operators can be installed via the in-cluster OperatorHub or via Make:

   ```
   $ make install_required_operators
   ```

   The GitLab operator uses the following operators:
   * the `Nginx Ingress Operator` by Nginx Inc. to deploy and Ingress Controller. This should be deployed from operatorhub.io if using Kubernetes or the embedded Operator Hub on OpenShift environments

   * the `Cert Manager operator` to create certificates used to secure the GitLab and Registry urls. Once this operator has been installed, create a cert-manager instance. Use default "cert-manager" for the Name field, the Labels field can be blank.


3. Deploy the CRDs(Custom Resource Definitions) for the resources managed by the operator

    ```
    $ make install_crds
    ```

4. Deploy the operator

    ```
    $ make deploy_operator
    ```

    This command first deploys the service accounts, roles and role bindings used by the operator, and then the operator itself.

5. Create a GitLab custom resource (CR)

   Create a new file to specify settings for an instance of GitLab. Name it something like `mygitlab.yaml`.

   Here is an example of the content to put in this file:

   ```yaml
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
             class: nginx # ensure this matches the ingress class defined within the NGINX ingress controller
             configureCertmanager: true
         certmanager-issuer:
           email: youremail@example.com # use your real email address here
   ```

6. Deploy a GitLab instance

   ```
   $ kubectl -n gitlab-system apply -f mygitlab.yaml
   ```

   This command sends your GitLab CR up to the cluster for the GitLab Operator to reconcile. You can watch the progress by tailing the logs from the controller pod:

   ```
   $  kubectl -n gitlab-system logs deployment/gitlab-controller-manager -c manager -f
   ```

   When the CR is reconciled, you can access GitLab in your browser at `https://gitlab.example.com`.

7. Clean up

   The operator does not delete the persistent volume claims that hold the stateful data when a GitLab instance is deleted. Therefore, remember to delete any lingering volumes.

   When deleting the Operator, the namespace where it is installed (`gitlab-system` by default) will not be deleted automatically. This is to ensure persistent volumes are not lost unintentionally.

   ```
   $ kubectl -n gitlab-system delete -f mygitlab.yaml
   $ make delete_operator
   $ make uninstall_crds
   $ make uninstall_required_operators
   ```

# Upgrading the Operator

Below are instructions to upgrade the GitLab Operator.

## Step 1: Identify the desired version of the Operator

To use a released version, the tags will look something like `vX.Y.Z-betaN`. See our
[tags](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/tags) for the full list.

If you wish to use a development version, you can find the commit on `master` that you'd like to use,
and copy the first 8 characters of that commit SHA. This aligns with the tag we apply to each
image built in the `master` pipelines (using `$CI_COMMIT_SHORT_SHA`).

Picking a specific SHA or tag is more reliable than using the `latest` tag, which is overridden with each commit to `master`.

Note that by default, the Operator deployment manifest specifies `imagePullPolicy=Always`. This ensures that if the tag
`latest` is used, deleting the pod will pull `latest` again and pull in the latest version of the image under that tag.

## Step 2: Update the Operator deployment with the desired version

The next step is to instruct the Operator deployment to use the desired version of the Operator image. This can be done
multiple ways - the simplest would be to run:

```
TAG=abcd1234 make deploy_operator
```

This will instruct `kustomize` to patch the [Operator deployment manifest](../config/manager/manager.yaml) with the desired
tag and send that Deployment manifest to the cluster.

Alternatively, you can edit the Deployment in the cluster directly and enter the desired image tag.

## Step 3: Confirm that the new version of the Operator becomes the leader

The Deployment should create a new ReplicaSet with this change, which will spawn a new Operator pod. Meanwhile, the previous
Operator pod will start to shut down, giving up its leader status. When this happens, the new Operator pod will become the leader.

If the new version of the Operator contains updated logic, you should see it start taking action on the resources in the namespace.

Keep an eye on the logs from the new Operator pod. If you notice any errors, check our
[issue tracker](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/issues) to see if the issue is known. If not,
open a new issue.

# More Information

If you would like to know more about [versioning and release info](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/blob/master/doc/security-context-constraints.md), [design decisions](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/blob/master/doc/design-decisions.md), [security context restraints](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/blob/master/doc/security-context-constraints.md), and a [developer guide](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/blob/master/developer-guide.md), please visit the [docs](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/tree/master/doc).
