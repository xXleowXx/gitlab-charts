# See https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/kascfg/config_example.yaml
agent:
  listen:
    address: ":{{ .Values.service.internalPort }}"
    websocket: true
gitlab:
  address: "{{ template "gitlab.workhorse.url" . }}"
  authentication_secret_file: "/etc/kas/.gitlab_kas_secret"
observability:
  listen:
    address: ":{{ .Values.metrics.port }}"
