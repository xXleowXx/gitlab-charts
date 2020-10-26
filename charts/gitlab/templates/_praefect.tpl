{{/*
Return the default praefect storage line for gitlab.yml
*/}}
{{- define "gitlab.praefect.storages" -}}
default:
  path: /var/opt/gitlab/repo
  gitaly_address: {{ template "gitlab.praefect.gitalyAddress" . }}
{{- end -}}


{{/*
Return the gitaly address in the context of praefect being enabled.
If an address for praefect is not provided, either to a load balancer
or directly to a praefect node, then return the service name for the
praefect statefulset to be generated.
*/}}
{{- define "gitlab.praefect.gitalyAddress" -}}
{{- if $.Values.global.praefect.address }}
{{- $.Values.global.praefect.address }}
{{- else -}}
tcp://{{ template "gitlab.praefect.serviceName" . }}:{{ $.Values.global.gitaly.service.externalPort }}
{{- end }}
{{- end -}}


{{/*
Return the resolvable name of the praefect service
*/}}
{{- define "gitlab.praefect.serviceName" -}}
{{ $.Release.Name }}-praefect
{{- end -}}


{{/*
Return a list of Gitaly pod names
*/}}
{{- define "gitlab.praefect.gitalyPodNames" -}}
{{ range until ($.Values.global.praefect.gitalyReplicas | int) }}{{ printf "%s-gitaly-%d" $.Release.Name . }},{{- end}}
{{- end -}}
