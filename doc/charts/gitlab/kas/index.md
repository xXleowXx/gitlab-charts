---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Using the GitLab-Kas chart

The `kas` sub-chart provides a configurable deployment of the [Kubernetes Agent Server](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent#gitlab-kubernetes-agent-server-kas), which is the server-side component of the [GitLab Kubernetes Agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent) implementation.

## Requirements

This chart depends on access to the GitLab API and the Gitaly Servers. An Ingress will be deployed if this chart is enabled.

## Design Choices

The `kas` container used in this chart will use a distroless image for minimal resource consumption. The deployed services will be exposed by an Ingress which will use [WebSocket proxying](https://nginx.org/en/docs/http/websocket.html) to permit communication in long lived connections with the external component [`agentk`](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent#gitlab-kubernetes-agent-agentk), which is its Kubernetes cluster-side agent counterpart.

Furthermore, `kas` will expect the external requests from `agentk` to come through `{GITLAB_HOST/-/kubernetes-agent}`. If you wish to use your own LB infrastructure instead of this chart's Ingress, make sure to provide the same kind of proxy path that `kas` is expecting. See [`kas` chart Ingress template](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/gitlab/charts) for reference.

Follow the link for further information about the [GitLab Kubernetes Agent architecure](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md).

## Configuration

`kas` is deployed turned off by default. To enable it on your GitLab server, use the Helm flag, like: `helm install --set global.kas.enabled=true`.

### Installation command line options

The table below contains all the possible charts configurations that can be supplied to
the `helm install` command using the `--set` flags.

| Parameter                   | Default        | Description                      |
| --------------------------- | -------------- | ---------------------------------|
| `annotations`               | `{}`           | Pod annotations                  |
| `extraContainers`           |                | List of extra containers to include      |
| `image.repository`          | `registry.gitlab.com/gitlab-org/cluster-integration/gitlab-agent/kas` | image repository |
| `image.tag`                 | `v0.0.6`       | Image tag                        |
| `hpa.targetAverageValue`    | `100m`         | Set the autoscaling target value (cpu) |
| `ingress.enabled`           |  `true` if `global.kas.enabled=true` | You can use `kas.ingress.enabled` to explicitly turn it on or off. If not set, you can optionally use `global.ingress.enabled` for the same purpose. |
| `ingress.annotations`       | `{}`           | Ingress annotations              |
| `ingress.tls`               | `{}`           | Ingress tls configuration        |
| `maxReplicas`               | `10`           | HPA `maxReplicas`                |
| `maxUnavailable`            | `1`            | HPA `maxUnavailable`             |
| `minReplicas`               | `2`            | HPA `maxReplicas`                |
| `serviceAccount.annotations`| `{}`       | Service account annotations      |
| `podLabels`                 | `{}`           | Supplemental Pod labels. Will not be used for selectors. |
| `resources.requests.cpu`    | `75m`                 | GitLab Exporter minimum cpu                    |
| `resources.requests.memory` | `100M`                | GitLab Exporter minimum memory                 |
| `service.externalPort`      | `8150`         | External port                    |
| `service.internalPort`      | `8150`         | Internal port                    |
| `service.type`              | `ClusterIP`    | Service type                     |
| `tolerations`               | `[]`           | Toleration labels for pod assignment     |

## Developement (how to manual QA)

1. Install the chart

   Choose the **Short Path** if you have access to `gitlab-paas` GCP project (internal), which will allow you
   to skip almost all the steps since cluster, project and agents are already setup.
   Choose the **Long Path** if you don't have access to `gitlab-paas` GCP project (internal).

   - **Short Path:** setup your local config to talk to this cluster:
   `gcloud container clusters get-credentials kas-chart-qa --zone us-west1-b --project gitlab-paas`. Then checkout the MR working branch and install/upgrade GitLab with `kas` enabled from your local chart branch using `--set global.kas.enabled=true`. E.g.:

   ```shell
   helm upgrade --force --install gitlab . \
     --timeout 600 \
     --set global.hosts.domain=qa.joaocunha.eu \
     --set global.hosts.externalIP=35.227.184.50 \
     --set certmanager-issuer.email=fake.email@gitlab.com \
     --set name=gitlab-instance \
     --set global.kas.enabled=true
   ```

   Check that the deploy was successful and skip to step 6.

   - **Long Path:** create your own GKE cluster. Then checkout the MR working branch and install/upgrade GitLab with `kas` enabled from your local chart branch using `--set global.kas.enabled=true`. E.g.:

   ```shell
   helm upgrade --force --install gitlab . \
     --timeout 600 \
     --set global.hosts.domain=your.domain.com \
     --set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
     --set certmanager-issuer.email=your@email.com \
     --set name=gitlab-instance \
     --set global.kas.enabled=true
   ```

1. Create a project on your GitLab instance to manage your cluster by either importing or copying the contents of [this template project](https://gitlab.qa.joaocunha.eu/root/kas-qa):

1. Create a `Clusters::Agent` and a `Clusters::AgentToken`. **Take note of the generated token, since we'll need it in the next step**.

   To do this you could either run `rails c` or via GraphQL. From `rails c`:

   ```ruby
   project = ::Project.find_by_full_path("root/kas-qa")
   agent = ::Clusters::Agent.create(name: "my-agent", project: project)
   token = ::Clusters::AgentToken.create(agent: agent)
   token.token # this will print out the token you need to use on the next step
   ```

   or using GraphQL:

   with this approach, you'll need a premium license to use this feature.

   ```json
   mutation createAgent {
     createClusterAgent(input: { projectPath: "root/kas-qa", name: "my-agent" }) {
       clusterAgent {
         id
         name
       }
       errors
     }
   }

   mutation createToken {
     clusterAgentTokenCreate(input: { clusterAgentId: <cluster-agent-id-taken-from-the-previous-mutation> }) {
       secret
       token {
         createdAt
         id
       }
       errors
     }
   }
   ```

   Note that GraphQL will only show you the token once, after you've created it. It's the `secret` field.

1. Follow these instructions on installing the [GitLab Kubernetes Agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/build/deployment/gitlab-agent) with the token generated on the previous step.

1. Login with the root user, edit the `manifest.yaml` ConfigMap in the root of your project. If you're using `gitlab-paas`, here is your [`manifest.yaml`](https://gitlab.joaocunha.eu/root/kas-test/-/blob/master/manifest.yaml). Change one of the configs to whatever value you like, for instance increment the `data.game.properties.lives` attr. Wait 30 seconds and check if this config map got correcly updated on your cluster: `kubectl get cm -n agentk game-config -oyaml`
