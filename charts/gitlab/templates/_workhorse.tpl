{{/* ######### workhorse templates */}}

{{/*
Return the workhorse hostname
If the workhorse host is provided, it will use that, otherwise it will fallback
to the service name
*/}}
{{- define "gitlab.workhorse.host" -}}
{{- if .Values.workhorse.host -}}
{{- .Values.workhorse.host -}}
{{- else -}}
{{- $name := default "unicorn" .Values.workhorse.serviceName -}}
{{- printf "%s-%s" .Release.Name $name -}}
{{- end -}}
{{- end -}}

{{- define "gitlab.workhorse.port" -}}
{{- if .Values.workhorse.port -}}
{{- .Values.workhorse.port -}}
{{- else -}}
{{- $port:= default "8181" .Values.workhorse.port -}}
{{- $port -}}
{{- end -}}
{{- end -}}

{{- define "gitlab.workhorse.config" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{.Release.Name }}-workhorse-config
  namespace: {{ $.Release.Namespace }}
  labels:
{{ include "gitlab.standardLabels" . | indent 4 }}
data:
  installation_type: |
    gitlab-helm-chart
  workhorse-config.toml.erb: |
    [redis]
    {{- if not .Values.global.redis.sentinels }}
    URL = "{{ template "gitlab.redis.scheme" . }}://{{ template "gitlab.redis.host" . }}:{{ template "gitlab.redis.port" . }}"
    {{- else }}
    SentinelMaster = "{{ template "gitlab.redis.host" . }}"
    Sentinel = [ {{ template "gitlab.redis.workhorse.sentinel-list" . }} ]
    {{- end }}
    {{- if .Values.global.redis.password.enabled }}
    Password = "<%= File.read("/etc/gitlab/redis/password").strip.dump[1..-2] %>"
    {{- end }}
  configure: |
      set -e
      mkdir -p /init-secrets-workhorse/gitlab-workhorse
      cp -v -r -L /init-config/gitlab-workhorse/secret /init-secrets-workhorse/gitlab-workhorse/secret
      {{- if .Values.global.redis.password.enabled }}
      mkdir -p /init-secrets-workhorse/redis
      cp -v -r -L /init-config/redis/password /init-secrets-workhorse/redis/
      {{- end }}
# Leave this here - This line denotes end of block to the parser.
{{- end -}}
