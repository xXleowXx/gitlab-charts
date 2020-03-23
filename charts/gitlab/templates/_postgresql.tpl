{{/*
Returns parts for a Gitlab configuration to setup a mutual TLS connection
with the PostgreSQL database.
*/}}
{{- define "gitlab.psql.ssl.config" -}}
{{- if .Values.global.psql.ssl }}
sslmode: {{ .Values.global.psql.ssl.mode | default "verify-ca" | quote }}
{{-   if .Values.global.psql.ssl.serverCA }}
sslrootcert: '/etc/gitlab/postgres/ssl/server-ca.pem'
{{-   end -}}
{{-   if .Values.global.psql.ssl.clientCertificate }}
sslcert: '/etc/gitlab/postgres/ssl/client-certificate.pem'
{{-   end -}}
{{-   if .Values.global.psql.ssl.clientKey }}
sslkey: '/etc/gitlab/postgres/ssl/client-key.pem'
{{-   end -}}
{{- end -}}
{{- end -}}

{{/*
Returns volume definition of a secret containing information required for
a mutual TLS connection.
*/}}
{{- define "gitlab.psql.ssl.volume" -}}
{{- if .Values.global.psql.ssl }}
{{-   if .Values.global.psql.ssl.secret  }}
- name: postgresql-ssl-secrets
  projected:
    defaultMode: 400
    sources:
    - secret:
        name: {{ .Values.global.psql.ssl.secret }}
        items:
          - key: {{ .Values.global.psql.ssl.serverCA }}
            path: server-ca.pem
          - key: {{ .Values.global.psql.ssl.clientCertificate }}
            path: client-certificate.pem
          - key: {{ .Values.global.psql.ssl.clientKey }}
            path: client-key.pem
{{-   end -}}
{{- end -}}
{{- end -}}

{{/*
Returns mount definition for the volume mount definition above.
*/}}
{{- define "gitlab.psql.ssl.volumeMount" -}}
{{- if .Values.global.psql.ssl }}
{{-   if .Values.global.psql.ssl.secret  }}
- name: postgresql-ssl-secrets
  mountPath: '/etc/postgresql/ssl/'
  readOnly: true
{{-   end -}}
{{- end -}}
{{- end -}}

{{/*
Returns a shell script snippet, which extends the script of a configure
container to copy the mutual TLS files to the proper location. Further
it sets the permissions correctly.
*/}}
{{- define "gitlab.psql.ssl.initScript" -}}
{{- if .Values.global.psql.ssl }}
{{-   if .Values.global.psql.ssl.secret  }}
if [ -d /etc/postgresql/ssl ]; then
  mkdir -p /${secret_dir}/postgres/ssl
  cp -v -r -L /etc/postgresql/ssl/* /${secret_dir}/postgres/ssl/
  chmod 600 /${secret_dir}/postgres/ssl/*
  chmod 700 /${secret_dir}/postgres/ssl
fi
{{-   end -}}
{{- end -}}
{{- end -}}
{{/*
Returns the K8s Secret definition for the PostgreSQL password.
*/}}
{{- define "gitlab.psql.secret" -}}
{{- $useSecret := include "gitlab.boolean.local" (dict "local" (pluck "useSecret" (index .Values.psql "password") | first) "global" .Values.global.psql.password.useSecret "default" true) -}}
{{- if $useSecret -}}
- secret:
    name: {{ template "gitlab.psql.password.secret" . }}
    items:
      - key: {{ template "gitlab.psql.password.key" . }}
        path: postgres/psql-password
{{- end -}}
{{- end -}}

{{/*
Returns the quoted path to the file where the PostgreSQL password is stored.
*/}}
{{- define "gitlab.psql.password.file" -}}
{{- $useSecret := include "gitlab.boolean.local" (dict "local" (pluck "useSecret" (index .Values.psql "password") | first) "global" .Values.global.psql.password.useSecret "default" true) -}}
{{- if not $useSecret -}}
{{- pluck "file" (index .Values.psql "password") (.Values.global.psql.password) | first | quote -}}
{{- else -}}
{{- "/etc/gitlab/postgres/psql-password" | quote -}}
{{- end -}}
{{- end -}}
