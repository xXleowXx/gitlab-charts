{{/*
Return the task-runner backup S3 credentials secret name
*/}}
{{- define "gitlab.task-runner.s3.credentials.secret" -}}
{{- default (printf "%s-s3credentials-secret" .Release.Name) .Values.global.appConfig.backups.secretName | quote -}}
{{- end -}}
