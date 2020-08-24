{{/* ######### KAS related templates */}}

{{- define "gitlab.kas.mountSecrets" -}}
# mount secret for kas
{{- if .Values.global.kas.enabled }}
- secret:
    name: {{ template "gitlab.kas.secret" . }}
    items:
      - key: {{ template "gitlab.kas.key" . }}
        path: kas/.gitlab_kas_secret
{{- end -}}
{{- end -}}{{/* "gitlab.kas.mountSecrets" */}}
