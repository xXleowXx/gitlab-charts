# Manage the container registry metadata database

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5521) in GitLab 16.4 as a [Beta](https://docs.gitlab.com/ee/policy/experiment-beta-support.html#beta) feature.

The metadata database enables many new registry features, including
online garbage collection, and increases the efficiency of many registry operations.
This page contains information on how to create the database.

## Metadata database feature support

You can migrate existing registries to the metadata database, and use online garbage collection.

Some database-enabled features are only enabled for GitLab.com and automatic database provisioning for
the registry database is not available. Review the feature support table in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#supported-feature-status)
for the status of features related to the container registry database.

## Create the database

If the Registry database is enabled, Registry will use its own database to track its state.
Follow the steps below to manually create the database and role.

NOTE:
These instructions assume you are using the bundled PostgreSQL server. If you are using your own server,
there will be some variation in how you connect.

1. Create the secret with the database password:

   ```shell
   kubectl create secret generic RELEASE_NAME-registry-database-password --from-literal=password=randomstring
   ```

1. Log into your database instance:

   ```shell
   kubectl exec -it $(kubectl get pods -l app.kubernetes.io/name=postgresql -o custom-columns=NAME:.metadata.name --no-headers) -- bash
   ```

   ```shell
   PGPASSWORD=${POSTGRES_POSTGRES_PASSWORD} psql -U postgres -d template1
   ```

1. Create the database user:

   ```sql
   CREATE ROLE registry WITH LOGIN;
   ```

1. Set the database user password.

   1. Fetch the password:

      ```shell
      kubectl get secret RELEASE_NAME-registry-database-password -o jsonpath="{.data.password}" | base64 --decode
      ```

   1. Set the password in the `psql` prompt:

      ```sql
      \password registry
      ```

1. Create the database:

   ```sql
   CREATE DATABASE registry WITH OWNER registry;
   ```

1. Safely exit from the PostgreSQL command line and then from the container using `exit`:

   ```shell
   template1=# exit
   ...@gitlab-postgresql-0/$ exit
   ```


## Enable the metadata database for Helm charts installations

Prerequisites:

- GitLab 16.4 or later.
- PostgreSQL database version 12 or later. It must be accessible from the registry pods.
- Access to the Kubernetes cluster and the Helm deployment locally.
- SSH access to the registry pods.

Follow the instructions that match your situation:

- [New installation](#new-installations) or enabling the container registry for the first time.
- Migrate existing container images to the metadata database:
  - [One-step migration](#one-step-migration). Only recommended for relatively small registries or no requirement to avoid downtime.
  - [Three-step migration](#three-step-migration). Recommended for larger container registries.

### Before you start

Read the [before you start](https://docs.gitlab.com/ee/administration/packages/container_registry_metadata_database.html#before-you-start)
section of the Registry administration guide.

### New installations

To enable the database:

1. [Create the database and Kubernetes secret](#create-the-database).
1. Get the current Helm values for your release and save them into a file.
   For example, for a release named `gitlab` and a file named `values.yml`:

   ```shell
   helm get values gitlab > values.yml
   ```

1. Add the following lines to your `values.yml` file:

   ```yaml
   registry:
      enabled: true
      database:
        enabled: true
        name: registry # must match the database name you created above
        user: registry # must match the database username you created above
        password:
          secret: gitlab-registry-database-password # must match the secret name
          key: password # must match the secret key to read the password from
      migrations:
        enabled: true # this option will execute the schema migration as part of the registry deployment
   ```

   NOTE:
   Setting the value of `registry.database.migrations.enabled` will execute
   the schema migrations as part the registry deployment in a job with a 
   name similar to `gitlab-registry-migrations-1`. The registry will 
   fail to start if the schema migrations failed.

1. Optional. You can verify the schema migrations have been applied properly.
   You can either:
   - Review the log output of the migrations job, for example:

      ```shell
      kubectl logs jobs/gitlab-registry-migrations-1
      ...
      OK: applied 154 migrations in 13.752s
      ```

   - Or, connect to the Postgres database and query the `schema_migrations` table:

      ```sql
      SELECT * FROM schema_migrations;
      ```
      
      Ensure the `applied_at` column timestamp is filled for all rows.

The registry is ready to use the metadata database!

### Existing registries

You can migrate your existing container registry data in one step or three steps.
A few factors affect the duration of the migration:

- The size of your existing registry data.
- The specifications of your PostgresSQL instance.
- The number of registry pods running in your cluster.
- Network latency between the registry, PostgresSQL and your configured Object Storage.

Choose the one or three step method according to your registry installation.

#### One-step migration

WARNING:
The registry must remain in `read-only` mode during the migration.
Only choose this method if you do not need to write to the registry during the migration
and your registry contains a relatively small amount of data.

1. [Create the database and Kubernetes secret](#create-the-database).
1. Get the current Helm values for your release and save them into a file.
   For example, for a release named `gitlab` and a file named `values.yml`:

   ```shell
   helm get values gitlab > values.yml
   ```

1. Find the `registry:` section in the `values.yml` file and
   add the `database` section, set the `maintenance.readonly.enabled` 
   flag to `true`, and `migrations.enabled` to `true`:

   ```yaml
   registry:
      enabled: true
      maintenance:
        readonly:
          enabled: true # must remain set to true while the migration is executed
      database:
        enabled: true
        name: registry # must match the database name you created above
        user: registry # must match the database username you created above
        password:
          secret: gitlab-registry-database-password # must match the secret name
          key: password # must match the secret key to read the password from
      migrations:
        enabled: true # this option will execute the schema migration as part of the registry deployment
   ```

1. Upgrade your Helm installation to apply changes in your deployment:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. Connect to one of the registry pods via SSH, for example for a pod named `gitlab-registry-5ddcd9f486-bvb57`:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. Run the following command:

   ```shell
   /usr/bin/registry database import /etc/docker/registry/config.yml
   ```

You can now use the metadata database for all operations!

#### Three-step migration

Follow this guide to migrate your existing container registry data.
This procedure is recommended for larger sets of data or if you are
trying to minimize downtime while completing the migration.

NOTE:
Users have reported step one import completed at [rates of 2 to 4 TB per hour](https://gitlab.com/gitlab-org/gitlab/-/issues/423459).
At the slower speed, registries with over 100TB of data could take longer than 48 hours.

##### Pre-import repositories (step one)

For larger instances, this command can take hours to days to complete, depending
on the size of your registry. You may continue to use the registry as normal while
step one is being completed.

WARNING:
It is [not yet possible](https://gitlab.com/gitlab-org/container-registry/-/issues/1162)
to restart the migration, so it's important to let the migration run to completion.
If you must halt the operation, you have to restart this step.

1. Add the `database` section to your `/etc/gitlab/gitlab.rb` file, but start with the metadata database **disabled**:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name'
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Apply schema migrations](#apply-schema-migrations) if you have not done so.
1. Run the first step to begin the migration:

   ```shell
   sudo gitlab-ctl registry-database import --step-one
   ```

NOTE:
You should try to schedule the following step as soon as possible
to reduce the amount of downtime required. Ideally, less than one week
after step one completes. Any new data written to the registry between steps one and two,
causes step two to take more time.

##### Import all repository data (step two)

This step requires the registry to be shut down or set in `read-only` mode.
Allow enough time for downtime while step two is being executed.

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']`
   configuration. For example, for a `gcs` backed registry using a `gs://my-company-container-registry`
   bucket , the configuration could be:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => "my-company-container-registry",
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Run step two of the migration

   ```shell
   sudo gitlab-ctl registry-database import --step-two
   ```

1. If the command completed successfully, all images are now fully imported. You
   can now enable the database, turn off read-only mode in the configuration, and
   start the registry service:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => "my-company-container-registry",
       'chunksize' => 5242880
     },
     'maintenance' => { # This section can be removed.
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

You can now use the metadata database for all operations!

##### Import the rest of the data (step three)

Even though the registry is now fully using the database for its metadata, it
does not yet have access to any potentially unused layer blobs.

To complete the process, run the final step of the migration:

```shell
sudo gitlab-ctl registry-database import --step-three
```

After that command exists successfully, the registry is now fully migrated to the database!

## Manage schema migrations

Use the following commands to run the schema migrations for the Container registry metadata database.
The registry must be enabled and the configuration section must have the database section filled.

### Apply schema migrations

1. Run the registry database schema migrations

   ```shell
   sudo gitlab-ctl registry-database migrate up
   ```

1. The registry must stop if it's running. Type `y` to confirm and wait for the process to finish.

NOTE:
The `migrate up` command offers some extra flags that can be used to control how the migrations are applied.
Run `sudo gitlab-ctl registry-database migrate up --help` for details.

### Undo schema migrations

You can undo schema migrations in case anything goes wrong, but this is a non-recoverable action.
If you pushed new images while the database was in use, they will no longer be accessible
after this.

1. Undo the registry database schema migrations:

   ```shell
   sudo gitlab-ctl registry-database migrate down
   ```

NOTE:
The `migrate down` command offers some extra flags. Run `sudo gitlab-ctl registry-database migrate down --help` for details.

## Troubleshooting
