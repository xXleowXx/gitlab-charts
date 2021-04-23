---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Migrating from GitLab Helm Chart to Omnibus GitLab

## Migration Steps

1. Check your current version of GitLab via the **Admin Area > Components** page.

1. Prepare a clean machine and install Omnibus GitLab version identical to your GitLab Helm chart version by following the guide [Manually download and install a GitLab package](https://docs.gitlab.com/omnibus/manual_install.html).

1. Create [a backup of your GitLab Helm chart instance](https://docs.gitlab.com/charts/backup-restore/backup.html). Make sure to [backup secrets as well](https://docs.gitlab.com/charts/backup-restore/backup.html#backup-the-secrets) as well.

1. backup your `/etc/gitlab/gitlab-secrets.json` on your Omnibus GitLab instance.

1. Use the file `secrets.yaml` obtained from your GitLab Helm chart instance to fill your `/etc/gitlab/gitlab-secrets.json` file on the new Omnibus GitLab instance:

1. Use the file `secrets.yaml` obtained from your GitLab Helm chart instance to fill your `/etc/gitlab/gitlab-secrets.json` file on the new Omnibus GitLab instance:
    1. open it with any text editor available and replace all the secrets in the section `gitlab_rails` with the secrets from the file `secrets.yaml`:
        - Make sure that the values of `secret_key_base`, `db_key_base`, `otp_key_base`, `encrypted_settings_key_base` do not contain line breaks.
        - The values of `openid_connect_signing_key`, `ci_jwt_signing_key` should have \n instead of line breaks, and the entire value should be in one line like this:

            ```shell
            -----BEGIN RSA PRIVATE KEY-----\nprivatekey\nhere\n-----END RSA PRIVATE KEY-----\n
            ```
    1. Run `sudo gitlab-ctl reconfigure` after the secrets are updated.

1. Configure [object storage](https://docs.gitlab.com/ee/administration/object_storage.html) with your Omnibus GitLab instance and make sure it works fine by testing LFS, artifacts, uploads,etc.

1. Sync the data from your object storage connected to the Helm chart instance with to the new storage connected to Omnibus GitLab. For s3-compatible storage it should be possible by copying the data using `s3cmd` utility.

1. Copy the GitLab backup to the folder `/var/opt/gitlab/backups` on your Omnibus GitLab server and perform [the restoration](https://docs.gitlab.com/ee/raketasks/backup_restore.html#restore-for-omnibus-gitlab-installations).

1. After the restoration is completed, run [Doctor Rake tasks](https://docs.gitlab.com/ee/administration/raketasks/doctor.html) to make sure that the secrets are valid.
