---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Migrating from Helm v2 to Helm v3

You can use [Helm 2to3 plugin](https://github.com/helm/helm-2to3) to migrate Helm 2 GitLab releases to
Helm 3:

```shell
helm 2to3 convert YOUR-GITLAB-RELEASE
```

## Known Issues

After migration the **subsequent upgrades may fail** with an error similar to the following:

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind Deployment: Deployment.apps "..." is invalid: spec.selector:
Invalid value: v1.LabelSelector{...}: field is immutable
```

or

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind StatefulSet: StatefulSet.apps "..." is invalid:
spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', and 'updateStrategy' are forbidden
```

This is due to known issues with Helm 2 to 3 migration in [Cert Manager](https://github.com/jetstack/cert-manager/issues/2451)
and [Redis](https://github.com/bitnami/charts/issues/3482) dependencies. In a nutshell, the `heritage` label
on some Deployments and StatefulSets are immutable and can not be changed from `Tiller` (set by Helm 2) to `Helm`
(set by Helm 3). So they must be replaced _forcefully_.

To work around this use the following instructions:

NOTE: **Note:**
These instructions _forcefully replace resources_, notably Redis StatefulSet.
You need to ensure that the attached data volume to this StatefulSet is safe and remains intact.

1. Replace cert-manager Deployments (when enabled).

```shell
kubectl get deployments -l app=cert-manager -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
kubectl get deployments -l app=cainjector -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
```

1. (Optional) Set `persistentVolumeReclaimPolicy` to `Retain` on the PV that is claimed by Redis StatefulSet.
   This is to ensure that the PV won't be deleted inadvertently.

```shell
kubectl patch pv <PV-NAME> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

1. Set `heritage` label of the existing Redis PVC to `Helm`.

```shell
kubectl label pvc -l app=redis --overwrite heritage=Helm
```

1. Replace Redis StatefulSet **without cascading**.

```shell
kubectl get statefulsets.apps -l app=redis -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true --cascade=false -f -
```
