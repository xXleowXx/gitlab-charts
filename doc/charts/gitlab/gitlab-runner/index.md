# Using the gitlab-runner chart

The gitlab-runner subchart provides a gitlab runner for running CI jobs. It is enabled
by default and should work out of the box with support for caching using s3 compatible
object storage.

## Requirements

This chart depends on the shared-secrets subchart to populate its `registrationToken`
for automatic registration. If you intend to run this chart as a stand-alone chart
with an existing gitlab instance, you will need to manually set the `registrationToken`
in the `gitlab-runner` secret to be equal to that displayed by the running gitlab instance.

## Configuration

There are no required settings, it should work out of the box if you deploy all of
the charts together.

## Deploying a stand-alone runner

By default we infer `gitlabUrl`, automatically generate a registration token, and
generate it through the `migrations` chart.

That behaviour will not work if you intend to deploy it with an already running gitlab
instance. In this case you will need to set the `gitlabUrl` value to be the url of
the running gitlab instance. You will also need to manually create the `gitlab-runner`
secret and fill it with the `registrationToken` provided by the running gitlab.

## Using docker-in-docker

In order to run docker-in-docker, the runner container needs to be set as privileged
to have access to the needed capabilities. To enable it set the `privileged` value to `true`.

CAUTION: **Caution:** Privileged containers have extended capabilities, for example they
can mount arbitrary files from the host they run on. Make sure to run the container
in an isolated environment, such that nothing important runs beside it.

## Installation command line options

| Parameter                                      | Default         | Description                                |
| ---------------------------------------------- | --------------- | ------------------------------------------ |
| `gitlab-runner.checkInterval`                  | `30s`           | polling interval                           |
| `gitlab-runner.concurrent`                     | `20`            | number of concurrent jobs                  |
| `gitlab-runner.image`                          | `gitlab/gitlab-runner:alpine-v10.5.0` | runner image         |
| `gitlab-runner.imagePullPolicy`                | `IfNotPresent`  | image pull policy                          |
| `gitlab-runner.init.image`                     | `busybox`       | initContainer image                        |
| `gitlab-runner.init.tag`                       | `latest`        | initContainer image tag                    |
| `gitlab-runner.install`                        | `true`          |                                            |
| `gitlab-runner.pullSecrets`                    |                 | Secrets for the image repository           |
| `gitlab-runner.rbac.clusterWideAccess`         | `false`         | deploy containers of jobs cluster-wide     |
| `gitlab-runner.rbac.create`                    | `true`          | whether to create rbac service account     |
| `gitlab-runner.rbac.serviceAccountName`        | `default`       | name of the rbac service account to create |
| `gitlab-runner.resources.limits.cpu`           |                 | runner cpu limit                           |
| `gitlab-runner.resources.limits.memory`        |                 | runner memory limit                        |
| `gitlab-runner.resources.requests.cpu`         |                 | runner requested cpu                       |
| `gitlab-runner.resources.requests.memory`      |                 | runner requested memory                    |
| `gitlab-runner.runners.build.cpuLimit`         |                 | build container limit                      |
| `gitlab-runner.runners.build.cpuRequests`      |                 | build container limit                      |
| `gitlab-runner.runners.build.memoryLimit`      |                 | build container limit                      |
| `gitlab-runner.runners.build.memoryRequests`   |                 | build container limit                      |
| `gitlab-runner.runners.cache.cacheShared`      | `true`          | share the cache between runners            |
| `gitlab-runner.runners.cache.cacheType`        | `s3`            | cache type                                 |
| `gitlab-runner.runners.cache.s3BucketLocation` | `us-east-1`     | bucket region                              |
| `gitlab-runner.runners.cache.s3BucketName`     | `runner-cache`  | name of the bucket                         |
| `gitlab-runner.runners.cache.s3CacheInsecure`  | `false`         | use http                                   |
| `gitlab-runner.runners.cache.s3CachePath`      | `gitlab-runner` | path in the bucket                         |
| `gitlab-runner.runners.cache.secretName`       | `gitlab-minio`  | secret to access key and secretkey from    |
| `gitlab-runner.runners.image`                  | `ubuntu:16.04`  | default container image to use in builds   |
| `gitlab-runner.runners.imagePullSecrets`       | `[]`            | imagePullSecrets                           |
| `gitlab-runner.runners.namespace`              | `default`       | numespace to run jobs in                   |
| `gitlab-runner.runners.privileged`             | `false`         | run in privileged mode, needed for `dind`  |
| `gitlab-runner.runners.service.cpuLimit`       |                 | service container limit                    |
| `gitlab-runner.runners.service.cpuRequests`    |                 | service container limit                    |
| `gitlab-runner.runners.service.memoryLimit`    |                 | service container limit                    |
| `gitlab-runner.runners.service.memoryRequests` |                 | service container limit                    |
| `gitlab-runner.unregisterRunners`              | `true`          | unregister all runners before termination  |

## Chart configuration examples

### gitlab-runner.pullSecrets

`pullSecrets` allows you to authenticate to a private registry to pull images for a pod.

Additional details about private registries and their authentication methods can be
found in [the Kubernetes documentation](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Below is an example use of `pullSecrets`

```YAML
image: my.runner.repository
imagePullPolicy: Always
pullSecrets:
- name: my-secret-name
- name: my-secondary-secret-name
```
