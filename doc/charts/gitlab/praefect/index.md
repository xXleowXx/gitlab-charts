---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Using the Praefect chart

The Praefect chart is used to manage a [Gitaly cluster](https://docs.gitlab.com/ee/administration/gitaly/praefect.html) inside a GitLab installment deployed with the Helm charts.

## Known Limitations

1. [TLS is not supported](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2306).
1. The database has to be [manually created](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2310).
1. [Migrating from an existing Gitaly setup](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2311) to Praefect is not supported.

## Requirements

This chart depends on the resources in the Gitaly chart. By default, it will spin up 3 Gitaly Replicas.

## Configuration

The chart is disabled by default. To enable it as part of a chart deploy set `global.praefect.enabled=true`.

### Replicas

The default number of replicas to deploy is 3. This can be changed by setting `global.praefect.virtualStorages` with the desired number of replicas. For example:

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
```

### Virtual storages

Multiple virtual storages can be configured (see [Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/praefect.html) documentation). For example:

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
```

This will create two sets of resources for Gitaly. This includes two Gitaly StatefulSets (one per virtual storage). In the Admin UI, under
`admin/application_settings/repository` > `Repository storage`, weights can be assigned to each virtual storage. Click the question mark (?) icon in the
`Storage nodes for new repositories` section for more information.

### Creating the database

Praefect uses its own database to track its state. This has to be manually created in order for Praefect to be functional.

NOTE: **Note:**
These instructions assume you are using the bundled PostgreSQL server. If you are using your own server,
there will be some variation in how you connect.

1. Log into your database instance:

   ```shell
   kubectl exec -it $(kubectl get pods -l app=postgresql -o custom-columns=NAME:.metadata.name --no-headers) -- bash
   PGPASSWORD=$(cat $POSTGRES_POSTGRES_PASSWORD_FILE) psql -U postgres -d template1
   ```

1. Create the database user:

   ```sql
   template1=# CREATE ROLE praefect WITH LOGIN;
   ```

1. Set the database user password.

   By default, the `shared-secrets` chart will generate a secret for you.

   1. Fetch the password:

      ```shell
      kubectl get secret RELEASE_NAME-praefect-dbsecret -o jsonpath="{.data.secret}" | base64 --decode
      ```

   1. Set the password in the `psql` prompt:

      ```sql
      template1=# \password praefect
      Enter new password:
      Enter it again:
      ```

1. Create the database:

   ```sql
   CREATE DATABASE praefect WITH OWNER praefect;
   ```

### Installation command line options

The table below contains all the possible charts configurations that can be supplied to
the `helm install` command using the `--set` flags.

| Parameter                      | Default                                           | Description                                                                                             |
| ------------------------------ | ------------------------------------------        | ----------------------------------------                                                                |
| failover.enabled               | true                                              | Whether Praefect should perform failover on node failure                                                |
| failover.readonlyAfter         | false                                             | Whether the nodes should be in read-only mode after failover                                            |
| autoMigrate                    | true                                              | Automatically run migrations on startup                                                                 |
| electionStrategy               | sql                                               | See [election strategy](https://docs.gitlab.com/ee/administration/gitaly/praefect.html#automatic-failover-and-leader-election) |
| image.repository               | `registry.gitlab.com/gitlab-org/build/cng/gitaly` | The default image repository to use. Praefect is bundled as part of the Gitaly image                    |
| service.name                   | `praefect`                                        | The name of the service to create                                                                       |
| service.type                   | ClusterIP                                         | The type of service to create                                                                           |
| service.internalPort           | 8075                                              | The internal port number that the Praefect pod will be listening on                                     |
| service.externalPort           | 8075                                              | The port number the Praefect service should expose in the cluster                                       |
| init.resources                 |                                                   |                                                                                                         |
| init.image                     |                                                   |                                                                                                         |
| logging.level                  |                                                   | Log level                                                                                               |
| logging.format                 | `json`                                            | Log format                                                                                              |
| logging.sentryDsn              |                                                   | Sentry DSN URL - Exceptions from Go server                                                              |
| logging.rubySentryDsn          |                                                   | Sentry DSN URL - Exceptions from `gitaly-ruby`                                                          |
| logging.sentryEnvironment      |                                                   | Sentry environment to be used for logging                                                               |
| metrics.enabled                | true                                              |                                                                                                         |
| metrics.port                   | 9236                                              |                                                                                                         |
| securityContext.runAsUser      | 1000                                              |                                                                                                         |
| securityContext.fsGroup        | 1000                                              |                                                                                                         |
