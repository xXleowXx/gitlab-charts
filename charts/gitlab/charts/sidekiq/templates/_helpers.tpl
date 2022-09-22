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
{{- $allExtraEnv := merge (default (dict) .local.extraEnv) (default (dict) .context.Values.extraEnv) .context.Values.global.extraEnv -}}
{{- range $key, $value := $allExtraEnv }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end -}}
{{- end -}}

{{/*
Returns a list of _common_ labels to be shared across all
Sidekiq deployments and other shared objects, otherwise
known as pods currently.
*/}}
{{- define "sidekiq.commonLabels" -}}
{{- $commonPodLabels := merge (default (dict) .pod) (default (dict) .global) -}}
{{- range $key, $value := $commonPodLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{/*
Returns a list of _pod_ labels to be shared across all
Sidekiq deployments, otherwise known as pods currently.
*/}}
{{- define "sidekiq.podLabels" -}}
{{- $commonPodLabels := default (dict) .pod -}}
{{- range $key, $value := $commonPodLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}

{{/*
Create a datamodel for our common labels
*/}}
{{- define "sidekiq.pod.common.labels" -}}
{{- $default := dict "labels" (dict) -}}
{{- $_ := set . "common" (merge (default (dict) .common) $default) -}}
{{- end -}}

{{/*
Return the sidekiq-metrics TLS secret name
*/}}
{{- define "sidekiq-metrics.tls.secret" -}}
{{- default (printf "%s-sidekiq-metrics-tls" .Release.Name) $.Values.metrics.tls.secretName | quote -}}
{{- end -}}

{{/*
Generates queues based on Sidekiq routing rules if exists.
Otherwise, returns default queues in .Values.queues.

Structure of routingRules is checked thoroughly so it does not panic here, allowing user friendly error message
returned by _checkConfig_sidekiq.tpl in the end.
*/}}
{{- define "sidekiq.queues" -}}
{{- $queues := "" -}}
{{- with $.Values.global.appConfig.sidekiq.routingRules -}}
{{- if . -}}
  {{- $queuesList := list -}}
  {{- if kindIs "slice" . }}
    {{- range $_, $rule := . -}}
      {{- if and (kindIs "slice" $rule) (eq (len $rule) 2) -}}
        {{- $queuesList = append $queuesList (index $rule 1) -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $queuesList = append $queuesList "mailers" -}}
  {{- $queues = join "," $queuesList -}}
{{- end -}}
{{- else -}}
  {{- $queues = $.Values.queues -}}
{{- end -}}
{{- $queues -}}
{{- end -}}