{{/*
Helper for Sentinels as a string

Expectation: input contents has .sentinels, which is a List of Dict
    in the format of [{host: , port:}, ...]
*/}}
{{- define "registry.redis.host.sentinels" -}}
{{- $sentinels := list -}}
{{- range .sentinels -}}
{{-   $sentinels = append $sentinels (printf "%s:%d" .host (default 26379 .port | int)) -}}
{{- end -}}
{{ join "," $sentinels }}
{{- end -}}


{{- define "gitlab.registry.redisCacheSecret.mount" -}}
{{- if .Values.redis.cache.password.enabled }}
- secret:
    name: {{ default (include  "redis.secretName" . ) ( .Values.redis.cache.password.secret | quote) }}
    items:
      - key: {{ default (include "redis.secretPasswordKey" . ) ( .Values.redis.cache.password.key | quote) }}
        path: registry/redis-password
{{- end }}
{{- end -}}

{{- define "gitlab.registry.redisSentinelSecret.mount" -}}
{{- include "gitlab.redis.selectedMergedConfig" . -}}
{{- if .Values.redis.cache.sentinelpassword }}
{{-   if .Values.redis.cache.sentinelpassword.enabled }}
- secret:
    name: {{ .Values.redis.cache.sentinelpassword.secret | quote }}
    items:
      - key: {{ .Values.redis.cache.sentinelpassword.key | quote }}
        path: redis-sentinel/redis-sentinel-password
{{-   end }}
{{- else }}
{{- if .redisMergedConfig.sentinelAuth.enabled }}
- secret:
    name: {{ template "gitlab.redis.sentinelAuth.secret" . }}
    items:
      - key: {{ template "gitlab.redis.sentinelAuth.key" . }}
        path: redis-sentinel/redis-sentinel-password
{{- end }}
{{- end -}}
{{- end -}}

{{- define "gitlab.registry.redisRateLimiterSecret.mount" -}}
{{- if .Values.redis.rateLimiter.password.enabled }}
- secret:
    name: {{ default (include  "redis.secretName" . ) ( .Values.redis.rateLimiter.password.secret | quote) }}
    items:
      - key: {{ default (include "redis.secretPasswordKey" . ) ( .Values.redis.rateLimiter.password.key | quote) }}
        path: registry/redis-rateLimiter-password
{{- end }}
{{- end -}}

