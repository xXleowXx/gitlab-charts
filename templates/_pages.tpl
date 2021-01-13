{{/* ######### gitlab-pages related templates */}}

{{/*
Return the gitlab-pages secret
*/}}

{{- define "gitlab.pages.apiSecret.secret" -}}
{{- default (printf "%s-gitlab-pages-secret" .Release.Name) $.Values.global.pages.apiSecret.secret | quote -}}
{{- end -}}

{{- define "gitlab.pages.apiSecret.key" -}}
{{- default "shared_secret" $.Values.global.pages.apiSecret.key | quote -}}
{{- end -}}

{{- define "gitlab.pages.gitlabAuthSecret.secret" -}}
{{ default (printf "%s-gitlab-pages-gitlab-auth-secret" .Release.Name) $.Values.global.pages.accessControl.gitlabAuth.secret }}
{{- end -}}

{{- define "gitlab.pages.gitlabAuthSecret.appIdKey" -}}
{{ default "appid" $.Values.global.pages.accessControl.gitlabAuth.appIdKey }}
{{- end -}}

{{- define "gitlab.pages.gitlabAuthSecret.appSecretKey" -}}
{{ default "appsecret" $.Values.global.pages.accessControl.gitlabAuth.appSecretKey }}
{{- end -}}

{{- define "gitlab.pages.authSecret.secret" -}}
{{ default (printf "%s-gitlab-pages-auth-secret" .Release.Name) $.Values.global.pages.accessControl.authSecret.secret }}
{{- end -}}

{{- define "gitlab.pages.authSecret.key" -}}
{{ default "password" $.Values.global.pages.accessControl.authSecret.key }}
{{- end -}}
