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

{{/*
Return the service name for Gitaly when Praefect is enabled

Call:

```
include "gitlab.praefect.gitaly.serviceName" (dict "context" $ "name" .name)
```
*/}}
{{- define "gitlab.praefect.gitaly.serviceName" -}}
{{ include "gitlab.gitaly.serviceName" .context }}-{{ .name }}
{{- end -}}

{{/*
Return the qualified service name for a given Gitaly pod.

Call:

```
include "gitlab.praefect.gitaly.qualifiedServiceName" (dict "context" $ "index" $i "name" .name)
```
*/}}
{{- define "gitlab.praefect.gitaly.qualifiedServiceName" -}}
{{- $name := include "gitlab.praefect.gitaly.serviceName" (dict "context" .context "name" .name) -}}
{{ $name }}-{{ .index }}.{{ $name }}
{{- end -}}
