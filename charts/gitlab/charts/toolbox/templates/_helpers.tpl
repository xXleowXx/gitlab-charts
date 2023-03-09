{{- define "toolbox.backups.cron.persistence.persistentVolumeClaim" -}}
metadata:
{{- if not .Values.backups.cron.persistence.useGenericEphemeralVolume }}
  name: {{ template "fullname" . }}-backup-tmp
  namespace: {{ $.Release.Namespace }}
{{- end }}
  labels:
    {{- include "gitlab.standardLabels" . | nindent 4 }}
    {{- include "gitlab.commonLabels" . | nindent 4 }}
spec:
  accessModes:
    - {{ .Values.backups.cron.persistence.accessMode | quote }}
  resources:
    requests:
      storage: {{ .Values.backups.cron.persistence.size | quote }}
{{- if .Values.backups.cron.persistence.volumeName }}
  volumeName: {{ .Values.backups.cron.persistence.volumeName }}
{{- end }}
{{- if .Values.backups.cron.persistence.storageClass }}
{{- if (eq "-" .Values.backups.cron.persistence.storageClass) }}
  storageClassName: ""
{{- else }}
  storageClassName: "{{ .Values.backups.cron.persistence.storageClass }}"
{{- end -}}
{{- end }}
  selector:
{{- if .Values.backups.cron.persistence.matchLabels }}
    matchLabels:
      {{- toYaml .Values.backups.cron.persistence.matchLabels | nindent 6 }}
{{- end -}}
{{- if .Values.backups.cron.persistence.matchExpressions }}
    matchExpressions:
      {{- toYaml .Values.backups.cron.persistence.matchExpressions | nindent 6 }}
{{- end -}}
{{- end -}}