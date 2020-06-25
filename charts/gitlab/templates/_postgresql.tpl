{{/*
Returns parts for a Gitlab configuration to setup a mutual TLS connection
with the PostgreSQL database.
*/}}
{{- define "gitlab.psql.ssl.config" -}}
{{- if .Values.global.psql.ssl }}
sslmode: verify-ca
sslrootcert: '/etc/gitlab/postgres/ssl/server-ca.pem'
sslcert: '/etc/gitlab/postgres/ssl/client-certificate.pem'
sslkey: '/etc/gitlab/postgres/ssl/client-key.pem'
{{- end -}}
{{- end -}}

{{/*
Returns volume definition of a secret containing information required for
a mutual TLS connection.
*/}}
{{- define "gitlab.psql.ssl.volume" -}}
{{- if .Values.global.psql.ssl }}
- name: postgresql-ssl-secrets
  projected:
    defaultMode: 400
    sources:
    - secret:
        name: {{ .Values.global.psql.ssl.secret | required "Missing required secret containing SQL SSL certificates and keys. Make sure to set `global.psql.ssl.secret`" }}
        items:
          - key: {{ .Values.global.psql.ssl.serverCA | required "Missing required key name of SQL server certificate. Make sure to set `global.psql.ssl.serverCA`" }}
            path: server-ca.pem
          - key: {{ .Values.global.psql.ssl.clientCertificate | required "Missing required key name of SQL client certificate. Make sure to set `global.psql.ssl.clientCertificate`" }}
            path: client-certificate.pem
          - key: {{ .Values.global.psql.ssl.clientKey | required "Missing required key name of SQL client key file. Make sure to set `global.psql.ssl.clientKey`" }}
            path: client-key.pem
{{- end -}}
{{- end -}}

{{/*
Returns mount definition for the volume mount definition above.
*/}}
{{- define "gitlab.psql.ssl.volumeMount" -}}
{{- if .Values.global.psql.ssl }}
- name: postgresql-ssl-secrets
  mountPath: '/etc/postgresql/ssl/'
  readOnly: true
{{- end -}}
{{- end -}}

{{/*
Returns a shell script snippet, which extends the script of a configure
container to copy the mutual TLS files to the proper location. Further
it sets the permissions correctly.
*/}}
{{- define "gitlab.psql.ssl.initScript" -}}
{{- if .Values.global.psql.ssl }}
if [ -d /etc/postgresql/ssl ]; then
  mkdir -p /${secret_dir}/postgres/ssl
  cp -v -r -L /etc/postgresql/ssl/* /${secret_dir}/postgres/ssl/
  chmod 600 /${secret_dir}/postgres/ssl/*
  chmod 700 /${secret_dir}/postgres/ssl
fi
{{- end -}}
{{- end -}}

{{- define "gitlab.psql.secret" -}}
{{- $vals := deepCopy $.Values.global.psql -}}
{{- if hasKey .Values "psql" -}}
{{- $vals = $vals | merge .Values.psql }}
{{- end -}}
{{- if or ($vals.password.useSecret) (not (hasKey $vals.password "useSecret")) -}}
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
{{- $vals := deepCopy $.Values.global.psql -}}
{{- if hasKey .Values "psql" -}}
{{- $vals = $vals | merge .Values.psql }}
{{- end -}}
{{- if and (not $vals.password.useSecret) (hasKey $vals.password "useSecret") -}}
{{- $vals.password.file | quote -}}
{{- else -}}
{{- "/etc/gitlab/postgres/psql-password" | quote -}}
{{- end -}}
{{- end -}}
