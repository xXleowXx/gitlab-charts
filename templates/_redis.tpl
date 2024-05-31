{{/* ######### Redis related templates */}}

{{/*
Build a dict of redis configuration

- inherit from global.redis, all but sentinels and cluster
- use values within children, if they exist, even if "empty"
*/}}
{{- define "gitlab.redis.configMerge" -}}
{{-   $_ := set $ "redisConfigName" (default "" $.redisConfigName) -}}
{{-   $_ := set $ "usingOverride" (default false $.usingOverride) -}}
{{-   $_ := unset $ "redisMergedConfig" -}}
{{-   $_ := set $ "redisMergedConfig" (dict "redisConfigName" $.redisConfigName) -}}
{{-   $hasOverrideSecret := false -}}
{{-   if and $.Values.global.redis.redisYmlOverride $.redisConfigName -}}
{{-     $hasOverrideSecret = (kindIs "map" (dig $.redisConfigName "password" "" $.Values.global.redis.redisYmlOverride)) -}}
{{-   end -}}
{{-   range $want := list "host" "port" "scheme" "user" -}}
{{-     $_ := set $.redisMergedConfig $want (pluck $want (index $.Values.global.redis $.redisConfigName) $.Values.global.redis | first) -}}
{{-   end -}}
{{-   if and $hasOverrideSecret $.usingOverride -}}
{{-     $_ := set $.redisMergedConfig "password" (get (index $.Values.global.redis.redisYmlOverride $.redisConfigName) "password") -}}
{{-   else if kindIs "map" (get (index $.Values.global.redis $.redisConfigName) "password")  -}}
{{-     $_ := set $.redisMergedConfig "password" (get (index $.Values.global.redis $.redisConfigName) "password") -}}
{{-   else if (kindIs "map" (get $.Values.global.redis "password")) -}}
{{-     $_ := set $.redisMergedConfig "password" (get $.Values.global.redis "password") -}}
{{-   else -}}
{{-     $_ := set $.redisMergedConfig "password" $.Values.global.redis.auth -}}
{{-   end -}}
{{-   range $key := keys $.Values.global.redis.auth -}}
{{-     if not (hasKey $.redisMergedConfig.password $key) -}}
{{-       $_ := set $.redisMergedConfig.password $key (index $.Values.global.redis.auth $key) -}}
{{-     end -}}
{{-   end -}}

{{/*
Build a dict of Redis Sentinel configuration

- redisYmlOverride is used by GitLab Rails, which uses the redis-rb gem (https://github.com/redis/redis-rb).
- The code below maps `sentinel_password` to the `sentinelAuth` structure.
- redis-rb v5 specifies `sentinel_password` and `sentinel_username` as parameters.
- Note that both redis-rb v4 and v5 can pass `password` and `username` as parameters in the Sentinel host list as well.
- We use `global.redis.sentinelAuth` to be consistent with `global.redis.auth`.
- Currently GitLab doesn't support Redis usernames, but this will likely be needed in the future.
  This could be done by introducing `global.redis.sentinelAuth.usernameKey` and `sentinel_username` in redisYmlOverride.
*/}}
{{-   $hasOverrideSentinelSecret := false -}}
{{-   if and $.Values.global.redis.redisYmlOverride $.redisConfigName -}}
{{-     $hasOverrideSentinelSecret = (kindIs "map" (dig $.redisConfigName "sentinel_password" "" $.Values.global.redis.redisYmlOverride)) -}}
{{-   end -}}
{{-   if and $hasOverrideSentinelSecret $.usingOverride -}}
{{-     $_ := set $.redisMergedConfig "sentinelAuth" (get (index $.Values.global.redis.redisYmlOverride $.redisConfigName) "sentinel_password") -}}
{{-   else if kindIs "map" (get (index $.Values.global.redis $.redisConfigName) "sentinelAuth")  -}}
{{-     $_ := set $.redisMergedConfig "sentinelAuth" (get (index $.Values.global.redis $.redisConfigName) "sentinelAuth") -}}
{{-   else if (kindIs "map" (get $.Values.global.redis "sentinelAuth")) -}}
{{-     $_ := set $.redisMergedConfig "sentinelAuth" (get $.Values.global.redis "sentinelAuth") -}}
{{-   else -}}
{{-     $_ := set $.redisMergedConfig "sentinelAuth" $.Values.global.redis.sentinelAuth -}}
{{-   end -}}
{{-   range $key := keys $.Values.global.redis.sentinelAuth -}}
{{-     if not (hasKey $.redisMergedConfig.sentinelAuth $key) -}}
{{-       $_ := set $.redisMergedConfig.sentinelAuth $key (index $.Values.global.redis.sentinelAuth $key) -}}
{{-     end -}}
{{-   end -}}
{{- end -}}

{{/*
Return the redis password secret name
*/}}
{{- define "gitlab.redis.password.secret" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default (printf "%s-redis-secret" .Release.Name) .redisMergedConfig.password.secret | quote -}}
{{- end -}}

{{/*
Return the redis password secret key
*/}}
{{- define "gitlab.redis.password.key" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default "secret" .redisMergedConfig.password.key | quote -}}
{{- end -}}

{{/*
Return a merged setting between global.redis.password.enabled,
global.redis.[subkey/"redisConfigName"].password.enabled, or
global.redis.auth.enabled
*/}}
{{- define "gitlab.redis.password.enabled" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{ ternary "true" "" .redisMergedConfig.password.enabled }}
{{- end -}}

{{/*
Return the Redis Sentinel auth secret name
*/}}
{{- define "gitlab.redis.sentinelAuth.secret" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default (printf "%s-redis-sentinel-secret" .Release.Name) .redisMergedConfig.sentinelAuth.secret | quote -}}
{{- end -}}

{{/*
Return the Redis Sentinel password secret key
*/}}
{{- define "gitlab.redis.sentinelAuth.key" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default "secret" .redisMergedConfig.sentinelAuth.key | quote -}}
{{- end -}}

{{/*
Return a merged setting between global.redis.sentinelAuth.enabled,
global.redis.[subkey/"redisConfigName"].sentinelAuth.enabled, or
global.redis.auth.enabled
*/}}
{{- define "gitlab.redis.sentinelAuth.enabled" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{ ternary "true" "" .redisMergedConfig.sentinelAuth.enabled }}
{{- end -}}
