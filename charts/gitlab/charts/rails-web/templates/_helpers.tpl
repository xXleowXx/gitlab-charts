{{/* vim: set filetype=mustache: */}}

{{/*
Returns the secret name for the Secret containing the TLS certificate and key.
Uses `ingress.tls.secretName` first and falls back to `global.ingress.tls.secretName`
if there is a shared tls secret for all ingresses.
*/}}
{{- define "railsWeb.tlsSecret" -}}
{{- $defaultName := (dict "secretName" "") -}}
{{- if .Values.global.ingress.configureCertmanager -}}
{{- $_ := set $defaultName "secretName" (printf "%s-gitlab-tls" .Release.Name) -}}
{{- else -}}
{{- $_ := set $defaultName "secretName" (include "gitlab.wildcard-self-signed-cert-name" .) -}}
{{- end -}}
{{- pluck "secretName" .Values.ingress.tls .Values.global.ingress.tls $defaultName | first -}}
{{- end -}}

{{/*
Returns the workhorse image repository depending on the value of global.edition.

Used to switch the deployment from Enterprise Edition (default) to Community
Edition. If global.edition=ce, returns the Community Edition image repository
set in the Gitlab values.yaml, otherwise returns the Enterprise Edition
image repository.
*/}}
{{- define "workhorse.repository" -}}
{{- if eq "ce" .Values.global.edition -}}
{{ index .Values "global" "communityImages" "workhorse" "repository" }}
{{- else -}}
{{ index .Values "global" "enterpriseImages" "workhorse" "repository" }}
{{- end -}}
{{- end -}}

{{- define "railsWeb.repository" -}}
{{-   if eq "ce" .Values.global.edition -}}
{{      $images := index .Values "global" "communityImages" }}
{{-   else -}}
{{    $images := index .Values "global" "enterpriseImages" }}
{{-   end -}}
{{-   if eq .Values.webServer "unicorn" -}}
{{      $image := index $images "unicorn" "repository"}}
{{      coalesce .Values.image.repository.unicorn $image }}:{{ coalesce .Values.image.tag (include "gitlab.versionTag" . ) }}
{{-   else -}}
{{      $image := index $images "puma" "repository"}}
{{      coalesce .Values.image.repository.puma $image }}:{{ coalesce .Values.image.tag (include "gitlab.versionTag" . ) }}
{{-   end -}}
{{- end -}}
