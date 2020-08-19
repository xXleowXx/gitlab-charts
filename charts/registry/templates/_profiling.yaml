{{/*
Return the registry's profiling credentials secret name
*/}}
{{- define "gitlab.registry.profiling.stackdriver.credentials.secret" -}}
{{- default (printf "%s-registry-profiling-creds" .Release.Name) .Values.profiling.stackdriver.credentials.secret | quote -}}
{{- end -}}

{{/*
Return the registry's profiling credentials secret key
*/}}
{{- define "gitlab.registry.profiling.stackdriver.credentials.key" -}}
{{- default "credentials" .Values.profiling.stackdriver.credentials.key | quote -}}
{{- end -}}

{{/*
Construct a default registry profiling service name, if not supplied
*/}}
{{- define "gitlab.registry.profiling.stackdriver.service" -}}
{{- default (printf "%s-container-registry" .Release.Name) .Values.profiling.stackdriver.service | quote -}}
{{- end -}}
