---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Installing GitLab using Helm **(FREE SELF)**

Install GitLab on Kubernetes with the cloud native GitLab Helm chart.

## Helm chart only deployment creates a POC configuration

Installing GitLab using only the Helm charts creates a POC implementation where all GitLab services are placed into the cluster. GitLab Cloud Native Hybrid Reference Architectures specify that the stateful components such as Postgres or Gitaly (Git Repository Storage dataplane) run outside the cluster on PaaS or instance compute. This is required in order to scale and reliably service the many varieties of workloads found in production environments. Additionally, it is allowable, and generally preferable to take advantage of Cloud PaaS for PostgreSQL, Redis and Object storage for all non Git Repository storages.

## Helm charts are configurable to externalize stateful components
There in only one set of GitLab Helm charts and they can be parameterized to point to external stateful storage for items such as the PostgreSQL, Redis, all Non-Git repository storage as well as Git repository storage (Gitaly). The Infrastructure as Code options below use this approach. For production-grade implementation by hand build or via custom IaC, the appropriate chart parameters should be used to point to prebuilt, externalized state stores that align with the choosen [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures).

## Getting started for production Cloud Native Hybrid

The Reference Architecture for deploying GitLab instances to Kubernetes is called Cloud Native Hybrid specifically because not all GitLab services can run in the cluster for production-grade implementations. Each Cloud Native Hybrid Reference Architecture is detailed within the overall architecture page. For instance, here is the [Cloud Native Hybrid reference architecture](https://docs.gitlab.com/ee/administration/reference_architectures/3k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) alternative for the 3,000 user count.

## GitLab deployment with Infrastructure as Code (IaC)

GitLab develops Infrastructure as Code IaC that is capable of configuring the combination of Helm charts and supplemental cloud infrastructure via the [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit). For AWS a second option is the [AWS Quick Start](https://docs.gitlab.com/ee/install/aws/gitlab_hybrid_on_aws.html#available-infrastructure-as-code-for-gitlab-cloud-native-hybrid). Regardless of how you are building Cloud Native Hybrid, there is AWS specific guidance and bills of materials in the implementation pattern [Provision GitLab Cloud Native Hybrid on AWS EKS](https://docs.gitlab.com/ee/install/aws/gitlab_hybrid_on_aws.html)

## Requirements

To deploy GitLab on Kubernetes, the following are required:

1. kubectl `1.16` or higher, compatible with your cluster
   ([+/- 1 minor release from your cluster](https://kubernetes.io/docs/tasks/tools/)).
1. Helm v3 (3.3.1 or higher).
1. A Kubernetes cluster, version 1.16 through 1.21. 8vCPU and 30GB of RAM is recommended.

    - Please refer to our [Cloud Native Hybrid reference architectures](https://docs.gitlab.com/ee/administration/reference_architectures/#available-reference-architectures) for the cluster topology recommendations for the specific environment sizes.

NOTE:
If using the in-chart NGINX Ingress Controller (`nginx-ingress.enabled=true`),
then Kubernetes 1.19 or newer is required.

NOTE:
Support for Kubernetes 1.22 is under active development - see
[&6883](https://gitlab.com/groups/gitlab-org/-/epics/6883) for more information.

NOTE:
Helm v2 has reached end of lifecyle. If GitLab has been previously installed
with Helm v2, you should use Helm v3 as soon as possible. Please consult
the [Helm migration document](migration/helm.md).

## Environment setup

Before proceeding to deploying GitLab, you need to prepare your environment.

### Tools

`helm` and `kubectl` need to be [installed on your computer](tools.md).

### Cloud cluster preparation

NOTE:
[Kubernetes 1.16 through 1.21 is required](#requirements), due to the usage of certain
Kubernetes features.

Follow the instructions to create and connect to the Kubernetes cluster of your
choice:

- [Amazon EKS](cloud/eks.md)
- [Azure Kubernetes Service](cloud/aks.md)
- [Google Kubernetes Engine](cloud/gke.md)
- [OpenShift](cloud/openshift.md)
- [Oracle Container Engine for Kubernetes](cloud/oke.md)
- VMware Tanzu - Documentation to be added.
- On-Premises solutions - Documentation to be added.

## Deploying GitLab

With the environment set up and configuration generated, you can now proceed to
the [deployment of GitLab](deployment.md).

## Upgrading GitLab

If you are upgrading an existing Kubernetes installation, follow the
[upgrade documentation](upgrade.md) instead.

## Migrate from or to the GitLab Helm chart

To migrate your existing GitLab Linux package installation to your Kubernetes cluster,
or vice versa, follow the [migration documentation](migration/index.md).
