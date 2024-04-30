---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Workload Identity Federation for GKE using the GitLab chart

The default configuration for external object storage in the charts uses
secret keys. [Workload Identity Federation for GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)
makes it possible to grant access to object storage to the Kubernetes cluster using short-lived
tokens. If you have an existing GKE cluster, read the [Google documentation on how to update the node pool to use Workload Identity Federation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#option_2_node_pool_modification).

## Troubleshooting

You can check whether Workload Identity is configured properly by
querying the metadata endpoint inside the toolbox pod. The service
account associated with the cluster should be returned:

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email
example@your-example-project.iam.gserviceaccount.com
```

This account should also be able to access the following scopes:

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/scopes
https://www.googleapis.com/auth/cloud-platform
https://www.googleapis.com/auth/userinfo.email
```
