---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Manually configure GitLab Pages access control

This document intends to provide documentation on how to enable
[GitLab Pages access control](https://docs.gitlab.com/ee/administration/pages/index.html#access-control)
manually, while we wait for [out-of-the box support to be implemented](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2443).

## Requirements

1. GitLab 13.8 or later instance with GitLab Pages enabled, deployed using
   this chart and running successfully.

## Steps to follow

1. Add GitLab Pages as a [client application](https://docs.gitlab.com/ee/integration/oauth_provider.html#oauth-applications-in-the-admin-area)
   to use GitLab OAuth service.

    1. Callback URL should be `http(s)://projects.<pages domain>/auth`.

1. Take a note of the application ID and secret displayed on the screen.

1. Create a secret with these credentials, with application ID under the `appid`
   key and secret under the `appsecret` keys.

   ```shell
   kubectl create secret generic <secret name> --from-literal="appid=<application id>" --from-literal="appsecret=<application secret>"
   ```

1. Specify the secret to Pages access control settings by deploying the charts
   again to the cluster with the following configuration added

   ```yaml
   global:
     pages:
       accessControl: true
     gitlabAuth:
       pages:
         secret: <secret name>
   ```
