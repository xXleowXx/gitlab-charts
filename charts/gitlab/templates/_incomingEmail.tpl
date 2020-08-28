{{- define "gitlab.appConfig.incoming_email" -}}
incoming_email:
  {{- with .incomingEmail }}
  enabled: {{ eq .enabled true }}
  address: {{ .address | quote }}
  user: {{ .user }}
  password: "<%= File.read("/etc/gitlab/incomingEmail/password").strip.dump[1..-2] %>"
  host: {{ .host }}
  port: {{ .port }}
  ssl: {{ .ssl }}
  start_tls: {{ .startTls }}
  mailbox: {{ .mailbox }}
  idle_timeout: {{ .idleTimeout }}
  {{- if ne .logger.logPath "" }}
  log_path: "{{ .logger.logPath }}"
  {{- end }}
  expunge_deleted: {{ .expungeDeleted }}
  {{- end }}
{{- end -}}{{/* "gitlab.appConfig.incoming_email" */}}

{{- define "gitlab.appConfig.incoming_email.mountSecrets" -}}
{{- if $.Values.global.appConfig.incomingEmail.enabled }}
# mount secrets for incoming_email
- secret:
    name: {{ $.Values.global.appConfig.incomingEmail.password.secret | required "Missing required secret containing the IMAP password for incoming email. Make sure to set `global.appConfig.incomingEmail.password.secret`" }}
    items:
      - key: {{ $.Values.global.appConfig.incomingEmail.password.key }}
        path: incomingEmail/password
{{- end }}
{{- end -}}{{/* "gitlab.appConfig.incoming_email.mountSecrets" */}}
