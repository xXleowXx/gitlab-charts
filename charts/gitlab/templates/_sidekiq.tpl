{{/*
Generates sidekiq (client) configuration.

Usage:
{{ include "gitlab.appConfig.sidekiq.configuration" $ }}
*/}}
{{- define "gitlab.appConfig.sidekiq.configuration" -}}
{{- with $.Values.global.appConfig.sidekiq }}
sidekiq:
{{- if kindIs "slice" .routingRules }}
  {{- if eq (len .routingRules) 0 }}
  routing_rules: []
  {{- else }}
  routing_rules:
    {{- range $rule := .routingRules }}
    {{- if and (kindIs "slice" $rule) (eq (len $rule) 2) }}
    - {{ toJson $rule }}
    {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end -}}{{/* "gitlab.appConfig.sentry.configuration" */}}
