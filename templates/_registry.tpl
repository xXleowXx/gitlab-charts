{{/* ######### Registry related templates */}}

{{/*
Return the registry certificate secret name
*/}}
{{- define "gitlab.registry.certificate.secret" -}}
{{- default (printf "%s-registry-secret" .Release.Name) .Values.global.registry.certificate.secret | quote -}}
{{- end -}}

{{/*
Return the registry's httpSecert secret name
*/}}
{{- define "gitlab.registry.httpSecret.secret" -}}
{{- default (printf "%s-registry-httpsecret" .Release.Name) .Values.global.registry.httpSecret.secret | quote -}}
{{- end -}}

{{/*
Return the registry's httpSecert secret key
*/}}
{{- define "gitlab.registry.httpSecret.key" -}}
{{- default "secret" .Values.global.registry.httpSecret.key | quote -}}
{{- end -}}

{{/*
Return database configuration, if enabled.
*/}}
{{- define "registry.database.config" -}}
{{- if .Values.global.registry.database.enabled }}
database:
  enabled: true
  host: {{ default (include "gitlab.psql.host" .) .Values.global.registry.database.host | quote }}
  port: {{ default (include "gitlab.psql.port" .) .Values.global.registry.database.port }}
  user: {{ .Values.global.registry.database.user }}
  password: "DB_PASSWORD_FILE"
  dbname: {{ .Values.global.registry.database.name }}
  sslmode: {{ .Values.global.registry.database.sslmode }}
  {{- if .Values.global.registry.database.ssl }}
  sslcert: /etc/docker/registry/ssl/client-certificate.pem
  sslkey: /etc/docker/registry/ssl/client-key.pem
  sslrootcert: /etc/docker/registry/ssl/server-ca.pem
  {{- end }}
  {{- if .Values.global.registry.database.connecttimeout }}
  connecttimeout: {{ .Values.global.registry.database.connecttimeout }}
  {{- end }}
  {{- if .Values.global.registry.database.draintimeout }}
  draintimeout: {{ .Values.global.registry.database.draintimeout }}
  {{- end }}
  {{- if .Values.global.registry.database.preparedstatements }}
  preparedstatements: true
  {{- end }}
  {{- if .Values.global.registry.database.pool }}
  pool:
    {{- if .Values.global.registry.database.pool.maxidle }}
    maxidle: {{ .Values.global.registry.database.pool.maxidle }}
    {{- end }}
    {{- if .Values.global.registry.database.pool.maxopen }}
    maxopen: {{ .Values.global.registry.database.pool.maxopen }}
    {{- end }}
    {{- if .Values.global.registry.database.pool.maxlifetime }}
    maxlifetime: {{ .Values.global.registry.database.pool.maxlifetime }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Returns Registry's database secret name
*/}}
{{- define "gitlab.registry.dbSecret.secret" -}}
{{ default (printf "%s-registry-dbsecret" .Release.Name) .Values.global.registry.database.password.secret }}
{{- end -}}

{{/*
Return Registry's database secret key
*/}}
{{- define "gitlab.registry.dbSecret.key" -}}
{{- default "secret" .Values.global.registry.database.password.key | quote -}}
{{- end -}}

{{/*
Return Praefect's database secret entry as a projected volume
*/}}
{{- define "gitlab.registry.dbSecret.projectedVolume" -}}
- secret:
    name: {{ include "gitlab.registry.dbSecret.secret" . }}
    items:
      - key: {{ include "gitlab.registry.dbSecret.key" . }}
        path: database_password
{{- end -}}

{{/*
Return PostgreSQL SSL secret name
*/}}
{{- define "gitlab.registry.psql.ssl.secret" -}}
{{ default .Values.global.psql.ssl.secret .Values.global.registry.database.ssl.secret | required "Missing required secret containing SQL SSL certificates and keys. Make sure to set `registry.database.ssl.secret`" }}
{{- end -}}

{{/*
Return PostgreSQL SSL client certificate secret key
*/}}
{{- define "gitlab.registry.psql.ssl.clientCertificate" -}}
{{ default .Values.global.psql.ssl.serverCA .Values.global.registry.database.ssl.clientCertificate | required "Missing required key name of SQL client certificate. Make sure to set `registry.database.ssl.clientCertificate`" }}
{{- end -}}

{{/*
Return PostgreSQL SSL client key secret key
*/}}
{{- define "gitlab.registry.psql.ssl.clientKey" -}}
{{ default .Values.global.psql.ssl.clientKey .Values.global.registry.database.ssl.clientKey | required "Missing required key name of SQL client key file. Make sure to set `registry.database.ssl.clientKey`" }}
{{- end -}}

{{/*
Return PostgreSQL SSL server CA secret key
*/}}
{{- define "gitlab.registry.psql.ssl.serverCA" -}}
{{ default .Values.global.psql.ssl.serverCA .Values.global.registry.database.ssl.serverCA | required "Missing required key name of SQL server certificate. Make sure to set `registry.database.ssl.serverCA`" }}
{{- end -}}

{{/*
Returns the K8s Secret definition for a PostgreSQL mutual TLS connection.
*/}}
{{- define "gitlab.registry.psql.ssl" -}}
{{-   if or .Values.global.registry.database.ssl .Values.global.psql.ssl }}
- secret:
    name: {{ include "gitlab.registry.psql.ssl.secret" . }}
    items:
      - key: {{ include "gitlab.registry.psql.ssl.clientCertificate" . }}
        path: ssl/client-certificate.pem
      - key: {{ include "gitlab.registry.psql.ssl.clientKey" . }}
        path: ssl/client-key.pem
      - key: {{ include "gitlab.registry.psql.ssl.serverCA" . }}
        path: ssl/server-ca.pem
{{-   end -}}
{{- end -}}

{{/*
Return the registry's notification secret name
*/}}
{{- define "gitlab.registry.notificationSecret.secret" -}}
{{- default (printf "%s-registry-notification" .Release.Name) .Values.global.geo.registry.syncSecret.secret | quote -}}
{{- end -}}

{{/*
Return the registry's notification secret key
*/}}
{{- define "gitlab.registry.notificationSecret.key" -}}
{{- default "secret" .Values.global.geo.registry.syncSecret.key | quote -}}
{{- end -}}

{{/*
Return the registry's notification mount
*/}}
{{- define "gitlab.registry.notificationSecret.mount" -}}
{{ if and .Values.global.geo.enabled .Values.global.geo.registry.syncEnabled }}
- secret:
    name: {{ template "gitlab.registry.notificationSecret.secret" $ }}
    items:
      - key: {{ template "gitlab.registry.notificationSecret.key" $ }}
        path: registry/notificationSecret
{{ end }}
{{- end -}}

{{/*
When Geo + Container Registry syncing enabled, adds the following notifier
*/}}
{{- define "global.geo.registry.syncNotifier" -}}
{{- if and .Values.global.geo.enabled .Values.global.geo.registry.syncEnabled -}}
endpoints:
  - name: geo_event
    url: https://{{ "registry.hostname" }}/api/v4/container_registry_event/events
    timeout: 2s
    threshold: 5
    backoff: 1s
    headers:
      Authorization:
        secret: {{ template "gitlab.registry.notificationSecret.secret" $ }}
        key: {{ template "gitlab.registry.notificationSecret.key" $ }}
{{- end -}}
{{- end -}}
