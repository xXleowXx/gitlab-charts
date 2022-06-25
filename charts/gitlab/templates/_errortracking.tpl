{{/* ######### Error Tracking template */}}

{{- define "gitlab.errortracking.env" -}}
{{- if .Values.global.errortracking.apiUrl }}
- name: ERROR_TRACKING_API_URL
  value: {{ .Values.global.errortracking.apiUrl | quote }}
{{- end -}}
{{- if .Values.global.errortracking.sharedSecret }}
- name: ERROR_TRACKING_SHARED_SECRET
  value: {{ .Values.global.errortracking.sharedSecret | quote }}
{{- end -}}
{{- end -}}
