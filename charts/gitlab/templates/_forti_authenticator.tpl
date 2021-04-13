{{- define "gitlab.appConfig.fortiAuthenticator.configuration" -}}
{{ with $.Values.global.appConfig }}
forti_authenticator:
  enabled: {{ .fortiAuthenticator.enabled }}
  {{- if .fortiAuthenticator.host }}
  host: {{ .fortiAuthenticator.host }}
  {{- end }}
  {{- if .fortiAuthenticator.port }}
  port: {{ .fortiAuthenticator.port }}
  {{- end }}
  {{- if .fortiAuthenticator.username }}
  username: {{ .fortiAuthenticator.username | quote }}
  {{- end }}
  {{- if .fortiAuthenticator.access_token }}
  access_token: "<%= File.read('/etc/gitlab/forti_authenticator/forti_authenticator_access_token').strip.dump[1..-2] %>"
  {{- end }}
{{- end -}}
{{- end -}}{{/* "gitlab.appConfig.fortiAuthenticator.configuration" */}}

{{- define "gitlab.appConfig.fortiAuthenticator.mountSecrets" -}}
{{ with $.Values.global.appConfig }}
{{- if .fortiAuthenticator.enabled -}}
- secret:
    name: {{ template "gitlab.fortiAuthenticator.accessToken.secret" . }}
    items:
      - key: {{ template "gitlab.fortiAuthenticator.accessToken.key" . }}
        path: forti_authenticator/forti_authenticator_access_token
{{- end -}}
{{- end }}
{{- end -}}{{/* "gitlab.appConfig.fortiAuthenticator.mountSecrets" */}}

{{- define "gitlab.fortiAuthenticator.accessToken.secret" -}}
{{- default (printf "%s-forti_authenticator-secret" .Release.Name) $.Values.global.fortiAuthenticator.accessToken.secret | quote -}}
{{- end -}}

{{- define "gitlab.fortiAuthenticator.accessToken.key" -}}
{{- default "shared_secret" $.Values.global.fortiAuthenticator.accessToken.key | quote -}}
{{- end -}}
