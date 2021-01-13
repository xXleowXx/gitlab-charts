{{- define "OAuth.gitlab-pages.secret" -}}
{{ default (printf "%s-oauth-gitlab-pages-secret" .Release.Name) (index $.Values.global.OAuth "gitlab-pages" "secret") }}
{{- end -}}

{{- define "OAuth.gitlab-pages.appIdKey" -}}
{{ default "appid" (index $.Values.global.OAuth "gitlab-pages" "appIdKey") }}
{{- end -}}

{{- define "OAuth.gitlab-pages.appSecretKey" -}}
{{ default "appsecret" (index $.Values.global.OAuth "gitlab-pages" "appSecretKey") }}
{{- end -}}

{{- define "OAuth.gitlab-pages.authRedirectUri" -}}
{{- if (index $.Values.global.OAuth "gitlab-pages" "redirectUri") -}}
{{   (index $.Values.global.OAuth "gitlab-pages" "redirectUri") }}
{{- else -}}
{{-   if eq "true" (include "gitlab.pages.https" $) -}}
https://projects.{{ template "gitlab.pages.hostname" . }}/auth
{{-   else -}}
http://projects.{{ template "gitlab.pages.hostname" . }}/auth
{{-   end -}}
{{- end -}}
{{- end -}}
