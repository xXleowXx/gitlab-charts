# Using the GitLab-Unicorn Chart

The `unicorn` sub-chart provides the gitlab rails web-server running two unicorn workers
per pod. (The minimum necessary for a single pod to be able to serve any web request in GitLab)

Currently the container used in the chart also includes a copy of gitlab-workhorse,
which we haven't yet split out.

## Requirements

This chart depends on Redis, PostgreSQL, Gitaly, and Registry services, either as
part of the complete GitLab chart or provided as external services reachable from
the Kubernetes cluster this chart is deployed onto.

# Configuration

The `unicorn` chart is configured as follows: Global Settings, Ingress Settings External
Services, and Chart Settings.

## Installation command line options

The table below contains all the possible charts configurations that can be supplied
to the `helm install` command using the `--set` flags

| Parameter                      | Description                                        | Default                                                      |
| ---                            | ---                                                | ---                                                          |
| annotations                    | Pod annotations                                    |                                                              |
| enabled                        | Unicorn enabled flag                               | true                                                         |
| extraContainers                | List of extra containers to include                |                                                              |
| extraInitContainers            | List of extra init containers to include           |                                                              |
| extras.google_analytics_id     | Google Analytics Id for frontend                   | nil                                                          |
| extraVolumeMounts              | List of extra volumes mountes to do                |                                                              |
| extraVolumes                   | List of extra volumes to create                    |                                                              |
| gitlab.unicorn.workhorse.image | Workhorse image repository                         | registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee |
| gitlab.unicorn.workhorse.tag   | Workhorse image tag                                |                                                              |
| hpa.targetAverageValue         | Set the autoscaling target value                   | 400m                                                         |
| image.pullPolicy               | Unicorn image pull policy                          | Always                                                       |
| image.pullSecrets              | Secrets for the image repository                   |                                                              |
| image.repository               | Unicorn image repository                           | registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ee   |
| image.tag                      | Unicorn image tag                                  |                                                              |
| init.image                     | initContainer image                                | busybox                                                      |
| init.tag                       | initContainer image tag                            | latest                                                       |
| metrics.enabled                | Toggle Prometheus metrics exporter                 | true                                                         |
| minio.bucket                   | Name of storage bucket, when using Minio           | git-lfs                                                      |
| minio.port                     | Port for Minio service                             | 9000                                                         |
| minio.serviceName              | Name of Minio service                              | minio-svc                                                    |
| psql.password.key              | Key to psql password in psql secret                | psql-password                                                |
| psql.password.secret           | psql secret name                                   | gitlab-postgres                                              |
| rack_attack.git_basic_auth     | See [GitLab documentation][rackattack] for details | {}                                                           |
| redis.serviceName              | Redis service name                                 | redis                                                        |
| registry.api.port              | Registry port                                      | 5000                                                         |
| registry.api.protocol          | Registry protocol                                  | http                                                         |
| registry.api.serviceName       | Registry service name                              | registry                                                     |
| registry.enabled               | Add/Remove registry link in all projects menu      | true                                                         |
| registry.tokenIssuer           | Registry token issuer                              | gitlab-issuer                                                |
| replicaCount                   | Unicorn number of replicas                         | 1                                                            |
| resources.requests.cpu         | Unicorn minimum cpu                                | 200m                                                         |
| resources.requests.memory      | Unicorn minimum memory                             | 1.4G                                                         |
| service.externalPort           | Unicorn exposed port                               | 8080                                                         |
| service.internalPort           | Unicorn internal port                              | 8080                                                         |
| service.name                   | Unicorn service name                               | unicorn                                                      |
| service.type                   | Unicorn service type                               | ClusterIP                                                    |
| service.workhorseExternalPort  | Workhorse exposed port                             | 8181                                                         |
| service.workhorseInternalPort  | Workhorse internal port                            | 8181                                                         |
| shell.authToken.key            | Key to shell token in shell secret                 | secret                                                       |
| shell.authToken.secret         | Shell token secret                                 | gitlab-shell-secret                                          |
| shell.port                     | Port number to use in SSH URLs generated by UI     | nil                                                          |
| trusted_proxies                | See [GitLab documentation][proxies] for details    | []                                                           |
| workerProcesses                | Unicorn number of workers                          | 2                                                            |
| workerTimeout                  | Unicorn worker timeout                             | 60                                                           |

