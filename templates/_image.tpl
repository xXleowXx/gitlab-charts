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
{{-   coalesce .local.registry .global.registry .context.Values.global.image.registry "registry.gitlab.com" -}}
{{- end -}}

{{/*
Defines the repository for a given image.
*/}}
{{- define "image.repository" -}}
{{-  coalesce .local.repository .global.repository .context.Values.global.image.repository "gitlab-org/build/cng" -}}
{{- end -}}

{{/*
Defines the name for a given image.
Defaults to `gitlab-$chartName-$edition` if no local name is defined.
If the local name is defined as `toolbox`, then prepend `gitlab-` and
append `-$edition`. This ensures that charts such as Migrations that
need to use the Toolbox image get the correct image path since we can't
use the chart's name to calculate it.
*/}}
{{- define "image.name" -}}
{{-   $defaultName := printf "gitlab-%s-%s" .context.Chart.Name .context.Values.global.edition -}}
{{-   if eq .local.name "toolbox" -}}
{{-     printf "gitlab-%s-%s" "toolbox" .context.Values.global.edition -}}
{{-   else -}}
{{-     coalesce .local.name .global.name $defaultName -}}
{{-   end -}}
{{- end -}}

{{/*
Return the version tag used to fetch the GitLab images
Defaults to using the information from the chart appVersion field, but can be
overridden using the global.gitlabVersion field in values.
*/}}
{{- define "image.tag" -}}
{{-   $prepend := coalesce .local.prepend "false" -}}
{{-   $appVersion := include "gitlab.parseAppVersion" (dict "appVersion" .context.Chart.AppVersion "prepend" $prepend) -}}
{{-   coalesce .local.tag .global.tag $appVersion }}
{{- end -}}

{{/*
Return the image digest to use.
*/}}
{{- define "image.digest" -}}
{{-   $digest := "" -}}
{{-   if .local.digest -}}
{{-     $digest = printf "@%s" .local.digest -}}
{{-   end -}}
{{-   $digest -}}
{{- end -}}

{{/*
Creates the full image path for use in manifests.
*/}}
{{- define "image.fullpath" -}}
{{-   $registry := include "image.registry" . -}}
{{-   $repository := include "image.repository" . -}}
{{-   $name := include "image.name" . -}}
{{-   $tag := include "image.tag" . -}}
{{-   $digest := include "image.digest" . -}}
{{-   printf "%s/%s/%s:%s%s" $registry $repository $name $tag $digest | quote -}}
{{- end -}}