{{/*
Return Redis configuration.
*/}}
{{- define "registry.redis.config" -}}
{{- include "gitlab.redis.selectedMergedConfig" . -}}
redis:
  {{- if .Values.redis.cache.enabled }}
  cache:
    enabled: {{ .Values.redis.cache.enabled | eq true }}
    {{- if .Values.redis.cache.sentinels }}
    addr: {{ include "registry.redis.host.sentinels" .Values.redis.cache | quote }}
    mainname: {{ .Values.redis.cache.host }}
    {{- else if .redisMergedConfig.sentinels }}
    addr: {{ include "registry.redis.host.sentinels" .redisMergedConfig | quote }}
    mainname: {{ template "gitlab.redis.host" . }}
    {{-   if .redisMergedConfig.sentinelAuth.enabled }}
    sentinelpassword: {% file.Read "/config/redis-sentinel/redis-sentinel-password" | strings.TrimSpace | data.ToJSON %}
    {{-   end }}
    {{- else if .Values.redis.cache.host  }}
    addr: {{ printf "%s:%d" .Values.redis.cache.host (int .Values.redis.cache.port | default 6379) | quote }}
    {{- else }}
    addr: {{ printf "%s:%s" ( include "gitlab.redis.host" . ) ( include "gitlab.redis.port" . ) | quote }}
    {{- end }}
    {{- if .Values.redis.cache.password.enabled }}
    password: "REDIS_CACHE_PASSWORD"
    {{- end }}
    {{- if hasKey .Values.redis.cache "db" }}
    db: {{ .Values.redis.cache.db }}
    {{- end }}
    {{- if .Values.redis.cache.dialtimeout }}
    dialtimeout: {{ .Values.redis.cache.dialtimeout }}
    {{- end }}
    {{- if .Values.redis.cache.readtimeout }}
    readtimeout: {{ .Values.redis.cache.readtimeout }}
    {{- end }}
    {{- if .Values.redis.cache.writetimeout }}
    writetimeout: {{ .Values.redis.cache.writetimeout }}
    {{- end }}
    {{- if .Values.redis.cache.tls }}
    tls:
      enabled: {{ .Values.redis.cache.tls.enabled | eq true }}
      insecure: {{ .Values.redis.cache.tls.insecure | eq true }}
    {{- end }}
    {{- if .Values.redis.cache.pool }}
    pool:
      {{- if .Values.redis.cache.pool.size }}
      size: {{ .Values.redis.cache.pool.size }}
      {{- end }}
      {{- if .Values.redis.cache.pool.maxlifetime }}
      maxlifetime: {{ .Values.redis.cache.pool.maxlifetime }}
      {{- end }}
      {{- if .Values.redis.cache.pool.idletimeout }}
      idletimeout: {{ .Values.redis.cache.pool.idletimeout }}
      {{- end -}}
    {{- end -}}
  {{- end }}
  {{- if .Values.redis.rateLimiter.enabled }}
  ratelimiter:
    enabled: {{ .Values.redis.rateLimiter.enabled | eq true }}
    {{- if .Values.redis.rateLimiter.sentinels }}
    addr: {{ include "registry.redis.host.sentinels" .Values.redis.rateLimiter | quote }}
    mainname: {{ .Values.redis.rateLimiter.host }}
    {{- else if .redisMergedConfig.sentinels }}
    addr: {{ include "registry.redis.host.sentinels" .redisMergedConfig | quote }}
    mainname: {{ template "gitlab.redis.host" . }}
    {{- else if .Values.redis.rateLimiter.host  }}
    addr: {{ printf "%s:%d" .Values.redis.rateLimiter.host (int .Values.redis.rateLimiter.port | default 6379) | quote }}
    {{- else }}
    addr: {{ printf "%s:%s" ( include "gitlab.redis.host" . ) ( include "gitlab.redis.port" . ) | quote }}
    {{- end }}
    {{- if .Values.redis.rateLimiter.username }}
    username: .Values.redis.rateLimiter.username
    {{- end }}
    {{- if .Values.redis.rateLimiter.password.enabled }}
    password: "REDIS_RATE_LIMITER_PASSWORD"
    {{- end }}
    {{- if hasKey .Values.redis.rateLimiter "db" }}
    db: {{ .Values.redis.rateLimiter.db }}
    {{- end }}
    {{- if .Values.redis.rateLimiter.dialtimeout }}
    dialtimeout: {{ .Values.redis.rateLimiter.dialtimeout }}
    {{- end }}
    {{- if .Values.redis.rateLimiter.readtimeout }}
    readtimeout: {{ .Values.redis.rateLimiter.readtimeout }}
    {{- end }}
    {{- if .Values.redis.rateLimiter.writetimeout }}
    writetimeout: {{ .Values.redis.rateLimiter.writetimeout }}
    {{- end }}
    {{- if .Values.redis.rateLimiter.tls }}
    tls:
      enabled: {{ .Values.redis.rateLimiter.tls.enabled | eq true }}
      insecure: {{ .Values.redis.rateLimiter.tls.insecure | eq true }}
    {{- end }}
    {{- if .Values.redis.rateLimiter.pool }}
    pool:
      {{- if .Values.redis.rateLimiter.pool.size }}
      size: {{ .Values.redis.rateLimiter.pool.size }}
      {{- end }}
      {{- if .Values.redis.rateLimiter.pool.maxlifetime }}
      maxlifetime: {{ .Values.redis.rateLimiter.pool.maxlifetime }}
      {{- end }}
      {{- if .Values.redis.rateLimiter.pool.idletimeout }}
      idletimeout: {{ .Values.redis.rateLimiter.pool.idletimeout }}
      {{- end -}}
    {{- end -}}
  {{- end }}
{{- end -}}
