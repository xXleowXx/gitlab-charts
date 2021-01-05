{{/* vim: set filetype=mustache: */}}

{{- define "gitlab.application.labels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- end -}}

{{- define "gitlab.standardLabels" -}}
app: {{ template "name" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- if .Values.global.application.create }}
{{ include "gitlab.application.labels" . }}
{{- end -}}
{{- end -}}

{{- define "gitlab.immutableLabels" -}}
app: {{ template "name" . }}
chart: {{ .Chart.Name }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{ if .Values.global.application.create -}}
{{ include "gitlab.application.labels" . }}
{{- end -}}
{{- end -}}

{{- define "gitlab.commonLabels" -}}
{{- range $key, $value := (merge .Values.common.labels .Values.global.common.labels) }}
{{ $key }}: {{ $value }}
{{- end -}}
{{- end -}}

{{- define "gitlab.commonPodLabels" -}}
{{- range $key, $value := (merge .Values.podLabels .Values.common.labels .Values.global.pod.labels .Values.global.common.labels) }}
{{ $key }}: {{ $value }}
{{- end -}}
{{- end -}}

{{- define "gitlab.commonServiceLabels" -}}
{{ range $key, $value := (merge .Values.serviceLabels .Values.common.labels .Values.global.service.labels .Values.global.common.labels) }}
{{ $key }}: {{ $value }}
{{- end -}}
{{- end -}}
