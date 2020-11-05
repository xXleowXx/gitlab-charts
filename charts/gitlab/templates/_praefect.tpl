{{/*
Return the default praefect storage line for gitlab.yml
*/}}
{{- define "gitlab.praefect.storages" -}}
default:
  path: /var/opt/gitlab/repo
  gitaly_address: tcp://{{ template "gitlab.praefect.serviceName" . }}:{{ .Values.global.gitaly.service.externalPort }}
{{- end -}}


{{/*
Return the resolvable name of the praefect service
*/}}
{{- define "gitlab.praefect.serviceName" -}}
{{ $.Release.Name }}-praefect
{{- end -}}
