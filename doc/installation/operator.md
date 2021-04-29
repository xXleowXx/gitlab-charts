---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Operator

GitLab Operator is an implementation of the [Operator pattern](https://www.openshift.com/blog)
for managing the lifecycle and upgrades of a GitLab instance. The GitLab Operator strengthens the support of OpenShift from GitLab, but is intended to be as native to Kubernetes as for OpenShift. The GitLab Operator provides a method of synchronizing and controlling various
stages of cloud-native GitLab installation/upgrade procedures. Using the Operator provides the ability to perform
rolling upgrades with minmal down time.

WARNING:
This functionality was Alpha and marked experimental. It is now [**deprecated**](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2210).

The prior [GitLab Operator](https://gitlab.com/gitlab-org/charts/components/gitlab-operator) was developed, but never passed alpha status or recommended for use. That operator is now deprecated, should not be used, and will be removed in the future.

A new GitLab Operator is currently in development and will soon be released into beta. More information can be found in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/3444).

Additionally, a [GitLab Runner-specific Operator](https://docs.gitlab.com/runner/install/openshift.html) is generally available, allowing users to easily run GitLab CI jobs in OpenShift.
