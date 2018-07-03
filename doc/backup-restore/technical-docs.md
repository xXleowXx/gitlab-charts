# Backup and restore

This document explains the technical implementation of the backup and restore into/from CNG.

## Task runner pod
The [task runner chart](../../charts/gitlab/charts/task-runner) deploys a pod into the cluster that acts as a user interface for running commands that interacts and does changes to the cluster from outside the cluster containers.

Using this pod user can run commands using `kubectl exec -it <pod name> -- <arbitrary command>`

The task runner runs a container from the [task-runner image](https://gitlab.com/gitlab-org/build/CNG/tree/master/gitlab-task-runner).

The image contains some custom scripts that are to be called as commands by the user, these scripts can be found [here](https://gitlab.com/gitlab-org/build/CNG/tree/master/gitlab-task-runner/scripts).

## Backup utility

[Backup utility](https://gitlab.com/gitlab-org/build/CNG/blob/master/gitlab-task-runner/scripts/bin/backup-utility) is one of the scripts
in the task runner container and as the name suggests it is a script used for doing backups and restore.

### Backups

The backup utility script when run without any arguments creates a backup tar and uploads it to object storage. The sequence of execution is:
1. Backup the repositories and database using the [gitlab-ce backup rake task](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/lib/tasks/gitlab/backup.rb)
2. For each of [registry, uploads, artifacts, lfs]
   - tar the existing data in the corresponding object storage bucket naming it `<bucket-name>.tar`
   - Move the tar to the backup location on disk
3. Writes a `backup_information.yml` file which contains some metadata identifying the version of gitlab, the time of the backup and the skipped items if any.
4. Bundle the result of backing up every item into a single tar file along with `backup_information.yml`
5. Upload the resulting tar file to object storage `gitlab-backups` bucket.

### Restore

The backup utility when given an argument `--restore` attempts to restore from an existing backup to the running instance. This
backup can be from either an omnibus or a CNG installation given that both the instance that was
backed up and the running instance runs the same version of gitlab. The restore expects either a `-t <backup-name>` parameter
or a `-f <url>`.

When given a `-t` parameter it looks into `gitlab-backups` bucket in object storage for a backup tar with such name. When
given a `-f` option it expects that the given url is a valid uri of a backup tar which can be placed anywhere accessible from the container.

After fetching the backup tar the sequence of execution is:
1. For repositories and database run the [gitlab-ce backup rake task](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/lib/tasks/gitlab/backup.rb)
2. For each of [registry, uploads, artifacts, lfs]
   - tar the existing data in the corresponding object storage bucket naming it `<backup-name>.tar`
   - upload it to `tmp` bucket in object storage
   - clean up the corresponding bucket
   - restore the backup content into the corresponding bucket

> This means that even if the restore fails user can revert to the data that was backed up in `tmp` bucket. However,
this process until the time of this writing is a manual process.
