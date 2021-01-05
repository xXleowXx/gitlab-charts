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
{{- $commonLabels := (merge .Values.common.labels .Values.global.common.labels) }}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{ $key }}: {{ $value }}
{{-   end }}
{{- end -}}
{{- end -}}

{{- define "gitlab.commonPodLabels" -}}
{{- $commonPodLabels := (merge .Values.podLabels .Values.common.labels .Values.global.pod.labels .Values.global.common.labels) }}
{{- if $commonPodLabels }}
{{-   range $key, $value := $commonPodLabels }}
{{ $key }}: {{ $value }}
{{-   end }}
{{- end -}}
{{- end -}}

{{- define "gitlab.commonServiceLabels" -}}
{{ $commonServiceLabels := (merge .Values.serviceLabels .Values.common.labels .Values.global.service.labels .Values.global.common.labels) }}
{{- if $commonServiceLabels }}
{{   range $key, $value := $commonServiceLabels }}
{{ $key }}: {{ $value }}
{{-   end }}
{{- end -}}
{{- end -}}
