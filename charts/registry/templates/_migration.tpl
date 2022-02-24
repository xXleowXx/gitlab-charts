{{/*
Return migration configuration.
*/}}
{{- define "registry.migration.config" -}}
migration:
  enabled: {{ .Values.migration.enabled | eq true }}
{{-   if .Values.migration.disablemirrorfs }}
  disablemirrorfs: true
{{-   end }}
{{-   if .Values.migration.rootdirectory }}
  rootdirectory: {{ .Values.migration.rootdirectory }}
{{-   end }}
{{-   if .Values.migration.importtimeout }}
  importtimeout: {{ .Values.migration.importtimeout }}
{{-   end }}
{{-   if .Values.migration.preimporttimeout }}
  preimporttimeout: {{ .Values.migration.preimporttimeout }}
{{-   end }}
{{-   if .Values.migration.tagconcurrency }}
  tagconcurrency: {{ .Values.migration.tagconcurrency }}
{{-   end }}
{{-   if .Values.migration.maxconcurrentimports }}
  maxconcurrentimports: {{ .Values.migration.maxconcurrentimports }}
{{-   end }}
{{- end -}}