{{/*
Return migration configuration.
*/}}
{{- define "registry.migration.config" -}}
migration:
{{-   if .Values.migration.enabled }}
  enabled: true
{{-   end }}
{{-   if .Values.migration.disablemirrorfs }}
  disablemirrorfs: true
{{-   end }}
{{-   if .Values.migration.rootdirectory }}
  rootdirectory: {{ .Values.migration.rootdirectory }}
{{-   end }}
{{- end -}}