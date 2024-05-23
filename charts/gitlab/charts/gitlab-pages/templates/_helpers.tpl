{{/*
Returns the secret name for the Secret containing the TLS certificate and key.
Uses `ingress.tls.secretName` first and falls back to `global.ingress.tls.secretName`
if there is a shared tls secret for all ingresses.
*/}}
{{- define "pages.tlsSecret" -}}
{{- $defaultName := (dict "secretName" "") -}}
{{- if .Values.global.ingress.configureCertmanager -}}
{{- $_ := set $defaultName "secretName" (printf "%s-pages-tls" .Release.Name) -}}
{{- else -}}
{{- $_ := set $defaultName "secretName" (include "gitlab.wildcard-self-signed-cert-name" .) -}}
{{- end -}}
{{- pluck "secretName" .Values.ingress.tls .Values.global.ingress.tls $defaultName | first -}}
{{- end -}}

{{/*
Return the pages-metrics TLS secret name
*/}}
{{- define "pages-metrics.tls.secret" -}}
{{- default (printf "%s-pages-metrics-tls" .Release.Name) $.Values.metrics.tls.secretName | quote -}}
{{- end -}}

{{/*
Optionally create a node affinity rule to optionally deploy gitlab-pages pods in a specific zone
*/}}

{{- define "gitlabpages.affinity" -}}
{{- $affinityOptions := list "hard" "soft" }}
{{- if or
  (has (default .Values.global.antiAffinity "") $affinityOptions)
  (has (default .Values.antiAffinity "") $affinityOptions)
  (has (default .Values.global.nodeAffinity "") $affinityOptions)
  (has (default .Values.nodeAffinity "") $affinityOptions)
}}
affinity:
  {{- if eq (default .Values.global.antiAffinity .Values.antiAffinity) "hard" }}
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - topologyKey: {{ default .Values.global.affinity.podAntiAffinity.topologyKey .Values.affinity.podAntiAffinity.topologyKey | quote }}
          labelSelector:
            matchLabels:
              app: {{ template "name" . }}
              release: {{ .Release.Name }}
  {{- else if eq (default .Values.global.antiAffinity .Values.antiAffinity) "soft" }}
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          podAffinityTerm:
            topologyKey: {{ default .Values.global.affinity.podAntiAffinity.topologyKey .Values.affinity.podAntiAffinity.topologyKey | quote }}
            labelSelector:
              matchLabels:
                app: {{ template "name" . }}
                release: {{ .Release.Name }}
  {{- end -}}
  {{- if eq (default .Values.global.nodeAffinity .Values.nodeAffinity) "hard" }}
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: {{ default .Values.global.affinity.nodeAffinity.key .Values.affinity.nodeAffinity.key | quote }}
                operator: In
                values: {{ default .Values.global.affinity.nodeAffinity.values .Values.affinity.nodeAffinity.values | toYaml | nindent 16 }}

  {{- else if eq (default .Values.global.nodeAffinity .Values.nodeAffinity) "soft" }}
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          nodeSelectorTerms:
            - matchExpressions:
                - key: {{ default .Values.global.affinity.nodeAffinity.key .Values.affinity.nodeAffinity.key | quote }}
                  operator: In
                  values: {{ default .Values.global.affinity.nodeAffinity.values .Values.affinity.nodeAffinity.values | toYaml | nindent 18 }}
  {{- end -}}
{{- end -}}
{{- end }}