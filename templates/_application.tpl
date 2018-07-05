{{- define "gitlab.application.labels" -}}
{{ if .Values.global.application.name -}}
app.kubernetes.io/name: {{ .Values.global.application.name }}
{{- end -}}
{{- end -}}

{{- define "gitlab.standardLabels" -}}
app: {{ template "name" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{ include "gitlab.application.labels" . }}
{{- end -}}

{{- define "gitlab.immutableLabels" -}}
app: {{ template "name" . }}
chart: {{ .Chart.Name }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{ include "gitlab.application.labels" . }}
{{- end -}}
