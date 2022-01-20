{{/*
Adds `ingress.class` annotation based on the API version of Ingress.

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `context` which is the parent context (either `.` or `$`)
*/}}
{{- define "ingress.class.annotation" -}}
{{-   $apiVersion := include "gitlab.ingress.apiVersion" . -}}
{{-   $className := .global.class | default (printf "%s-nginx" .context.Release.Name) -}}
{{-   if not (eq $apiVersion "networking.k8s.io/v1") -}}
kubernetes.io/ingress.class: {{ $className }}
{{-   end -}}
{{- end -}}

{{/*
Calculates the IngressClass name.

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `context` which is the parent context (either `.` or `$`)
*/}}
{{- define "ingress.class.name" -}}
{{-   .global.class | default (printf "%s-nginx" .context.Release.Name) -}}
{{- end -}}

{{/*
Sets `ingressClassName` based on the API version of Ingress.

It expects a dictionary with two entries:
  - `global` which contains global ingress settings, e.g. .Values.global.ingress
  - `context` which is the parent context (either `.` or `$`)
*/}}
{{- define "ingress.class.field" -}}
{{-   $apiVersion := include "gitlab.ingress.apiVersion" . -}}
{{-   if eq $apiVersion "networking.k8s.io/v1" -}}
ingressClassName: {{ include "ingress.class.name" . }}
{{-   end -}}
{{- end -}}
