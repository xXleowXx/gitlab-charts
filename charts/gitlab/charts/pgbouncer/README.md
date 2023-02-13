# PgBouncer Helm Chart

The PgBouncer Helm Chart is a Helm chart implementation for PgBouncer.

pgBouncer is a lightweight connection pooler for PostgreSQL. It sits between your application and the PostgreSQL server, allowing your application to reuse connections to the server, rather than creating a new connection for each query. This can improve the performance and scalability of your application, as well as reduce the load on the PostgreSQL server.

## Installation

You can install the helm chart with:

```bash
helm install -f values.yaml pgbouncer
```

or through the chart's requirements:

```yaml
dependencies:
- name: pgbouncer
  version: 0.0.1
  condition: pgbouncer.enabled
  repository: https://registry.cern.ch/chartrepo/pgbouncer
```

## Configuration

To configure PgBouncer, create a `values.yaml` file and add the following settings (as an example):

```yaml
pgbouncer:
  enabled: true
  replicaCount: 1
  image:
    repository: registry.cern.ch/pgbouncer/pgbouncer
    tag: 1.18.0
  databases:
    mydatabase:
      host: my-host.cern.ch
      port: 5432
    myseconddatabase:
      host: my-second-host.cern.ch
      port: 5432
  pgbouncer:
    logfile: /dev/stdout
    auth_type: md5
    auth_file: /etc/pgbouncer/userlist.txt
    # Console access control
    admin_users: user1
    stats_users: user2
    # Log settings
    log_connections: 1
    log_disconnections: 1
    log_pooler_errors: 1
    log_stats: 1
    verbose: 0
  userlist:
    user1: <pwd | md5 | scram-sha-256 >
    user2: <pwd | md5 | scram-sha-256 >
```

For a full overview of all the configurations allowed, please refer to the [values.yaml](./chart/values.yaml) file.

For further information about the configuration of pgbouncer, refer to the official documentation under <https://www.pgbouncer.org/config.html>

### PgBouncer Exporter configuration

Additionally to the deployment of `pgbouncer`, a `pbgouncer-exporter` for metrics can be also deployed as a sidecar container, by appending the following as an example of configuration:

```yaml
pgbouncer:
  enabled: true
  #
  # <rest of the configuration for pgbouncer>
  #
  pgbouncerExporter:
    enabled: true
    extraEnv:
      - name: PGBOUNCER_PORT
        value: "6432"
    extraEnvFrom:
      - name: PGBOUNCER_USER
        valueFrom:
          secretKeyRef:
            name: mysecret
            key: pgbouncer-user
            optional: false
      - name: PGBOUNCER_PWD
        valueFrom:
          secretKeyRef:
            name: mysecret
            key: pgbouncer-password
            optional: false
```

> note: the above snippet assumes you have configured previously a secret named `secret` in your cluster, containing two keys, `pgbouncer-user` and `pgbouncer-password`. For information about how to configure a secret in your cluster, refer to the official documentation under <https://kubernetes.io/docs/concepts/configuration/secret/#use-cases>

It is mandatory to include the `PGBOUNCER_PORT`, `PGBOUNCER_USER` and `PGBOUNCER_PWD` environment variables for the `pgbouncer-exporter` to work.
