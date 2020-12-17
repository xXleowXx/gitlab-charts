{{/* vim: set filetype=mustache: */}}

{{- define "gitlab-shell.labels" -}}
{{ merge .Values.common.labels .Values.global.common.labels | toYaml }}
{{- end -}}

{{- define "gitlab-shell.podLabels" -}}
{{ merge .Values.podLabels .Values.common.labels .Values.global.pod.labels .Values.global.common.labels | toYaml }}
{{- end -}}

{{- define "gitlab-shell.serviceLabels" -}}
{{ merge .Values.serviceLabels .Values.common.labels .Values.global.service.labels .Values.global.common.labels | toYaml }}
{{- end -}}
