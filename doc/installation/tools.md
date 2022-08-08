---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Prerequisites for installing the GitLab chart **(FREE SELF)**

Before you deploy GitLab in a Kubernetes cluster, install these prerequisites.

## `kubectl`

Install `kubectl` 1.16 or later by following [the Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/#kubectl).

The version you install must be within one minor release of
[the version running in your cluster](https://kubernetes.io/docs/tasks/tools/).

## Helm

Install Helm v3.3.1 or later by following [the Helm documentation](https://helm.sh/docs/intro/install/).

## Next steps

[Prepare your Kubernetes cluster](cloud/index.md).
