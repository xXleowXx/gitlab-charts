{{/* ######### workhorse templates */}}

{{/*
Return the workhorse hostname
If the workhorse host is provided, it will use that, otherwise it will fallback
to the service name
*/}}
{{- define "gitlab.workhorse.host" -}}
{{- $hostname := default .Values.global.workhorse.host .Values.workhorse.host -}}
{{- if empty $hostname -}}
{{-   $name := default .Values.global.workhorse.serviceName .Values.workhorse.serviceName -}}
{{-   $hostname = printf "%s-%s.%s.svc" .Release.Name $name .Release.Namespace -}}
{{- end -}}
{{- $hostname -}}
{{- end -}}

{{- define "gitlab.workhorse.port" -}}
{{- coalesce .Values.workhorse.port .Values.global.workhorse.port "8181" -}}
{{- end -}}
