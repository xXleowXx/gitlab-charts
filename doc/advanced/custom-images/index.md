---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Bringing your own images

In certain scenarios (i.e. air-gapping), you may want to bring your own images rather than pulling them down from the Internet. This requires specifying your own Docker image registry/repository for each of the charts that make up the GitLab release.

## Default image format

Our default format for the image in most cases includes the full path to the image, excluding the tag.

```yaml
image:
  repository: repo.example.com/image
  tag: custom-tag
```

The end result will be `repo.example.com/image:custom-tag`.

## Example values file

Below is an example values file that demonstrates how to configure a custom Docker registry/repository and tag. You can copy relevant sections of this file for your own releases.

NOTE: Note:
Some of the charts (especially third party charts) sometimes have slightly different conventions for specifying the image registry/repository and tag. You can find documentation for third party charts on the [Helm Hub](https://hub.helm.sh/).

  ```yaml
  # Need to set certmanager-issuer.email before templating
  certmanager-issuer:
    email: me@example.com

  # YAML anchor to demonstrate setting image.repository and image.tag
  .custom: &custom
    image:
      repository: custom-repository
      tag: custom-tag

  # --- Global settings ---

  global:
    <<: *custom
    kubectl: *custom
    certificates: *custom
    grafana:
      enabled: true

  # --- GitLab charts ---

  gitlab:
    geo-logcursor: *custom
    gitaly:
      <<: *custom
      init: *custom
    gitlab-exporter:
      <<: *custom
      init: *custom
    gitlab-grafana: *custom
    gitlab-shell:
      <<: *custom
      init: *custom
    mailroom: *custom
    migrations:
      <<: *custom
      init: *custom
    operator: *custom
    sidekiq:
      <<: *custom
      init: *custom
    task-runner:
      <<: *custom
      init: *custom
    webservice:
      <<: *custom
      init: *custom
      workhorse:
        image: custom-repository
        tag: custom-tag

  # --- Charts from requirements.yaml ---

  certmanager:
    <<: *custom
    cainjector: *custom

  gitlab-runner:
    image: custom-repository:custom-tag

  minio:
    image: custom-repository
    imageTag: custom-tag
    init: *custom
    minioMc:
      image: custom-repository
      tag: custom-tag

  nginx-ingress:
    controller: *custom
    defaultBackend: *custom

  registry:
      <<: *custom
      init: *custom

  postgresql:
    global:
      imageRegistry: custom-repository
    image:
      repository: custom-repository
      tag: 11-custom-tag # start with number to make checkConfig happy
    metrics: *custom

  prometheus:
    server: *custom
    configmapReload: *custom

  redis:
    global:
      imageRegistry: custom-repository
    <<: *custom
    metrics: *custom

  upgradeCheck: *custom

  grafana:
    <<: *custom
    sidecar:
      image: custom-repository:custom-tag
  ```
