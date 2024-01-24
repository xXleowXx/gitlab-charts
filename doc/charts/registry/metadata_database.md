# Manage the container registry metadata database **(FREE SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5521) in GitLab 16.4 as a [Beta](https://docs.gitlab.com/ee/policy/experiment-beta-support.html#beta) feature.

The metadata database enables many new registry features, including
online garbage collection, and increases the efficiency of many registry operations.
This page contains information on how to create the database.

## Creating the database

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
