{{/*
Returns a image tag from the passed in app version or branchname
Usage:
{{ include "gitlab.parseAppVersion" (    \
     dict                                \
         "appVersion" .Chart.AppVersion  \
         "prepend" "false"               \
     ) }}
1. If the version is a semver version, we check the prepend flag.
   1. If it is true, we prepend a `v` and return `vx.y.z` image tag.
   2. If it is false, we do not prepend a `v` and just use the input version
2. Else we just use the version passed as the image tag
*/}}
{{- define "gitlab.parseAppVersion" -}}
{{- $appVersion := coalesce .appVersion "master" -}}
{{- if regexMatch "^\\d+\\.\\d+\\.\\d+(-rc\\d+)?(-pre)?$" $appVersion -}}
{{-   if eq .prepend "true" -}}
{{-      printf "v%s" $appVersion -}}
{{-   else -}}
{{-      $appVersion -}}
{{-   end -}}
{{- else -}}
{{- $appVersion -}}
{{- end -}}
{{- end -}}

{{/*
Defines the registry for a given image.
*/}}
{{- define "image.registry" -}}
{{-   coalesce .local.registry .global.registry -}}
{{- end -}}

{{/*
Defines the repository for a given image.
*/}}
{{- define "image.repository" -}}
{{-  coalesce .local.repository .global.repository -}}
{{- end -}}

{{/*
Returns the image repository depending on the value of global.edition.

Used to switch the deployment from Enterprise Edition (default) to Community
Edition. If global.edition=ce, returns the Community Edition image repository
set in the Gitlab values.yaml, otherwise returns the Enterprise Edition
image repository.
*/}}
{{- define "image.name" -}}
{{-   $name := coalesce .name .context.Chart.Name -}}
{{-   $defaultName := printf "gitlab-%s-%s" $name .context.Values.global.edition -}}
{{-   coalesce .local.name $name -}}
{{- end -}}

{{/*
Return the version tag used to fetch the GitLab images
Defaults to using the information from the chart appVersion field, but can be
overridden using the global.gitlabVersion field in values.
*/}}
{{- define "image.tag" -}}
{{-   $prepend := coalesce .local.prepend "false" -}}
{{-   $appVersion := include "gitlab.parseAppVersion" (dict "appVersion" .context.Chart.AppVersion "prepend" $prepend) -}}
{{-   coalesce .local.tag $appVersion }}
{{- end -}}

{{/*
Creates the full image path for use in manifests.
*/}}
{{- define "image.fullpath" -}}
{{-   $registry := include "image.registry" . -}}
{{-   $repository := include "image.repository" . -}}
{{-   $name := include "image.name" . -}}
{{-   $tag := include "image.tag" . -}}
{{-   printf "%s/%s/%s:%s" $registry $repository $name $tag -}}
{{- end -}}
