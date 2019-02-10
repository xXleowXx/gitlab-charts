# Using the GitLab-Shell chart

The `gitlab-shell` sub-chart provides an SSH server configured for Git SSH access to GitLab.

## Requirements

This chart depends on access to Redis and Unicorn services, either as part of the
complete GitLab chart or provided as external services reachable from the Kubernetes
cluster this chart is deployed onto.

## Design Choices

In order to easily support SSH replicas, and avoid using shared storage for the ssh
authorized keys, we are using the SSH [AuthorizedKeysCommand](https://man.openbsd.org/sshd_config#AuthorizedKeysCommand)
to authenticate against GitLab's authorized keys endpoint. As a result, we don't persist
or update the AuthorizedKeys file within these pods.

## Configuration

The `gitlab-shell` chart is configured in two parts: [external services](#external-services),
and [chart settings](#chart-settings). The port exposed through Ingress is configured
with `global.shell.port`, and defaults to `22`.

## Installation command line options

| Parameter              | Description                              | Default                                        |
| ---------------------- | ---------------------------------------- | ---------------------------------------------- |
| annotations            | Pod annotations                          |                                                |
| enabled                | Shell enable flag                        | true                                           |
| extraContainers        | List of extra containers to include      |                                                |
| extraInitContainers    | List of extra init containers to include |                                                |
| extraVolumeMounts      | List of extra volumes mountes to do      |                                                |
| extraVolumes           | List of extra volumes to create          |                                                |
| hpa.targetAverageValue | Set the autoscaling target value         | 100m                                           |
| image.pullPolicy       | Shell image pull policy                  | Always                                         |
| image.pullSecrets      | Secrets for the image repository         |                                                |
| image.repository       | Shell image repository                   | registry.com/gitlab-org/build/cng/gitlab-shell |
| image.tag              | Shell image tag                          | latest                                         |
| init.image             | initContainer image                      | busybox                                        |
| init.tag               | initContainer image tag                  | latest                                         |
| redis.serviceName      | Redis service name                       | redis                                          |
| replicaCount           | Shell replicas                           | 1                                              |
| service.externalPort   | Shell exposed port                       | 22                                             |
| service.internalPort   | Shell internal port                      | 22                                             |
| service.name           | Shell service name                       | gitlab-shell                                   |
| service.type           | Shell service type                       | ClusterIP                                      |
| unicorn.serviceName    | Unicorn service name                     | unicorn                                        |

## Chart configuration examples

### image.pullSecrets

`pullSecrets` allows you to authenticate to a private registry to pull images for a pod.

Additional details about private registries and their authentication methods can be
found in [the Kubernetes documentation](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Below is an example use of `pullSecrets`:

```YAML
image:
  repository: my.shell.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### annotations

`annotations` allows you to add annotations to the gitlab-shell pods.

Below is an example use of `annotations`

```YAML
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## External Services

This chart should be attached the Unicorn service, and should also use the same Redis
as the attached Unicorn service.

### Redis

```YAML
redis:
  host: redis.example.com
  serviceName: redis
  port: 6379
  password:
    secret: gitlab-redis
    key: redis-password
```

| Name            | Type    | Default | Description |
|:----------------|:-------:|:--------|:------------|
| host            | String  |         | The hostname of the Redis server with the database to use. This can be omitted in lieu of `serviceName`. |
| password.key    | String  |         | The name of the key in the secret below that contains the password. |
| password.secret | String  |         | The name of the kubernetes `Secret` to pull from. |
| port            | Integer | `6379`  | The port on which to connect to the Redis server. |
| serviceName     | String  | `redis` | The name of the `service` which is operating the Redis database. If this is present, and `host` is not, the chart will template the hostname of the service (and current `.Release.Name`) in place of the `host` value. This is convenient when using Redis as a part of the overall GitLab chart. |

### Unicorn

```YAML
unicorn:
  host: unicorn.example.com
  serviceName: unicorn
  port: 8080
```

| Name        | Type    | Default   | Description |
|:------------|:-------:|:----------|:------------|
| host        | String  |           | The hostname of the Unicorn server. This can be omitted in lieu of `serviceName`. |
| port        | Integer | `8080`    | The port on which to connect to the Unicorn server.|
| serviceName | String  | `unicorn` | The name of the `service` which is operating the Unicorn server. If this is present, and `host` is not, the chart will template the hostname of the service (and current `.Release.Name`) in place of the `host` value. This is convenient when using Unicorn as a part of the overall GitLab chart. |

## Chart Settings

The following values are used to configure the GitLab Shell Pods.

### hostKeys.secret

The name of the Kubernetes `secret` to grab the SSH host keys from. The keys in the
secret must start with the key names `ssh_host_` in order to be used by GitLab Shell.

### authToken

GitLab Shell uses an Auth Token in its communication with Unicorn. Share the token
with GitLab Shell and Unicorn using a shared Secret.

```YAML
authToken:
 secret: gitlab-shell-secret
 key: secret
```

| Name             | Type    | Default | Description |
|:-----------------|:-------:|:--------|:------------|
| authToken.key    | String  |         | The name of the key in the above secret that contains the authToken. |
| authToken.secret | String  |         | The name of the kubernetes `Secret` to pull from. |
