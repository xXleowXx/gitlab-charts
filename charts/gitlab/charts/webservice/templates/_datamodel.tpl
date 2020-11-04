{{/* vim: set filetype=mustache: */}}

{{/*
webservice.datamodel.prepare

!! To be run against $

Walks `deployments` and merges `webservice.datamodel.blank` into each
item, ensuring presence of all keys.
*/}}
{{- define "webservice.datamodel.prepare" -}}
{{- $fullname := include "webservice.fullname" $ -}}
{{/* make sure we always have at least one */}}
{{- if not $.Values.deployments -}}
{{-   $blank := fromYaml (include "webservice.datamodel.blank" $) -}}
{{-   $_ := set $blank.ingress "path" "/" -}}
{{-   $_ := set $.Values "deployments" (dict) -}}
{{-   $_ := set $.Values.deployments "web" $blank -}}
{{- end -}}
{{- range $deployment, $values := $.Values.deployments -}}
{{-   $blank := fromYaml (include "webservice.datamodel.blank" $) -}}
{{-   $_ := set $values "name" $deployment -}}
{{-   $_ := set $values "fullname" $fullname -}}
{{-   $_ := set $.Values.deployments $deployment (merge $values $blank) -}}
{{- end -}}
{{- end -}}

{{- define "webservice.datamodel.blank" -}}
ingress:
  path:
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
