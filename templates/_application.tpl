{{- define "gitlab.application.labels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- end -}}

{{- define "gitlab.application.enabled" -}}
{{- if or .Values.global.application.create .Values.global.application.enabled -}}
true
{{- end -}}
{{- end -}}

{{- define "gitlab.standardLabels" -}}
app: {{ template "name" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{ if (include "gitlab.application.enabled" . ) -}}
{{ include "gitlab.application.labels" . }}
{{- end -}}
{{- end -}}

{{- define "gitlab.immutableLabels" -}}
app: {{ template "name" . }}
chart: {{ .Chart.Name }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{ if (include "gitlab.application.enabled" . ) -}}
{{ include "gitlab.application.labels" . }}
{{- end -}}
{{- end -}}
