{{/* vim: set filetype=mustache: */}}

{{- define "gitlab-shell.labels" -}}
{{- range $key, $value := (merge .Values.common.labels .Values.global.common.labels) -}}
{{ $key }}: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{- define "gitlab-shell.podLabels" -}}
{{ range $key, $value := (merge .Values.podLabels .Values.common.labels .Values.global.pod.labels .Values.global.common.labels) }}
{{ $key }}: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{- define "gitlab-shell.serviceLabels" -}}
{{ range $key, $value := (merge .Values.serviceLabels .Values.common.labels .Values.global.service.labels .Values.global.common.labels) }}
{{ $key }}: {{ $value | quote }}
{{- end -}}
{{- end -}}