## Chart configuration examples

### image.pullSecrets

`pullSecrets` allows you to authenticate to a private registry to pull images for a pod.

Additional details about private registries and their authentication methods
can be found in [the Kubernetes documentation](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Below is an example use of `pullSecrets`:

```YAML
image:
  repository: my.unicorn.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### annotations

`annotations` allows you to add annotations to the unicorn pods. 

Below is an example use of `annotations`:

```YAML
annotations:
  kubernetes.io/example-annotation: annotation-value
``` 

## Using the Community Edition of this chart

By default, the Helm charts use the Enterprise Edition of GitLab. If desired, you
can instead use the Community Edition. Learn more about the [difference between the two](https://about.gitlab.com/installation/ce-or-ee/).

In order to use the Community Edition, set `image.repository` to
`registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce` and `workhorse.image`
to `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce`

## Global Settings

We share some common global settings among our charts. See the [Globals Documentation](../../globals.md) for common configuration
options, such as GitLab and Registry hostnames.

## Ingress Settings

| Name                                 | Type    | Default | Description |
|:-------------------------------------|:-------:|:--------|:------------|
| ingress.annotations.*annotation-key* | String  | (empty) | `annotation-key` is a string that will be used with the value as an annotation on every ingress. For example: `ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`. |
| ingress.enabled                      | Boolean | false   | Setting that controls whether to create ingress objects for services that support them. When `false`, the `global.ingress.enabled` setting value is used. |
| ingress.tls.enabled                  | Boolean | true    | When set to `false`, you disable TLS for GitLab Unicorn. This is mainly useful for cases in which you cannot use TLS termination at ingress-level, like when you have a TLS-terminating proxy before the ingress controller. |
| ingress.tls.secretName               | String  | (empty) | The name of the Kubernetes TLS Secret that contains a valid certificate and key for the GitLab url. When not set, the `global.ingress.tls.secretName` value is used instead. |

## External Services

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
| serviceName     | String  | `redis` | The name of the `service` which is operating the Redis database. If this is present, and `host` is not, the chart will template the hostname of the service (and current `.Release.Name`) in place of the `host` value. This is convenient when using Redis as a part of the overall GitLab chart. |
| port            | Integer | `6379`  | The port on which to connect to the Redis server. |
| password.key    | String  |         | The `password.key` attribute for PostgreSQL defines the name of the key in the secret (below) that contains the password. |
| password.secret | String  |         | The `password.secret` attribute for PostgreSQL defines the name of the kubernetes `Secret` to pull from. |

### PostgreSQL

```YAML
psql:
  host: psql.example.com
  port: 5432
  database: gitlabhq_production
  username: gitlab
  password:
    secret: gitlab-postgres
    key: psql-password
```

| Name            | Type    | Default               | Description |
|:----------------|:-------:|:----------------------|:------------|
| host            | String  |                       | The hostname of the PostgreSQL server with the database to use. This can be omitted if `postgresql.install=true` (default non-production). |
| database        | String  | `gitlabhq_production` | The name of the database to use on the PostgreSQL server. |
| password.key    | String  |                       | The `password.key` attribute for PostgreSQL defines the name of the key in the secret (below) that contains the password. |
| password.secret | String  |                       | The `password.secret` attribute for PostgreSQL defines the name of the kubernetes `Secret` to pull from. |
| port            | Integer | `5432`                | The port on which to connect to the PostgreSQL server. |
| username        | String  | `gitlab`              | The username with which to authenticate to the database. |

### Gitaly

Gitaly is configured from [global settings](../../globals.md). Please see the
[Gitaly configuration documentation](../../globals.md#configure-gitaly-settings).

### Minio

```YAML
minio:
  serviceName: 'minio-svc'
  port: 9000
```

| Name        | Type    | Default               | Description |
|:------------|:-------:|:----------------------|:------------|
| port        | Integer | `9000`                | Port number to reach the Minio `Service` on. |
| serviceName | String  | `minio-svc`           | Name of the `Service` that is exposed by the Minio pod. |

### Registry

```YAML
registry:
  host: registry.example.com
  port: 443
  api:
    protocol: http
    host: registry.example.com
    serviceName: registry
    port: 5000
  tokenIssuer: gitlab-issuer
  certificate:
    secret: gitlab-registry
    key: registry-auth.key
```

| Name               | Type    | Default         | Description |
|:-------------------|:-------:|:----------------|:------------|
| host               | String  |                 | The external hostname to use for providing docker commands to users in the GitLab UI. Falls back to the value set in the `registry.hostname` template. Which determines the registry hostname based on the values set in `global.hosts`. See the [Globals Documentation](../../globals.md) for more information. |
| port               | Integer |                 | The external port used in the hostname. Using port `80` or `443` will result in the URLs being formed with `http`/`https`. Other ports will all use `http` and append the port to the end of hostname, for example `http://registry.example.com:8443`. |
| api.host           | Integer |                 | The hostname of the Registry server to use. This can be omitted in lieu of `api.serviceName` |
| api.protocol       | Integer |                 | The protocol Unicorn should use to reach the Registry api. |
| api.serviceName    | Integer | `registry`      | The name of the `service` which is operating the Registry server. If this is present, and `api.host` is not, the chart will template the hostname of the service (and current `.Release.Name`) in place of the `api.host` value. This is convenient when using Registry as a part of the overall GitLab chart. |
| api.port           | Integer | `5000`          | The port on which to connect to the Registry api. |
| tokenIssuer        | Integer | `gitlab-issuer` | The name of the auth token issuer. This must match the name used in the Registry's configuration, as it incorporated into the token when it is sent. The default of `gitlab-issuer` is the same default we use in the Registry chart. |
| certificate.secret | Integer |                 | The name of the [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) that houses the certificate bundle to be used to verify the tokens created by the GitLab instance(s). |
| certificate.key    | Integer |                 | The name of the `key` in the `Secret` which houses the certificate bundle that will be provided to the [registry][] container as `auth.token.rootcertbundle`. |

## Chart Settings

The following values are used to configure the Unicorn Pods.

#### replicaCount

Field `replicaCount` is an integer, controlling the number of Unicorn instances to create in the deployment. This defaults to `1`.

#### workerProcesses

Field `workerProcesses` is an integer, controller the number of Unicorn workers to run per pod. You must have at least `2` workers available in your cluster in order for GitLab to properly function. Note that as you increase the `workerProcesses` the memory required will increase by approximately `400MB`, so you should update the pod `resources` accordingly.  `workerProcesses` defaults to `2`.

#### workerTimeout

Field `workerTimeout` is an integer specifying the number of seconds a request can be pending before it times out. Defaults to `60`

### metrics.enabled

By default, each pod exposes a metrics endpoint at `/-/metrics`. Metrics are only available when [GitLab Prometheus metrics](https://docs.gitlab.com/ee/administration/monitoring/prometheus/gitlab_metrics.html) are enabled in the Admin area. When metrics are enabled, annotations are added to each pod allowing a Prometheus server to discover and scrape the exposed metrics.

### GitLab Shell

GitLab Shell uses an Auth Token in its communication with Unicorn. Share the token with GitLab Shell and Unicorn using a shared Secret.

```YAML
shell:
  authToken:
    secret: gitlab-shell-secret
    key: secret
  port:
```

| Name             | Type    | Default | Description |
|:-----------------|:-------:|:--------|:------------|
| authToken.key    | String  |         | Defines the name of the key in the secret (below) that contains the authToken. |
| authToken.secret | String  |         | Defines the name of the kubernetes `Secret` to pull from. |
| port             | Integer | `22`    | The port number to use in the generation of SSH URLs within the GitLab UI. Controlled by `global.shell.port`. |

[registry]: https://hub.docker.com/_/registry/
[lfscon]: https://docs.gitlab.com/ee/workflow/lfs/lfs_administration.html
[uplcon]: https://docs.gitlab.com/ee/administration/uploads.html#using-object-storage
[rackattack]: https://docs.gitlab.com/ee/security/rack_attack.html
[proxies]: https://docs.gitlab.com/ee/install/installation.html#adding-your-trusted-proxies
