{{/* vim: set filetype=mustache: */}}

{{/*
Create a default fully qualified job name.
The name contains a hash that is based on the chart's app version
and the chart's values (which also might contain the global.gitlabVersion)
to make sure that the job is run at least once everytime GitLab is updated.

In order to make sure that the hash is stable for `helm template`
and `helm upgrade --install`, we need to remove the `local` block injected
by the template file `charts/gitlab/templates/_databaseDatamodel.tpl`.

This local block contains the values of the Helm "built-in object"
(see https://helm.sh/docs/chart_template_guide/builtin_objects) which would
result in different hash values due to fields like `Release.IsUpgrade`,
`Release.IsInstall` and especially `Release.Revision`.
*/}}
{{- define "migrations.jobname" -}}
{{- $values := deepCopy .Values -}}
{{- $values := unset $values "local" -}}
{{- $name := include "fullname" . | trunc 55 | trimSuffix "-" -}}
{{- $hash := printf "%s-%s" .Chart.AppVersion ( $values | toYaml | b64enc ) | sha256sum | trunc 7 }}
{{- printf "%s-%s" $name $hash | trunc 63 | trimSuffix "-" -}}
{{- end -}}
