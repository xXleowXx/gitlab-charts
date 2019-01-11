{{- define "gitlab.appConfig.ldap.configuration" -}}
{{- if not .Values.global.appConfig.ldap.servers -}}
ldap:
  enabled: false
{{- else -}}
ldap:
  enabled: true
  servers:
    {{- range $serverName, $serverConfig := .Values.global.appConfig.ldap.servers -}}
      {{- include "gitlab.appConfig.ldap.servers.configuration" (dict "name" $serverName "config" $serverConfig) | nindent 4 -}}
    {{- end -}}
{{- end -}}
{{- end -}}{{/* "gitlab.appConfig.ldap.configuration" */}}

{{/*
Usage example:

{{ include "gitlab.appConfig.ldap.servers.configuration" (\
    dict \
        "name" <ServerName>
        "config" <ServerConfig>
    ) }}
*/}}
{{- define "gitlab.appConfig.ldap.servers.configuration" -}}
{{- $.name }}:
{{- range $key, $value := $.config -}}
{{-   if and (eq $key "password") (kindIs "map" $value) -}}
{{-     printf "password: %s" (printf "<%%= File.read('/etc/gitlab/ldap/%s/password') %%>" $.name | quote) | trimSuffix "\n" | nindent 2 -}}
{{-   else -}}
{{-     toYaml (dict $key $value) | trimSuffix "\n" | nindent 2 -}}
{{-   end -}}
{{- end -}}
{{- end -}}{{/* gitlab.appConfig.ldap.servers.configuration */}}

{{- define "gitlab.appConfig.ldap.servers.mountSecrets" -}}
# mount secrets for LDAP
{{- if .Values.global.appConfig.ldap.servers -}}
{{-   range $name, $config := .Values.global.appConfig.ldap.servers -}}
{{-     if (and $config.password (kindIs "map" $config.password)) }}
- secret:
    name: {{ $config.password.secretName }}
    items:
      - key: {{ default "password" $config.password.secretKey }}
        path: ldap/{{ $name }}/password
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}{{/* "gitlab.appConfig.ldap.servers.mountSecrets" "*/}}
