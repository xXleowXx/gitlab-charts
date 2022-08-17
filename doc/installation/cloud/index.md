---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Preparation for installing on cloud based providers **(FREE SELF)**

A Kubernetes cluster, version 1.16 through 1.21 is required due to the usage of certain
Kubernetes features. 8vCPU and 30GB of RAM is recommended.
Support for Kubernetes 1.22 is under active development, see
[&6883](https://gitlab.com/groups/gitlab-org/-/epics/6883) for more information.

Refer to the [Cloud Native Hybrid reference architectures](https://docs.gitlab.com/ee/administration/reference_architectures/#available-reference-architectures) for cluster topology recommendations for an environment.

NOTE:
If using the in-chart NGINX Ingress Controller (`nginx-ingress.enabled=true`),
then Kubernetes 1.19 or newer is required.

Create and connect to the Kubernetes cluster in the environment you choose:

- [Azure Kubernetes Service](aks.md)
- [Amazon EKS](eks.md)
- [Google Kubernetes Engine](gke.md)
- [OpenShift](openshift.md)
- [Oracle Container Engine for Kubernetes](oke.md)
