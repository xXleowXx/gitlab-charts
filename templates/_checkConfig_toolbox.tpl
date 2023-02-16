{{/*
Ensure that a valid object storage config secret is provided.
*/}}
{{- define "gitlab.toolbox.backups.objectStorage.config.secret" -}}
{{- $objectStorage := .Values.gitlab.toolbox.backups.objectStorage -}}
{{-   if .Values.gitlab.toolbox.enabled -}}
{{-     if or $objectStorage.config (not (or .Values.global.minio.enabled .Values.global.appConfig.object_store.enabled)) (has $objectStorage.backend (list "gcs" "azure")) }}
{{-       if not $objectStorage.config.secret -}}
toolbox:
    A valid object storage config secret is needed for backups.
    Please configure it via `gitlab.toolbox.backups.objectStorage.config.secret`.
{{-       else if and (eq $objectStorage.backend "azure") (not $objectStorage.config.azureBaseUrl) -}}
toolbox:
    A valid Azure base URL is needed for backing up to Azure.
    Please configure it via `gitlab.toolbox.backups.objectStorage.config.azureBaseUrl`.
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.toolbox.backups.objectStorage.config.secret */}}

{{/*
Ensure that gitlab/toolbox is not configured with `replicas` > 1 if
persistence is enabled.
*/}}
{{- define "gitlab.toolbox.replicas" -}}
{{-   $replicas := index $.Values.gitlab "toolbox" "replicas" | int -}}
{{-   if and (gt $replicas 1) (index $.Values.gitlab "toolbox" "persistence" "enabled") -}}
toolbox: replicas is greater than 1, with persistence enabled.
    It appear that `gitlab/toolbox` has been configured with more than 1 replica, but also with a PersistentVolumeClaim. This is not supported. Please either reduce the replicas to 1, or disable persistence.
{{-   end -}}
{{- end -}}
{{/* END gitlab.toolbox.replicas */}}
