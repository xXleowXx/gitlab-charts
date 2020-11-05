{{/* vim: set filetype=mustache: */}}

{{/*
webservice.datamodel.prepare

!! To be run against $

Walks `deployments` and merges `webservice.datamodel.blank` into each
item, ensuring presence of all keys.
*/}}
{{- define "webservice.datamodel.prepare" -}}
{{- $fullname := include "webservice.fullname" $ -}}
{{- $blank := dict -}}
{{/* make sure we always have at least one */}}
{{- if not $.Values.deployments -}}
{{-   $blank := fromYaml (include "webservice.datamodel.blank" $) -}}
{{-   $_ := set $blank.ingress "path" "/" -}}
{{-   $_ := set $.Values "deployments" (dict) -}}
{{-   $_ := set $.Values.deployments "web" $blank -}}
{{- end -}}
{{/* walk all entries, do ensure default properties populated */}}
{{- $checks := dict "hasBasePath" false -}}
{{- range $deployment, $values := $.Values.deployments -}}
{{-   $blank := fromYaml (include "webservice.datamodel.blank" $) -}}
{{-   $_ := set $values "name" $deployment -}}
{{-   $_ := set $values "fullname" $fullname -}}
{{-   $_ := set $.Values.deployments $deployment (merge $values $blank) -}}
{{-   if eq ($values.ingress.path | toString ) "/" -}}
{{-     $_ := set $checks "hasBasePath" true -}}
{{-   end -}}
{{- end -}}
{{- if not $checks.hasBasePath -}}
{{-   fail "FATAL: Webservice: no deployment with ingress.path '/' specified." -}}
{{- end -}}
{{- end -}}

{{/*
webservice.datamodel.prepare

!! To be run against $

Creates a copy of the data model expected for `deployments` entries,
pulling default values from the appropriate items in `.Values.xyz`.
This is output as YAML, it can be read back in as a dict via `toYaml`.
*/}}
{{- define "webservice.datamodel.blank" -}}
ingress:
  path: # intentionally not setting a value. User must set.
  annotations:
    {{- .Values.ingress.annotations | toYaml | nindent 4 }}
  proxyConnectTimeout: {{ .Values.ingress.proxyConnectTimeout }}
  proxyReadTimeout: {{ .Values.ingress.proxyReadTimeout }}
  proxyBodySize: {{ .Values.ingress.proxyBodySize | quote }}
deployment:
  annotations: {}
  labels: {}
  {{- .Values.deployment | toYaml | nindent 2 }}
pod:
  labels: {} # additional labels to .podLabels
  annotations: # inherit from .Values.annotations
    {{ toYaml .Values.annotations | nindent 4 }}
service:
  labels: {} # additional labels to .serviceLabels
  annotations: {} # additional annotations to .service.annotations
hpa:
  minReplicas: {{ .Values.minReplicas }} # defaults to .minReplicas
  maxReplicas: {{ .Values.minReplicas }} # defaults to .maxReplicas
  metrics: {} # optional replacement of HPA metrics definition
  {{- .Values.hpa | toYaml | nindent 2 }}
pdb:
  maxUnavailable: {{ .Values.maxUnavailable }} # defaults to .maxUnavailable
resources: # resources for `webservice` container
  {{- .Values.resources | toYaml | nindent 2 }}
workhorse:
  resources:
    {{- .Values.workhorse.resources | toYaml | nindent 4 }}
  livenessProbe:
    {{- .Values.workhorse.livenessProbe | toYaml | nindent 4 }}
  readinessProbe:
    {{- .Values.workhorse.readinessProbe | toYaml | nindent 4 }}
extraEnv:
  {{- .Values.extraEnv | toYaml | nindent 2 }}
puma:
  {{- .Values.puma | toYaml | nindent 2 }}
shutdown:
  {{- .Values.shutdown | toYaml | nindent 2 }}
{{- end -}}
