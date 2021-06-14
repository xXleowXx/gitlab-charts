{{/* ######### gitlab-kas related templates */}}

{{/*
Return the gitlab-kas secret
*/}}

{{- define "gitlab.kas.secret" -}}
{{- default (printf "%s-gitlab-kas-secret" .Release.Name) .Values.global.appConfig.gitlab_kas.secret | quote -}}
{{- end -}}

{{- define "gitlab.kas.key" -}}
{{- default "kas_shared_secret" .Values.global.appConfig.gitlab_kas.key | quote -}}
{{- end -}}

{{/*
Return the gitlab-kas private API secret
*/}}

{{- define "gitlab.kas.privateApi.secret" -}}
{{- $secret := printf "%s-kas-private-api" .Release.Name -}}
{{- if eq .Chart.Name "kas" -}}
{{-    $secret = .Values.privateApi.secret -}}
{{- else -}}
{{-    $secret = .Values.gitlab.kas.privateApi.secret -}}
{{- end -}}
{{- $secret | quote -}}
{{- end -}}

{{- define "gitlab.kas.privateApi.key" -}}
{{- $key := "kas_private_api_secret" -}}
{{- if eq .Chart.Name "kas" -}}
{{-    $key = .Values.privateApi.key -}}
{{- else -}}
{{-    $key = .Values.gitlab.kas.privateApi.key -}}
{{- end -}}
{{- $key | quote -}}
{{- end -}}
