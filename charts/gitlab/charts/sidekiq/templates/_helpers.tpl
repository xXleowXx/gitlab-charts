{{/* vim: set filetype=mustache: */}}

{{/*
Returns the extraEnv keys and values to inject into containers. Allows
pod-level values for extraEnv.

Takes a dict with `local` being the pod-level configuration and `parent`
being the chart-level configuration.

Pod values take precedence, then chart values, and finally global
values.
*/}}
{{- define "sidekiq.podExtraEnv" -}}
{{- $allExtraEnv := merge (default (dict) .local.extraEnv) (default (dict) .parent.Values.extraEnv) .parent.Values.global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of labels to be shared across all
Sidekiq deployments, otherwise known as pods currently.
*/}}
{{- define "sidekiq.commonPodLabels" -}}
{{/* include "sidekiq.podExtraEnv" (dict "local" . "parent" $) */}}
{{- $commonPodLabels := merge (default (dict) .commonLabels) (default (dict) .podLabels) -}}
{{- range $key, $value := $commonPodLabels }}
{{ $key }}: {{ $value }}
{{- end }}
{{- end -}}
