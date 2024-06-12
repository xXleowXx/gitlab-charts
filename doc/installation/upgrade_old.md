---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrade old versions

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Upgrade instructions for older versions are available on this page.

If you are looking to upgrade a recent version of the GitLab chart, see the [Upgrade Guide](upgrade.md).

## Upgrade to version 5.9

### Sidekiq pod never becomes ready

Upgrading to `5.9.x` may lead to a situation where the Sidekiq pod does not become ready. The pod starts and appears to work properly but never listens on the `3807`, the default metrics endpoint port (`metrics.port`). As a result, the Sidekiq pod is not considered to be ready.

This can be resolved from the **Admin Area**:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Metrics and profiling**.
1. Expand **Metrics - Prometheus**.
1. Ensure that **Enable health and performance metrics endpoint** is enabled.
1. Restart the affected pods.

There is additional conversation about this scenario in a [closed issue](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3198).

## Upgrade to version 5.5

The `task-runner` chart [was renamed](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2099/diffs)
to `toolbox` and removed in `5.5.0`. As a result, any mention of `task-runner`
in your configuration should be renamed to `toolbox`. In version 5.5 and newer,
use the `toolbox` chart, and in version 5.4 and older, use the `task-runner` chart.

### Missing object storage secret error

Upgrading to 5.5 or newer might cause an error similar to the following:

```shell
Error: UPGRADE FAILED: execution error at (gitlab/charts/gitlab/charts/toolbox/templates/deployment.yaml:227:23): A valid backups.objectStorage.config.secret is needed!
```

If the secret mentioned in the error already exists and is correct, then this error
is likely because there is an object storage configuration value that still references
`task-runner` instead of the new `toolbox`. Rename `task-runner` to `toolbox` in your
configuration to fix this.

There is an [open issue about clarifying the error message](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3004).

## Upgrade to version 5.0

WARNING:
If you are upgrading from the `4.x` version of the chart to the latest `5.0` release, you need
to first update to the latest `4.12.x` patch release in order for the upgrade to work.
The [5.0 release notes](../releases/5_0.md) describe the supported upgrade path.

The `5.0.0` release requires manual steps in order to perform the upgrade. If you're using the
bundled PostgreSQL, the best way to perform this upgrade is to back up your old database, and
restore into a new database instance.

WARNING:
Remember to make a [backup](../backup-restore/index.md)
before proceeding with the upgrade. Failure to perform these steps as documented **may** result in
the loss of your database. Ensure you have a separate backup.

If you are using an external PostgreSQL database, you should first upgrade the database to version 12 or greater. Then
follow the [standard upgrade steps](upgrade.md#steps).

If you are using the bundled PostgreSQL database, you should follow the [bundled database upgrade steps](database_upgrade.md#steps-for-upgrading-the-bundled-postgresql).

### Troubleshooting 5.0 release upgrade process

- If you see any failure during the upgrade, it may be useful to check the description of `gitlab-upgrade-check` pod for details:

  ```shell
  kubectl get pods -lrelease=RELEASE,app=gitlab
  kubectl describe pod <gitlab-upgrade-check-pod-full-name>
  ```

## Upgrade the bundled PostgreSQL to version 12

As part of the `5.0.0` release of this chart, we upgraded the bundled PostgreSQL version from `11.9.0` to `12.7.0`. This is
not a drop in replacement. Manual steps need to be performed to upgrade the database.
The steps have been documented in the [5.0 upgrade steps](#upgrade-to-version-50).
