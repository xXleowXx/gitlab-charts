---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure the GitLab chart with an external PgBouncer

This document outlines how to install and configure [PgBouncer](https://www.pgbouncer.org) with GitLab Helm Chart and external [PostgreSQL](https://www.postgresql.org).

[PgBouncer](https://www.pgbouncer.org) is a [PostgreSQL](https://www.postgresql.org/) connection pooler. Any target application can be connected to pgbouncer as if it were a PostgreSQL server, and pgbouncer will create a connection to the actual server, or it will reuse one of its existing connections.

The aim of [PgBouncer](https://pgbouncer.org) is to lower the performance impact of opening new connections to PostgreSQL.

## Prerequisites

- A deployment of PostgreSQL 12 or later.

## Configure PgBouncer

In order to start using the `pgbouncer` within GitLab Helm chart, the following properties must be set:

- `pgbouncer.enabled`: Set to `true` to enable the included PgBouncer chart.
- `pgbouncer.databases.<database-name>`. Set `<database-name>` to the name of the database used for GitLab (e.g., `gitlabhq_production`).
- `pgbouncer.databases.<database-name>.host`. Set `<database-name>.host` to the host name of the database server.
- `pgbouncer.databases.<database-name>.port`. Set `<database-name>.port` to the port of the database server.

A more complete [example values file](examples/pgbouncer/values-pgbouncer.yaml) is provided, which shows the
appropriate set of configuration.

NOTE:
When using multiple replicas of PgBouncer, values for `min_pool_size` and `default_pool_size` are scaled according to the number of replicas. For example, if `min_pool_size: 20` and `replicaCount: 3` are configured, the resulting minimum pool size in the database server will be `20 * 3 = 60` minimum backend connections. The same logic applies to `default_pool_size`. Keep this in mind when scaling PgBouncer.

### User Authentication in PgBouncer

There are a few different ways to authenticate users in PgBouncer.

#### Authentication File

Authentication file contains the list of known roles and their password hash (a.k.a. `auth_file`). 

There are two approaches for configuring it.

More secure approach is to create manually a secret in advance, mounted in the `auth_file` location path for being referenced, using the appropriate `extraVolumes` and `extraVolumeMounts` elements in `pgbouncer` chart. For that, external PostgreSQL instance should already have `gitlab_user` and `gitlab` users created:

```sql
CREATE DATABASE gitlab;
create user gitlab with encrypted password 'verylongverysecurepostgresqlpassword';
create user gitlab_user with encrypted password 'xxxverysecretpasswordxxx';
-- GRANT ALL PRIVILEGES ON DATABASE gitlab TO gitlab;
-- GRANT ALL PRIVILEGES ON DATABASE gitlab TO gitlab_user;
```

```shell
cat > pgbouncer_auth_file << EOF
gitlab_user: xxxverysecretpasswordxxx
gitlab: verylongverysecurepostgresqlpassword
EOF

kubectl create secret --namespace=gitlab generic pgbouncer --from-file=auth_file=pgbouncer_auth_file
```

```yaml
pgbouncer:
  pgbouncer:
    auth_file: /etc/pgbouncer/auth_file
  extraVolumes:
    - name: pgbouncer_auth
      secret:
        secretName: pgbouncer
        items:
          - key: auth_file
            path: auth_file
  extraVolumeMounts:
    - name: pgbouncer_auth
      mountPath: /etc/pgbouncer/auth_file
      subPath: auth_file
      readonly: true
```

Alternatively, less secure (and **not recommended** outside of experimentation), is utilizing the `userlist` element. This will automatically generate a secret:

```yaml
pgbouncer:
  # ...
  pgbouncer:
    # ...
    auth_file: /etc/pgbouncer/userlist.txt
  userlist:
    user1: <pwd | md5 | scram-sha-256 >
```

#### Authentication Query

Secure function must be created at the database server level and a superuser access to the `pg_shadow` table is required. Example of secure function:

```sql
CREATE OR REPLACE FUNCTION pgbouncer.user_lookup(in i_username text, out uname text, out phash text)
RETURNS record AS $$
BEGIN
    SELECT usename, passwd FROM pg_catalog.pg_shadow
    WHERE usename = i_username INTO uname, phash;
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
REVOKE ALL ON FUNCTION pgbouncer.user_lookup(text) FROM public, pgbouncer;
GRANT EXECUTE ON FUNCTION pgbouncer.user_lookup(text) TO pgbouncer;
```

This function allows to fetch the hashed password of the database user name (assuming `gitlab` is the database username):

```sql
gitlabhq_production=# select uname, phash from pgbouncer_auth.user_lookup('gitlab');

 uname  |                                                                 phash
--------+---------------------------------------------------------------------------------------------------------------------------------------
 gitlab | SCRAM-SHA-256...
```

Authentication query returns the password hash (a.k.a `auth_query`). Chart configuration to enable `auth_query`:

```yaml
pgbouncer:
  # ...
  pgbouncer:
    # ...
    auth_query: select uname, phash from pgbouncer_auth.user_lookup($1)
```

NOTE:
When both `auth_query` and `auth_file` are defined, the `auth_query` is used only for roles not found in the `auth_file`.

For further information about how to configure the secure function, refer to the [PgBouncer official documentation](https://www.pgbouncer.org/config.html).

`auth_type` value **has to** match `password_encryption` value under the `postgresql.conf` configuration file in the database server(s), as well as in the client authentication `pg_hba.conf` file.

### Configure TLS connection for PgBouncer

In order to connect PgBouncer over TLS, create a Kubernetes Secret containing both the key and the certificate(s) is needed in advance:

```shell
kubectl create secret generic gitlab-pgbouncer-tls --from-file=client.crt=client-pgbouncer-tls.crt=<path to certificate>
kubectl create secret generic gitlab-pgbouncer-tls --from-file=client.key=client-pgbouncer.key=<path to key>

kubectl create secret generic gitlab-pgbouncer-tls --from-file=server.crt=server-pgbouncer-tls.crt=<path to certificate>
kubectl create secret generic gitlab-pgbouncer-tls --from-file=server.key=server-pgbouncer.key=<path to key>
```

PgBouncer has to mount above secrets in `pgbouncer` container, to be able to reference them in the `pgbouncer.pgbouncer` Helm chart configuration. This can be done using `extraVolumes` and `extraVolumeMounts` elements accordingly.

```yaml
pgbouncer:
  pgbouncer:
    client_tls_key_file: /etc/pgbouncer/tls/client.crt
    client_tls_cert_file: /etc/pgbouncer/tls/client.key

    server_tls_key_file: /etc/pgbouncer/tls/server.crt
    server_tls_cert_file: /etc/pgbouncer/tls/server.key
  extraVolumes:
    - name: pgbouncer-tls
      secret:
        secretName: gitlab-pgbouncer-tls
  extraVolumeMounts:
    - name: pgbouncer-tls
      mountPath: /etc/pgbouncer/tls
      readonly: true
```

## Configure GitLab application to use PgBouncer

With PgBouncer fully configured, it could be referenced from GitLab chart. The only services requiring additional configuration are `webservice`, `sidekiq` and `gitlab-exporter`.

To configure above services, keep the `global.psql` configuration as is, and modify the GitLab components configuration as follows:

```yaml
global:
  # ...
  psql:
    host: host1.example.com
    password:
      secret: gitlab-database-credentials
      key: database-username-pwd
    database: gitlabhq_production
    port: 6600
    username: gitlab
# ...
gitlab:
  # ...
  gitlab-exporter:
    # ...
    psql:
      host: gitlab-pgbouncer # assuming the release name is gitlab
      port: 6432
      password:
        secret: gitlab-database-credentials
        key: database-username-pwd
      database: gitlabhq_production
      username: gitlab
  # ...
  webservice:
    # ...
    psql:
      host: gitlab-pgbouncer # assuming the release name is gitlab
      port: 6432
      password:
        secret: gitlab-database-credentials
        key: database-username-pwd
      database: gitlabhq_production
      username: gitlab
    # ...
  sidekiq:
    # ...
    psql:
      host: gitlab-pgbouncer # assuming the release name is gitlab
      port: 6432
      password:
        secret: gitlab-database-credentials
        key: database-username-pwd
      database: gitlabhq_production
      username: gitlab
```

At this point GitLab is functionally ready to use PgBouncer.

### Enable PgBouncer exporter for monitoring

To enable monitoring for the PgBouncer service, `pgbouncerExporter` must be enabled and configured.

NOTE:
When enabling `pgbouncerExporter`, `PGBOUNCER_USER`, `PGBOUNCER_PORT`, and `PGBOUNCER_PWD` environment variables must be created.

To automatically create a sidecar container start exposing metrics for each of the PgBouncer replicas add configuration:

```yaml
pgbouncer:
  enabled: true
  podAnnotations:
    gitlab.com/prometheus_scrape: "true"
    gitlab.com/prometheus_port: "9127"
    gitlab.com/prometheus_path: "/metrics"
  # ...
  pgbouncerExporter: # optional
    enabled: true
    extraEnv:
      - name: PGBOUNCER_PORT
        value: "6432"
      - name: PGBOUNCER_USER
        value: "database_username"
    extraEnvFrom:
      - name: PGBOUNCER_PWD
        valueFrom:
          secretKeyRef:
            name: gitlab-database-credentials
            key: database-username-pwd
            optional: false
```
