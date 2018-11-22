# Upgrade Guide

Before upgrading your GitLab installation, you need to check the [change log](https://gitlab.com/charts/gitlab/blob/master/CHANGELOG.md) corresponding to the specific release you want to upgrade to. And look for any [release notes](../releases/index.md) that might pertain to the new GitLab chart version. We also recommend that you take a [backup](https://gitlab.com/charts/gitlab/blob/master/doc/backup-restore/index.md) first. Also note that you need to provide all values using `helm upgrade --set key=value` syntax or `-f values.yml` instead of using `--reuse-values` because some of the current values might be deprecated.

> **NOTE:** You can retrieve your previous `--set` arguments cleanly, with
`helm get values <release name>`. If you direct this into a file
(`helm get values <release name> > gitlab.yaml`), you can safely pass this
file via `-f`. Thus `helm upgrade gitlab gitlab/gitlab -f gitlab.yaml`.
This safely replaces the behavior of `--reuse-values`

Mappings between chart versioning and GitLab versioning can be found [here](./version-mappings.md)

# Steps

The following are the steps to upgrade GitLab to a newer version:

1. Check the [change log](https://gitlab.com/charts/gitlab/blob/master/CHANGELOG.md) for the specific version you would like to upgrade to
1. Go through [deployment documentation](./deployment.md) step by step
1. Extract your previous `--set` arguments with
   ```
   helm get values gitlab > gitlab.yaml
   ```
1. Decide on all the values you need to set
1. If you would like to use the GitLab operator go through the steps outlined in [Operator installation](./operator.md)
1. Perform the upgrade, with all `--set` arguments extracted in step 4
   ```
   helm upgrade gitlab gitlab/gitlab \
     --version <new version> \
     -f gitlab.yaml \
     --set ...
   ```
