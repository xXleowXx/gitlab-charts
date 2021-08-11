{{/* vim: set filetype=mustache: */}}

{{/*
database.datamodel.blank

Called with context of `.Values[.global].psql`.

Returns a deepCopy of context, with some keys removed.

Removed:
  - all .knownDecompositions [main, ci, ...]
*/}}
{{- define "database.datamodel.blank" -}}
{{- $psql := deepCopy . -}}
{{- $_ := unset $psql "knownDecompositions" -}}
{{- range $decomposedDatabase := .knownDecompositions -}}
{{-   $_ := unset $psql $decomposedDatabase -}}
{{- end -}}
{{ $psql | toYaml }}
{{- end -}}

{{/*
database.datamodel.prepare

Result:
  `.Values.local.psql` contains a fully composed datamodel of psql properties
  to be passed as the context to other helpers. Which Schema you are in can
  be found via `.Schema`.

How:
  - mergeOverwrite `.global.psql` `.global.psql.x`
  - mergeOverwrite `.psql` `.psql.x`
  - build $context dict, with .Release .Values.global.psql .Values.psql 

Example object -
  local:
    psql:
      main:
        Schema: main
        Release: # pointer to $.Release
        Values:
          global:
            psql: # mirrored from .Values.global.psql
          psql:   # mirrored from .Values.psql
      ci:
        Schema: ci
        Release: # pointer to $.Release
        Values:
          global:
            psql: # mirrored from .Values.global.psql
          psql:   # mirrored from .Values.psql
*/}}
{{- define "database.datamodel.prepare" -}}
{{- $globalBlank := fromYaml (include "database.datamodel.blank" $.Values.global.psql) -}}
{{- $_ := set $.Values.global.psql "main" (default (deepCopy $globalBlank) (get $.Values.global.psql "main")) -}}
{{- $_ := set $.Values.psql "knownDecompositions" $.Values.global.psql.knownDecompositions -}}
{{- $localBlank := fromYaml (include "database.datamodel.blank" $.Values.psql) -}}
{{- $_ := set $.Values.psql "main" (default (deepCopy $localBlank) (get $.Values.psql "main")) -}}
{{- $_ := set $.Values "local" ($.Values.local | default (dict "psql" (dict))) -}}
{{- range $decomposedDatabase := $.Values.global.psql.knownDecompositions -}}
{{-   if or (hasKey $.Values.global.psql $decomposedDatabase) (hasKey $.Values.psql $decomposedDatabase) -}}
{{-     $globalSchema := mergeOverwrite (deepCopy $globalBlank) (get $.Values.global.psql $decomposedDatabase | default (dict)) -}}
{{-     $localSchema := mergeOverwrite (deepCopy $localBlank) (get $.Values.psql $decomposedDatabase | default (dict)) -}}
{{-     $context := dict "Schema" $decomposedDatabase "Release" $.Release "Values" (dict "global" (dict "psql" $globalSchema) "psql" ($localSchema) ) -}}
{{-     $_ := set $.Values.local.psql $decomposedDatabase $context -}}
{{-   end -}}
{{- end -}}
{{- end -}}
