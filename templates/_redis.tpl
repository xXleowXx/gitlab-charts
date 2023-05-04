{{/* ######### Redis related templates */}}

{{/*
Build a dict of redis configuration

- inherit from global.redis, all but sentinels and cluster
- use values within children, if they exist, even if "empty"
*/}}
{{- define "gitlab.redis.configMerge" -}}
{{-   $_ := set $ "redisConfigName" (default "" $.redisConfigName) -}}
{{-   $_ := unset $ "redisMergedConfig" -}}
{{-   $_ := set $ "redisMergedConfig" (dict "redisConfigName" $.redisConfigName) -}}
{{-   range $want := list "host" "port" "auth" "scheme" "user" -}}
{{-     $_ := set $.redisMergedConfig $want (pluck $want (index $.Values.global.redis $.redisConfigName) $.Values.global.redis | first) -}}
{{-   end -}}
{{-   range $key := keys $.Values.global.redis.auth -}}
{{-     if not (hasKey $.redisMergedConfig.auth $key) -}}
{{-       $_ := set $.redisMergedConfig.auth $key (index $.Values.global.redis.auth $key) -}}
{{-     end -}}
{{-   end -}}
{{/*  backwards compatibility with existing global.redis.password maps */}}
{{-   if kindIs "map" $.Values.global.redis.password  -}}
{{-     range $key := keys $.Values.global.redis.password -}}
{{-       if not (hasKey $.redisMergedConfig.auth $key) -}}
{{-         $_ := set $.redisMergedConfig.auth $key (index $.Values.global.redis.password $key) -}}
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}

{{/*
Return the redis password secret name
*/}}
{{- define "gitlab.redis.auth.secret" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default (printf "%s-redis-secret" .Release.Name) .redisMergedConfig.auth.existingSecret | quote -}}
{{- end -}}

{{/*
Return the redis password secret key
*/}}
{{- define "gitlab.redis.auth.key" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default "secret" .redisMergedConfig.auth.existingSecretKey | quote -}}
{{- end -}}
