{{/* ######### Gitaly related templates */}}

{{/*
Return the gitaly secret name
Preference is local, global, default (`gitaly-secret`)
*/}}
{{- define "gitlab.gitaly.authToken.secret" -}}
{{- coalesce .Values.global.gitaly.authToken.secret (printf "%s-gitaly-secret" .Release.Name) | quote -}}
{{- end -}}

{{/*
Return the gitaly secret key
Preference is local, global, default (`token`)
*/}}
{{- define "gitlab.gitaly.authToken.key" -}}
{{- coalesce .Values.global.gitaly.authToken.key "token" | quote -}}
{{- end -}}

{{/*
Return the gitaly TLS secret name
*/}}
{{- define "gitlab.gitaly.tls.secret" -}}
{{- default (printf "%s-gitaly-tls" .Release.Name) .Values.global.gitaly.tls.secretName | quote -}}
{{- end -}}

{{/*
Return the gitaly service name

Order of operations:
- chart-local gitaly service name override
- global gitaly service name override
- derived from chart name

Call:

```
name: {{ include "gitlab.gitaly.serviceName" (dict "context" $ "name" .name) }}
```
*/}}
{{- define "gitlab.gitaly.serviceName" -}}
{{- coalesce .context.Values.gitaly.serviceName .context.Values.global.gitaly.serviceName (printf "%s-gitaly-%s" .context.Release.Name .name) -}}
{{- end -}}

{{/*
Return a qualified gitaly service name, for direct access to the gitaly headless service endpoint of a pod.

Call:

```
{{- include "gitlab.gitaly.qualifiedServiceName" (dict "context" . "index" $i)-}}
```
*/}}
{{- define "gitlab.gitaly.qualifiedServiceName" -}}
{{- $storageName := default (.context.Values.global.gitaly.internal.names | first) .context.name -}}
{{- $name := include "gitlab.gitaly.serviceName" (dict "context" .context "name" $storageName) -}}
{{ printf "%s-%d.%s" $name .index $name }}
{{- end -}}
