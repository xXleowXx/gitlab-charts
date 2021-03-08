---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab Operator

GitLab Operator is an implementation of the [Operator pattern](https://www.openshift.com/blog)
for management of deployment lifecycle. This component provides a method of synchronizing and controlling various
stages of cloud-native GitLab installation/upgrade procedures. Using the Operator provides the ability to perform
rolling upgrades without down time.

Notice:

The previous Operator project gitlab/gitlab-operator helm chart is now [**deprecated**](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2210), and will be removed in the future. Do not use in production.


A new GitLab Operator is currently in development, working towards beta release. Progress on the development can be found in this [issue](https://gitlab.com/groups/gitlab-org/-/epics/3444)


The GitLab Runner Operator is currently in production, and can be found [here](https://docs.gitlab.com/runner/install/openshift.html)
