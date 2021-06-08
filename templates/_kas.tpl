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
{{- default (printf "%s-kas-private-api" .Release.Name) .Values.gitlab.kas.privateApi.secretValue | quote -}}
{{- end -}}

{{- define "gitlab.kas.privateApi.key" -}}
{{- default "kas_private_api_secret" .Values.gitlab.kas.privateApi.secretKey | quote -}}
{{- end -}}
