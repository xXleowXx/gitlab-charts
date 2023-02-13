{{/*
The userlist.txt file in pgbouncer contains the database users and their passwords,
used to authenticate the client agains PostgreSQL.

For further information, check https://www.pgbouncer.org/config.html#authentication-file-format
*/}}

{{ define "userlist.txt" }}
{{- range $k, $v := .Values.userlist }}
  {{ $k | quote }} {{ $v | quote }}
{{- end }}
{{ end }}