{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified job name.
Due to the job only being allowed to run once, we add a timestamp so helm
upgrades don't cause errors trying to create the already ran job.
*/}}
{{- define "migrations.jobname" -}}
{{- $name := include "fullname" . | trunc 41 | trimSuffix "-" -}}
{{- $timestamp := include "gitlab.timestamp" . }}
{{- printf "%s-%s" $name $timestamp | trunc 63 | trimSuffix "-" -}}
{{- end -}}
