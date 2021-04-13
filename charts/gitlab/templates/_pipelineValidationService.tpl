{{/*
Generates Pipeline Validation Service (PVS) configuration.

Usage:
{{ include "gitlab.appConfig.pipelineValidationService.configuration" . }}
*/}}
{{- define "gitlab.appConfig.pipelineValidationService.configuration" -}}
pipeline_validation_service:
  {{- if .Values.global.appConfig.pipelineValidationService.url }}
  url: {{ $.Values.global.appConfig.pipelineValidationService.url }}
  {{- end }}
  {{- if .Values.global.appConfig.pipelineValidationService.token }}
  token: {{ $.Values.global.appConfig.pipelineValidationService.token }}
  {{- end }}
  {{- if .Values.global.appConfig.pipelineValidationService.timeout }}
  timeout: {{ $.Values.global.appConfig.pipelineValidationService.timeout }}
  {{- end }}
{{- end -}}{{/* "gitlab.appConfig.pipelineValidationService.configuration" */}}
