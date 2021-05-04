---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Operator

GitLab Operator is an implementation of the [Operator pattern](https://www.openshift.com/blog)
for managing the lifecycle and upgrades of a GitLab instance. The GitLab Operator strengthens the support of OpenShift from GitLab, but is intended to be as native to Kubernetes as for OpenShift. The GitLab Operator provides a method of synchronizing and controlling various
stages of cloud-native GitLab installation/upgrade procedures. Using the Operator provides the ability to perform
rolling upgrades with minmal down time. The first goal is to support OpenShift, the subsequent goal will be for automation of day 2 operations like upgrades as noted.

A new GitLab Operator is currently in development and has been released into beta. More information can be found in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/3444), and the documentation can be found in the [GitLab Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-operator/-/tree/master/doc) repo. 

The GitLab operator aims to manage the full lifecycle of GitLab instances in your Kubernetes or Openshift container platforms.
While new and still actively being developed, the operator aims to:

* ease installation and configuration of GitLab instances
* offer seamless upgrades from version to version
* ease backup and restore of GitLab and its components
* aggregate and visualize metrics using Prometheus and Grafana
* setup auto-scaling

Additionally, a [GitLab Runner-specific Operator](https://docs.gitlab.com/runner/install/openshift.html) is generally available, allowing users to easily run GitLab CI jobs in OpenShift.
