{{/*
Generates a templated config for dependencyProxy keys in gitlab.yml.

Usage:
{{ include "gitlab.appConfig.dependencyProxy.configuration" ( \
     dict                                             \
         "config" .Values.path.to.dependencyProxy.config      \
         "context" $                                  \
     ) }}
*/}}
{{- define "gitlab.appConfig.dependencyProxy.configuration" -}}
dependency_proxy:
  enabled: {{ if kindIs "bool" .config.enabled }}{{ eq .config.enabled true }}{{ end }}
  {{- include "gitlab.appConfig.objectStorage.configuration" (dict "name" "dependencyProxy" "config" .config "context" .context) | nindent 2 }}
{{- end -}}{{/* "gitlab.appConfig.dependencyProxy.configuration" */}}
