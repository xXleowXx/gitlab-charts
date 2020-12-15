{{- define "gitlab-shell.labels" -}}
{{ include "gitlab.standardLabels" . }}
{{- if .Values.common.labels }}
{{ .Values.common.labels | toYaml }}
{{- end -}}
{{- end -}}
