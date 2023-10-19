---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure the GitLab chart with an external PgBouncer

This documentation outlines how to install and configure [PgBouncer](https://www.pgbouncer.org) with GitLab Helm Chart and external [PostgreSQL](https://www.postgresql.org).

PgBouncer is a PostgreSQL connection pooler. You can connect any target application to PgBouncer as if it were a PostgreSQL server. PgBouncer then either creates a connection to the actual server, or reuses one of its existing connections.

Using PgBouncer lowers the performance impact of opening new connections to PostgreSQL.

## Configure PgBouncer

Prerequisite:

- A deployment of PostgreSQL 12 or later.

To use PgBouncer within GitLab Helm chart, set the following properties:

- `pgbouncer.enabled`: Set to `true` to enable the included PgBouncer chart.
- `pgbouncer.databases.<database_name>`: Set `<database_name>` to the name of the database used for GitLab (for example, `gitlabhq_production`).
- `pgbouncer.databases.<database_name>.host`: Set `<database_name>.host` to the host name of the database server.
- `pgbouncer.databases.<database_name>.port`: Set `<database_name>.port` to the port of the database server.

For more information, see the [example values file](https://gitlab.com/gitlab-org/gitlab/-/tree/master/examples/pgbouncer/values-pgbouncer.yaml), which shows the
appropriate configuration.

NOTE:
When using multiple replicas of PgBouncer, values for `min_pool_size` and `default_pool_size` are scaled according to the number of replicas. For example, if `min_pool_size: 20` and `replicaCount: 3` are configured, the resulting minimum pool size in the database server will be `20 * 3 = 60` minimum backend connections. The same logic applies to `default_pool_size`. Keep this in mind when scaling PgBouncer.

### User Authentication in PgBouncer

There are multiple ways to authenticate users in PgBouncer.

#### Authentication File

The authentication file (also known as the `auth_file`) contains the list of known roles and their password hash. 

To securely configure this file:

1. Create the `gitlab_user` and `gitlab` users in the external PostgreSQL instance:

   ```sql
   CREATE DATABASE gitlab;
   create user gitlab with encrypted password 'verylongverysecurepostgresqlpassword';
   create user gitlab_user with encrypted password 'xxxverysecretpasswordxxx';
   -- GRANT ALL PRIVILEGES ON DATABASE gitlab TO gitlab;
   -- GRANT ALL PRIVILEGES ON DATABASE gitlab TO gitlab_user;
   ```

1. Manually create a secret in advance, mounted in the `auth_file` location path for being referenced. Use the appropriate `extraVolumes` and `extraVolumeMounts` elements in the `pgbouncer` chart. 

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

An alternative, less secure approach is to use the `userlist` element to automatically generate a secret:

```yaml
pgbouncer:
  # ...
  pgbouncer:
    # ...
    auth_file: /etc/pgbouncer/userlist.txt
  userlist:
    user1: <pwd | md5 | scram-sha-256 >
```

WARNING:
You should not use this approach outside of experimentation.

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

Prerequisite:

- Superuser access to the `pg_shadow` table.

1. Create a secure function at the database server level. For example:

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

1. Fetch the hashed password of the database user name (the following example assumes `gitlab` is the database username):

   ```sql
   gitlabhq_production=# select uname, phash from pgbouncer_auth.user_lookup('gitlab');

    uname  |                                                                 phash
   --------+---------------------------------------------------------------------------------------------------------------------------------------
    gitlab | SCRAM-SHA-256...
   ```

1. Run the following chart configuration to enable the authentication query (`auth_query`) to return the password hash:

   ```yaml
   pgbouncer:
     # ...
     pgbouncer:
       # ...
       auth_query: select uname, phash from pgbouncer_auth.user_lookup($1)
   ```

NOTE:
When both `auth_query` and `auth_file` are defined, the `auth_query` is used only for roles not found in the `auth_file`.

For more information about how to configure the secure function, see the [PgBouncer documentation](https://www.pgbouncer.org/config.html).

NOTE:
The `auth_type` value **must** match the `password_encryption` value under the `postgresql.conf` configuration file in the database server(s), as well as in the client authentication `pg_hba.conf` file.

### Configure TLS connection for PgBouncer

To connect PgBouncer over TLS:

1. Create a Kubernetes Secret containing both the key and the certificate(s).

   ```shell
   kubectl create secret generic gitlab-pgbouncer-tls --from-file=client.crt=client-pgbouncer-tls.crt=<path to certificate>
   kubectl create secret generic gitlab-pgbouncer-tls --from-file=client.key=client-pgbouncer.key=<path to key>

   kubectl create secret generic gitlab-pgbouncer-tls --from-file=server.crt=server-pgbouncer-tls.crt=<path to certificate>
   kubectl create secret generic gitlab-pgbouncer-tls --from-file=server.key=server-pgbouncer.key=<path to key>
   ```

1. PgBouncer has to mount these secrets in the `pgbouncer` container to be able to reference them in the `pgbouncer.pgbouncer` Helm chart configuration. To do this, use the `extraVolumes` and `extraVolumeMounts` elements:

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

After you have configured PgBouncer, it can be referenced from GitLab chart. To do this, configure the `webservice`, `sidekiq` and `gitlab-exporter` services as follows:

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

You do not need to reconfigure the `global.psql` service.

GitLab is now ready to use PgBouncer.

### Enable PgBouncer exporter for monitoring

To enable monitoring for the PgBouncer service, you enable and configure `pgbouncerExporter`.

To do this, you:

- Create the `PGBOUNCER_USER`, `PGBOUNCER_PORT`, and `PGBOUNCER_PWD` environment variables.
- Create a sidecar container that automatically exposes metrics for each PgBouncer replica.

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

## Related topics

- [PgBouncer exporter](https://docs.gitlab.com/ee/administration/monitoring/prometheus/pgbouncer_exporter.html)
- [Working with the bundled PgBouncer service](https://docs.gitlab.com/ee/administration/postgresql/pgbouncer.html)
