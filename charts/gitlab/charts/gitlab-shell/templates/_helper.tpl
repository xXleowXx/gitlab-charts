{{- define "gitlab-shell.labels" -}}
{{ include "gitlab.standardLabels" . }}
{{- if .Values.common.labels }}
{{ merge .Values.common.labels .Values.global.common.labels | toYaml }}
{{- end -}}
{{- end -}}
