---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Updating chart dependencies

The GitLab Helm Chart includes dependencies on other bundled Helm Charts. The list of dependencies are managed by the `requirements.yml` file at the root of the repository, and these dependencies are found in the top level `charts` directory.

The charts are broken down into the following categories:

## GitLab sub-charts

The actual GitLab Helm chart source is contained within a series of sub-charts under the `charts/gitlab` chart. See the [GitLab chart architecture](../architecture/architecture.md#the-gitlab-chart) for details. These charts are not considered _dependencies_ but are instead the primary templates for the GitLab Helm Chart.

## Forked charts

Checked-in but modified sources of third-party charts. Follow the [forked charts documentation](../architecture/decisions.md#forked-charts) for details and updating instructions.

## Upstream chart dependencies

These are dependencies bundled into the `charts` folder as `.tgz` files during packaging or prior to a deployment of the source branch, and are downloaded copies of charts available in public repositories. The versions and locations from where these are downloaded is controlled by the `requirements.yml` file.

### Update upstream chart dependency

1. Update the version information in `requirements.yml`
1. Run `helm dependency update` to download the new version of the chart to your local repository, and to update the `requirements.lock` file.
1. Create a new Merge Request with the new files, and the updated `requirements.yml` and `requirements.lock`.
