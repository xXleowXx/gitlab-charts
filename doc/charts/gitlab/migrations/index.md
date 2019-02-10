# Using the GitLab-Migrations Chart

The `migrations` sub-chart provides a single migration [Job][] that handles seeding/migrating
the GitLab database. The chart runs using the gitlab-rails codebase.

After migrating, this Job also edits the application settings in the database to turn off
[writes to authorized keys file](https://docs.gitlab.com/ee/administration/operations/fast_ssh_key_lookup.html#setting-up-fast-lookup-via-gitlab-shell).
In the charts we are only supporting use of the GitLab Authorized Keys API with the
SSH `AuthorizedKeysCommand`, instead of writing to an authorized keys file.

## Requirements

This chart depends on Redis and PostgreSQL, either as part of the complete GitLab
chart or provided as external services reachable from the Kubernetes cluster this
chart is deployed onto.

## Design Choices

`migrations` is configured to use Helm post-install/post-upgrade hooks in order to
create a new migrations [Job](https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/)
each time the chart is deployed. In order to prevent job name collisions, we append
the chart revision, and a random alpha-numeric value to the Job name each time it is
created. The purpose of the random text is described below.

For now we also have the jobs remain as objects in the cluster after they complete,
so we can observe the migration logs. Currently this means these Jobs persist
even after a `helm delete`. This is one of the reasons why we append random text to
the Job name, so that future deployments using the same release name don't cause conflicts.
Once we have some form of log-shipping in place, we can revisit the persistence of
these objects.

The container used in this chart has some additional optimizations that we are not
currently using in this Chart; mainly the ability to quickly skip running migrations
if they are already up to date, without needing to boot up the rails application to
check. This optimization requires us to persist the migration status, which we are
not doing with this chart at the moment. In the future we will introduce storage support
for the migrations status to this chart.

## Configuration

The `migrations` chart is configured in two parts: [external services](#external-services),
and chart settings.

### Installation command line options

The table below contains all the possible charts configurations that can be supplied
to `helm install` command using the `--set` flags.

| Parameter            | Description                              | Default         |
| -------------------- | ---------------------------------------- | --------------- |
| enabled              | Migrations enable flag                   | true            |
| extraContainers      | List of extra containers to include      |                 |
| extraInitContainers  | List of extra init containers to include |                 |
| extraVolumeMounts    | List of extra volumes mountes to do      |                 |
| extraVolumes         | List of extra volumes to create          |                 |
| image.pullPolicy     | Migrations pull policy                   | Always          |
| image.pullSecrets    | Secrets for the image repository         |                 |
| image.repository     | Migrations image repository              | registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ee |
| image.tag            | Migrations image tag                     |                 |
| init.image           | initContainer image                      | busybox         |
| init.tag             | initContainer image tag                  | latest          |
| psql.password.key    | key to psql password in psql secret      | psql-password   |
| psql.password.secret | psql secret                              | gitlab-postgres |
| redis.serviceName    | Redis service name                       | redis           |

## Chart configuration examples

### image.pullSecrets

`pullSecrets` allows you to authenticate to a private registry to pull images for a pod.

Additional details about private registries and their authentication methods can be
found in [the Kubernetes documentation](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Below is an example use of `pullSecrets`

```YAML
image:
  repository: my.migrations.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

## Using the Community Edition of this chart

By default, the Helm charts use the Enterprise Edition of GitLab. If desired, you
can use the Community Edition instead. Learn more about the
[differences between the two](https://about.gitlab.com/installation/ce-or-ee/).

In order to use the Community Edition, set `image.repository` to
`registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ce`.

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
| password.key    | String  |         | The name of the key in the secret below that contains the password. |
| password.secret | String  |         | The name of the kubernetes `Secret` to pull from. |
| port            | Integer | `6379`  | The port on which to connect to the Redis server. |
| serviceName     | String  | `redis` | The name of the `service` which is operating the Redis database. If this is present, and `host` is not, the chart will template the hostname of the service (and current `.Release.Name`) in place of the `host` value. This is convenient when using Redis as a part of the overall GitLab chart. |

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
| password.key    | String  |                       | The name of the key in the secret (below) that contains the password. |
| password.secret | String  |                       | The name of the kubernetes `Secret` to pull from. |
| port            | Integer | `5432`                | The port on which to connect to the PostgreSQL server. |
| username        | String  | `gitlab`              | The username with which to authenticate to the database. |
