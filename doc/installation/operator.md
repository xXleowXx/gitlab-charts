# GitLab Operator

GitLab operator is an implementation of the [Operator pattern](https://coreos.com/blog/introducing-operators.html) for management of deployment lifecycle. This component provides a method of synchronizing and controlling various stages of cloud-native GitLab installation/upgrade procedures. Using the operator provides the ability to perform rolling upgrades without down time.

## Operator chart

We provide an [operator chart](https://gitlab.com/charts/gitlab/tree/master/charts/gitlab/charts/operator) for installing the operator. If enabled, the operator will assume control of the upgrade process that was previously managed via [Helm hooks](https://docs.helm.sh/developing_charts/#hooks).

### Enabling the operator

We provide the flag `global.operator.enabled`, when set to true it enables the operator and allows it to manage resources.

## Installing using the operator

The operator makes use of Kubernetes CustomResourceDefinitions (CRD). Therefore, you need cluster level privilege to install
it. Please note that this privilege is only required for CRD installation. The operator itself does not mandate it.

Simply run `helm upgrade --install <release-name> . --set global.operator.enabled=true ... ` where `...` shall be replaced by the rest of the values you would like to set. Along with everything else, this command will install the CRD, GitLab custom resource, and the operator.

**NOTE:** When the operator is enabled you can not use `--no-hooks` and `--wait` flags. Otherwise it will fail the installation.

**NOTE:** Test new versions of the operator by setting `gitlab.operator.image.tag` to either the branch name of a gitlab-operator container build or a specific tagged release number.

**NOTE:** The operator is transitioning from a ClusterRole to a regular Role that operates within a namespace. Operator containers after version 0.4 will have this new behavior by default.

**NOTE:** When the operator is enabled the CRD is managed automatically. It's this particular piece that requires cluster-level privileges. If you need/want to manage CRD installation without Helm, e.g. due to restrictions on cluster-level roles, you can disable automatic CRD management by setting `gitlab.operator.crdManager.enabled` to 
`false`.