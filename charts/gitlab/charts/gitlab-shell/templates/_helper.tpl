{{/* vim: set filetype=mustache: */}}

{{- define "gitlab-shell.labels" -}}
{{- range $key, $value := .Values.common.labels }}
{{ $key }}: {{ $value }}
{{- end -}}
{{- end -}}

{{- define "gitlab-shell.podLabels" -}}
{{ range $key, $value := (merge .Values.podLabels .Values.common.labels) }}
{{ $key }}: {{ $value }}
{{- end -}}
{{- end -}}

{{- define "gitlab-shell.serviceLabels" -}}
{{ range $key, $value := (merge .Values.serviceLabels .Values.common.labels) }}
{{ $key }}: {{ $value }}
{{- end -}}
{{- end -}}
