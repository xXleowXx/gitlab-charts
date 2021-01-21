{{- define "gitlabAuth.pages.secret" -}}
{{ default (printf "%s-gitlab-oauth-pages-secret" .Release.Name) $.Values.global.gitlabAuth.pages.secret }}
{{- end -}}

{{- define "gitlabAuth.pages.appIdKey" -}}
{{ default "appid" $.Values.global.gitlabAuth.pages.appIdKey}}
{{- end -}}

{{- define "gitlabAuth.pages.appSecretKey" -}}
{{ default "appsecret" $.Values.global.gitlabAuth.pages.appSecretKey}}
{{- end -}}

{{- define "gitlabAuth.pages.authRedirectUri" -}}
{{- if $.Values.global.gitlabAuth.pages.redirectUri -}}
{{   $.Values.global.gitlabAuth.pages.redirectUri }}
{{- else -}}
{{-   if eq "true" (include "gitlab.pages.https" $) -}}
https://projects.{{ template "gitlab.pages.hostname" . }}/auth
{{-   else -}}
http://projects.{{ template "gitlab.pages.hostname" . }}/auth
{{-   end -}}
{{- end -}}
{{- end -}}
