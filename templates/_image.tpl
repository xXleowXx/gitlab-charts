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
{{-   $appVersion := coalesce .appVersion "master" -}}
{{-   if regexMatch "^\\d+\\.\\d+\\.\\d+(-rc\\d+)?(-pre)?$" $appVersion -}}
{{-     if eq .prepend "true" -}}
{{-       printf "v%s" $appVersion -}}
{{-     else -}}
{{-        $appVersion -}}
{{-     end -}}
{{-   else -}}
{{-     $appVersion -}}
{{-   end -}}
{{- end -}}

{{/*
Defines the registry for a given image.
*/}}
{{- define "gitlab.image.registry" -}}
{{-   coalesce .local.registry .global.registry "none" -}}
{{- end -}}

{{/*
Defines the repository for a given image.
*/}}
{{- define "gitlab.image.repository" -}}
{{-   coalesce .local.repository .global.repository -}}
{{- end -}}

{{/*
Return the version tag used to fetch the GitLab images
Defaults to using the information from the chart appVersion field, but can be
overridden using the global.gitlabVersion field in values.
*/}}
{{- define "gitlab.image.tag" -}}
{{-   $prepend := coalesce .local.prepend "false" -}}
{{-   $appVersion := include "gitlab.parseAppVersion" (dict "appVersion" .context.Chart.AppVersion "prepend" $prepend) -}}
{{-   coalesce .local.tag .global.tag $appVersion }}
{{- end -}}

{{/*
Return the image digest to use.
*/}}
{{- define "gitlab.image.digest" -}}
{{-   if .local.digest -}}
{{-     printf "@%s" .local.digest -}}
{{-   end -}}
{{- end -}}

{{/*
Creates the full image path for use in manifests.
Will replace the `-ee` edition suffix if `global.edition=ce`.
*/}}
{{- define "gitlab.image.fullPath" -}}
{{-   $registry := include "gitlab.image.registry" . -}}
{{-   $repository := include "gitlab.image.repository" . -}}
{{-   $tag := include "gitlab.image.tag" . -}}
{{-   $tagSuffix := include "gitlab.image.tagSuffix" . -}}
{{-   $digest := include "gitlab.image.digest" . -}}
{{-   if hasSuffix "-ee" $repository -}}
{{-      if eq .context.Values.global.edition "ce" -}}
{{-        $repository = print $repository | replace "-ee" "-ce" -}}
{{-      end -}}
{{-   end -}}
{{-   if eq $registry "none" -}}
{{-     printf "%s:%s%s%s" $repository $tag $tagSuffix $digest | quote -}}
{{-   else -}}
{{-     printf "%s/%s:%s%s%s" $registry $repository $tag $tagSuffix $digest | quote -}}
{{-   end -}}
{{- end -}}

{{/*
  A helper template for collecting and inserting the imagePullSecrets.

  It expects a dictionary with two entries:
    - `global` which contains global image settings, e.g. .Values.global.image
    - `local` which contains local image settings, e.g. .Values.image
*/}}
{{- define "gitlab.image.pullSecrets" -}}
{{-   $pullSecrets := default (list) .global.pullSecrets -}}
{{-   if .local.pullSecrets -}}
{{-   $pullSecrets = concat $pullSecrets .local.pullSecrets -}}
{{-   end -}}
{{-   if $pullSecrets }}
imagePullSecrets:
{{-     range $index, $entry := $pullSecrets }}
- name: {{ $entry.name }}
{{-     end }}
{{-   end }}
{{- end -}}

{{/*
  A helper template for inserting imagePullPolicy.

  It expects a dictionary with two entries:
    - `global` which contains global image settings, e.g. .Values.global.image
    - `local` which contains local image settings, e.g. .Values.image
*/}}
{{- define "gitlab.image.pullPolicy" -}}
{{-   $pullPolicy := coalesce .local.pullPolicy .global.pullPolicy -}}
{{-   if $pullPolicy }}
imagePullPolicy: {{ $pullPolicy | quote }}
{{-   end -}}
{{- end -}}
