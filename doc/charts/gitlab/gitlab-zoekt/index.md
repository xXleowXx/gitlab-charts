---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Using the GitLab-Zoekt chart **(PREMIUM SELF EXPERIMENT)**

FLAG:
On self-managed GitLab, by default this feature is disabled.
To make it available, an administrator can enable the feature flags named `index_code_with_zoekt` and `search_code_with_zoekt`.

WARNING:
This feature is an [Experiment](https://docs.gitlab.com/ee/policy/experiment-beta-support.html#experiment).
GitLab Support cannot assist with configuring or troubleshooting the
`gitlab-zoekt` chart. For more information, see
[exact code search](https://docs.gitlab.com/ee/user/search/exact_code_search.html).

The Zoekt integration provides support for
[exact code search](https://docs.gitlab.com/ee/user/search/exact_code_search.html).
You can install the integration by setting `gitlab-zoekt.install` to `true`.
For more information, see the [`gitlab-zoekt` chart](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt).

## How to enable Zoekt

In order to enable Zoekt integration, you need to set these values:

```shell
--set gitlab-zoekt.install=true \
--set gitlab-zoekt.replicas=2 \         # Number of Zoekt pods. If want to use one, this can be skipped
--set gitlab-zoekt.indexStorage=128Gi   # Zoekt node disk size. Please note that Zoekt uses about x3 of the repository storage
```

## Resources

You might want to also set proper requests/limits. Below you can see current GitLab.com values (as of 2024-01-17), which need to be tuned depending on your use-case:

```yaml
  webserver:
    resources:
      requests:
        cpu: 4
        memory: 32Gi
      limits:
        cpu: 16
        memory: 128Gi
  indexer:
    resources:
      requests:
        cpu: 4
        memory: 6Gi
      limits:
        cpu: 16
        memory: 12Gi
  gateway:
    resources:
      requests:
        cpu: 2
        memory: 512Mi
      limits:
        cpu: 4
        memory: 1Gi
```

## GitLab integration

> Shards [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134717) to nodes in GitLab 16.6.

To enable Zoekt for a top-level group:

1. Connect to the Rails console of the Toolbox Pod:

   ```shell
   kubectl exec <Toolbox pod name> -it -c toolbox -- gitlab-rails console -e production
   ```

1. Enable the Zoekt feature flags:

   ```shell
   ::Feature.enable(:index_code_with_zoekt)
   ::Feature.enable(:search_code_with_zoekt)
   ```

1. Set up indexing:

   ```shell
   # Select one of the zoekt nodes
   node = ::Search::Zoekt::Node.last
   # Use the name of your top-level group
   namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
   enabled_namespace = Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
   node.indices.create!(zoekt_enabled_namespace_id: enabled_namespace.id, namespace_id: namespace.id, state: :ready)
   ```

Zoekt can now index projects after they are updated or created.
