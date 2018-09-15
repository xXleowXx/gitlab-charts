{{/* vim: set filetype=mustache: */}}

{{/*
Returns the secret name for the Secret containing the TLS certificate and key.
Uses `ingress.tls.secretName` first and falls back to `global.ingress.tls.secretName`
if there is a shared tls secret for all ingresses.
*/}}
{{- define "unicorn.tlsSecret" -}}
{{- $defaultName := (dict "secretName" "") -}}
{{- if .Values.global.ingress.configureCertmanager -}}
{{- $_ := set $defaultName "secretName" (printf "%s-gitlab-tls" .Release.Name) -}}
{{- else -}}
{{- $_ := set $defaultName "secretName" (include "gitlab.wildcard-self-signed-cert-name" .) -}}
{{- end -}}
{{- pluck "secretName" .Values.ingress.tls .Values.global.ingress.tls $defaultName | first -}}
{{- end -}}

{{/*
Returns workhorse.imageEE if global.edition is set to "ee", or
workhorse.imageCE otherwise.
*/}}
{{- define "workhorse.image" -}}
{{- if eq "ee" .Values.global.edition -}}
{{ .Values.workhorse.imageEE }}
{{- else -}}
{{ .Values.workhorse.imageCE }}
{{- end -}}
{{- end -}}
