{{/*
Returns the K8s Secret definition for the PostgreSQL password.
*/}}
{{- define "gitlab.registry.psql.secret" -}}
- secret:
    name: {{ default (include "gitlab.psql.password.secret" . ) .Values.database.password.secret }}
    items:
      - key: {{ .Values.database.password.key }}
        path: database_password
{{- end -}}

{{/*
Returns the K8s Secret definition for a PostgreSQL mutual TLS connection.
*/}}
{{- define "gitlab.registry.psql.ssl" -}}
{{-   if or .Values.database.ssl .Values.global.psql.ssl }}
- secret:
    name: {{ default .Values.global.psql.ssl.secret .Values.database.ssl.secret | required "Missing required secret containing SQL SSL certificates and keys. Make sure to set `registry.database.ssl.secret`" }}
    items:
      - key: {{ default .Values.global.psql.ssl.serverCA .Values.database.ssl.clientCertificate | required "Missing required key name of SQL client certificate. Make sure to set `registry.database.ssl.clientCertificate`" }}
        path: client-certificate.pem
      - key: {{ default .Values.global.psql.ssl.clientKey .Values.database.ssl.clientKey | required "Missing required key name of SQL client key file. Make sure to set `registry.database.ssl.clientKey`" }}
        path: client-key.pem
      - key: {{ default .Values.global.psql.ssl.serverCA .Values.database.ssl.serverCA | required "Missing required key name of SQL server certificate. Make sure to set `registry.database.ssl.serverCA`" }}
        path: server-ca.pem
{{-   end -}}
{{- end -}}