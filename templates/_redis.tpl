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

{{-   $hasOverrideSentinelSecret := false -}}
{{-   if and $.Values.global.redis.redisYmlOverride $.redisConfigName -}}
{{-     $hasOverrideSentinelSecret = (kindIs "map" (dig $.redisConfigName "sentinel_password" "" $.Values.global.redis.redisYmlOverride)) -}}
{{-   end -}}
{{-   if and $hasOverrideSentinelSecret $.usingOverride -}}
{{-     $_ := set $.redisMergedConfig "sentinelPassword" (get (index $.Values.global.redis.redisYmlOverride $.redisConfigName) "sentinel_password") -}}
{{-   else if kindIs "map" (get (index $.Values.global.redis $.redisConfigName) "sentinelPassword")  -}}
{{-     $_ := set $.redisMergedConfig "sentinelPassword" (get (index $.Values.global.redis $.redisConfigName) "sentinelPassword") -}}
{{-   else if (kindIs "map" (get $.Values.global.redis "sentinelPassword")) -}}
{{-     $_ := set $.redisMergedConfig "sentinelPassword" (get $.Values.global.redis "sentinelPassword") -}}
{{-   else -}}
{{-     $_ := set $.redisMergedConfig "sentinelPassword" $.Values.global.redis.auth -}}
{{-   end -}}
{{-   range $key := keys $.Values.global.redis.sentinelPassword -}}
{{-     if not (hasKey $.redisMergedConfig.sentinelPassword $key) -}}
{{-       $_ := set $.redisMergedConfig.sentinelPassword $key (index $.Values.global.redis.sentinelPassword $key) -}}
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
Return the redis sentinel password secret name
*/}}
{{- define "gitlab.redis.sentinelPassword.secret" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default (printf "%s-redis-sentinel-secret" .Release.Name) .redisMergedConfig.sentinelPassword.secret | quote -}}
{{- end -}}

{{/*
Return the redis password secret key
*/}}
{{- define "gitlab.redis.sentinelPassword.key" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default "secret" .redisMergedConfig.sentinelPassword.key | quote -}}
{{- end -}}

{{/*
Return a merged setting between global.redis.sentinelPassword.enabled,
global.redis.[subkey/"redisConfigName"].sentinelPassword.enabled, or
global.redis.auth.enabled
*/}}
{{- define "gitlab.redis.sentinelPassword.enabled" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{ ternary "true" "" .redisMergedConfig.sentinelPassword.enabled }}
{{- end -}}
