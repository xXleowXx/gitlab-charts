{{/* vim: set filetype=mustache: */}}

{{/*
database.datamodel.blank
*/}}
{{- define "database.datamodel.blank" -}}
{{ $psql := deepCopy $.Values.global.psql }}
{{ $_ := unset $psql "knownDecompositions" }}
{{- range $decomposedDatabase := $.Values.global.psql.knownDecompositions }}
{{ $_ := unset $psql $decomposedDatabase }}
{{- end -}}
{{ $psql | toYaml }}
{{- end -}}

{{- define "database.datamodel.configuration" -}}
adapter: postgresql
encoding: unicode
database: {{ template "gitlab.psql.database" . }}
username: {{ template "gitlab.psql.username" . }}
password: "<%= File.read({{ template "gitlab.psql.password.file" . }}).strip.dump[1..-2] %>"
host: {{ include "gitlab.psql.host" . | quote }}
port: {{ template "gitlab.psql.port" . }}
connect_timeout: {{ template "gitlab.psql.connectTimeout" . }}
keepalives: {{ template "gitlab.psql.keepalives" . }}
keepalives_idle: {{ template "gitlab.psql.keepalivesIdle" . }}
keepalives_interval: {{ template "gitlab.psql.keepalivesInterval" . }}
keepalives_count: {{ template "gitlab.psql.keepalivesCount" . }}
tcp_user_timeout: {{ template "gitlab.psql.tcpUserTimeout" . }}
application_name: {{ template "gitlab.psql.applicationName" . }}
prepared_statements: {{ template "gitlab.psql.preparedStatements" . }}
{{- end -}}

{{/*
database.datamodel.prepare
*/}}

{{- define "database.datamodel.prepare" -}}
{{- $blank := fromYaml (include "database.datamodel.blank" $) -}}
{{- if not $.Values.global.psql.main -}}
{{-   $_ := set $.Values.global.psql "main" (deepCopy $blank) -}}
{{- end -}}
{{- range $decomposedDatabase := $.Values.global.psql.knownDecompositions }}
{{/* Now we know we are in main, ci, etc */}}
{{- $globalSchema := get $.Values.global.psql $decomposedDatabase }}
{{- $localSchema := get $.Values.psql $decomposedDatabase | default (dict) }}
{{- $mergedSchema := mergeOverwrite (deepCopy $blank) (deepCopy $globalSchema) (deepCopy $localSchema) }}
{{ $context := dict "Release" $.Release "Values" (dict "global" (dict "psql" $mergedSchema) "psql" (dict) ) }}
{{ $decomposedDatabase -}}:
{{/* $context | toYaml | nindent 2 */}}
{{ include "database.datamodel.configuration" $context | nindent 2 }}
{{- end }}
{{- end -}}
