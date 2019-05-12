{{- define "jaeger.hostname" -}}
{{- coalesce .Values.global.hosts.jaeger.name (include "gitlab.assembleHost"  (dict "name" "jaeger" "context" . )) -}}
{{- end -}}

{{/*
Returns the secret name for the Secret containing the TLS certificate and key.
Uses `ingress.tls.secretName` first and falls back to `global.ingress.tls.secretName`
if there is a shared tls secret for all ingresses.
*/}}
{{- define "jaeger.tlsSecret" -}}
{{- $defaultName := (dict "secretName" "") -}}
{{- if .Values.global.ingress.configureCertmanager -}}
{{- $_ := set $defaultName "secretName" (printf "%s-jaeger-tls" .Release.Name) -}}
{{- else -}}
{{- $_ := set $defaultName "secretName" (include "gitlab.wildcard-self-signed-cert-name" .) -}}
{{- end -}}
{{- pluck "secretName" .Values.ingress.tls .Values.global.ingress.tls $defaultName | first -}}
{{- end -}}

{{/*
Returns the nginx ingress class
*/}}
{{- define "jaeger.ingressclass" -}}
{{- pluck "class" .Values.global.ingress (dict "class" (printf "%s-nginx" .Release.Name)) | first -}}
{{- end -}}