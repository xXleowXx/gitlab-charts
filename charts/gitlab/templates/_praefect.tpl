{{/*
Return the default praefect storage line for gitlab.yml
*/}}
{{- define "gitlab.praefect.storages" -}}
{{- range $.Values.global.praefect.virtualStorages }}
{{ .name }}:
  path: /var/opt/gitlab/repo
  gitaly_address: tcp://{{ template "gitlab.praefect.serviceName" $ }}:{{ $.Values.global.gitaly.service.externalPort }}
{{- end }}
{{- end -}}


{{/*
Return the resolvable name of the praefect service
*/}}
{{- define "gitlab.praefect.serviceName" -}}
{{ $.Release.Name }}-praefect
{{- end -}}
