# GitLab Operator

GitLab operator is an implementation of the [Operator pattern](https://coreos.com/blog/introducing-operators.html) for management of deployment lifecycle. This component provides a method of synchronizing and controlling various stages of cloud-native GitLab installation/upgrade procedures. Using the operator provides the ability to perform rolling upgrades without down time.

## Operator chart

We provide an [operator chart](https://gitlab.com/charts/gitlab/tree/master/charts/gitlab/charts/operator) for installing the operator. If enabled, the operator will assume control of the upgrade process that was previously managed via [Helm hooks](https://docs.helm.sh/developing_charts/#hooks).

### Enabling the operator

NOTE: **Note**: This requires helm 2.12.3 or newer

We provide the flag `global.operator.enabled`, when set to true it enables the operator, installs the necessary CRDs and allows it to manage resources.
