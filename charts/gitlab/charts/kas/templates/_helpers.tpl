{{/*
Returns the secret name for the Secret containing the TLS certificate and key.
Uses `ingress.tls.secretName` first and falls back to `global.ingress.tls.secretName`
if there is a shared tls secret for all ingresses.
*/}}
{{- define "kas.tlsSecret" -}}
{{- $defaultName := (dict "secretName" "") -}}
{{- if .Values.global.ingress.configureCertmanager -}}
{{- $_ := set $defaultName "secretName" (printf "%s-kas-tls" .Release.Name) -}}
{{- else -}}
{{- $_ := set $defaultName "secretName" (include "gitlab.wildcard-self-signed-cert-name" .) -}}
{{- end -}}
{{- pluck "secretName" .Values.ingress.tls .Values.global.ingress.tls $defaultName | first -}}
{{- end -}}

{{/*
Build the structure describing sentinels
*/}}
{{- define "kas.redis" -}}
{{- if .Values.global.redis.sharedState -}}
{{- $_ := set $ "redisConfigName" "sharedState" -}}
{{- end -}}
{{- include "gitlab.redis.configMerge" . -}}
password_file: /etc/kas/redis/{{ printf "%s-password" (default "redis" .redisConfigName) }}
{{ if not .redisMergedConfig.sentinels -}}
server:
  address: {{ template "gitlab.redis.host" . }}:{{ template "gitlab.redis.port" . }}
{{ else -}}
sentinel:
  master_name: {{ template "gitlab.redis.host" . }}
  addresses:
{{- range $i, $entry := .redisMergedConfig.sentinels }}
    - {{ quote (print "tcp://" (trim $entry.host) ":" ( default 26379 $entry.port | int ) ) -}}
{{- end -}}
{{- end -}}
{{- end -}}