# Migrating from Docker-based GitLab installation

NOTE: **Note**:
The steps below assume you are using the [default Linux volumes location](https://docs.gitlab.com/omnibus/docker/#set-up-the-volumes-location)
for data stored on your host and that the Docker container is called `gitlab`.
To check what your volume locations are, you can run `sudo docker inspect -f '{{ .Mounts }}' gitlab`.

## Prerequisites

- Deployment using the Docker GitLab image needs to be running. Run
  `sudo docker exec -t gitlab gitlab-ctl status` and confirm no services report
  a `down` state.

- `/srv/gitlab/config/gitlab-secrets.json` file from package based installation.

- A Helm charts based deployment running the same GitLab version as the
  Docker-based GitLab installation.

- Object storage service which the Helm chart based deployment is configured to
  use. For production use, we recommend you use an [external object storage](../../advanced/external-object-storage/index.md)
  and have the login credentials to access it ready. If you are using the built-in
  MinIO service, [read the docs](minio.md) on how to grab the login credentials
  from it.

## Migration Steps

1. Migrate existing files (uploads, artifacts, lfs objects) from Docker based
   installation to object storage:

   1. Modify `/srv/gitlab/config/gitlab.rb` and configure object storage for
      [uploads](https://docs.gitlab.com/ee/administration/uploads.html#s3-compatible-connection-settings),
      [artifacts](https://docs.gitlab.com/ee/administration/job_artifacts.html#s3-compatible-connection-settings)
      and [LFS](https://docs.gitlab.com/ee/workflow/lfs/lfs_administration.html#s3-for-omnibus-installations).

      NOTE: **Note:** This **must** be the same object storage service that the
      Helm charts based deployment is connected to.

   1. Restart the Docker container to apply the changes:

      ```shell
      sudo docker restart gitlab
      ```

   1. Open a interactive shell on the Docker container:

      ```shell
      sudo docker exec -ti gitlab bash
      ```

   1. Migrate existing artifacts to object storage:

      ```shell
      gitlab-rake gitlab:artifacts:migrate
      ```

   1. Migrate existing LFS objects to object storage:

      ```shell
      gitlab-rake gitlab:lfs:migrate
      ```

   1. Migrate existing uploads to object storage:

      ```shell
      gitlab-rake gitlab:uploads:migrate:all
      ```

      For more information, see [migrate to object storage](https://docs.gitlab.com/ee/administration/raketasks/uploads/migrate.html#migrate-to-object-storage).

   1. Exit the interactive shell on the Docker container:

      ```shell
      exit
      ```

   1. Visit the Docker GitLab instance and make sure the
      uploads are available. For example, check if user, group and project
      avatars are rendered fine, image and other files added to issues load
      correctly, etc.

   1. Restart the Docker container. This will recreate empty directories in place,
      so the backup task won't fail:

      ```shell
      sudo docker restart gitlab
      ```

1. [Create a backup](https://docs.gitlab.com/ee/raketasks/backup_restore.html#creating-a-backup-of-the-gitlab-system):

   ```shell
   sudo docker exec -t gitlab gitlab:backup:create SKIP=uploads,lfs,artifacts
   ```

   The backup file will be stored in `/srv/gitlab/data/backups` directory, unless
   [explicitly changed](https://docs.gitlab.com/omnibus/settings/backups.html#manually-manage-backup-directory)
   in `gitlab.rb`.

1. [Restore the backup to Helm chart based deployment](../../backup-restore/restore.md).

1. Follow [official documentation](../../backup-restore/restore.md#restoring-the-secrets)
1. Follow the documentation on how to
   [restore the secrets](../../backup-restore/restore.md#restoring-the-secrets) from a package based installation.

1. Restart all pods to make sure changes are applied:

   ```shell
   kubectl delete pods -lrelease=<helm release name>
   ```

1. Visit the Helm based deployment and confirm projects, groups, users, issues
   etc. that existed in your Docker based installation are restored.
   Also verify if the uploaded files (avatars, files uploaded to issues, etc.)
   are loaded fine.
