{{- define "gitlab.praefect.serviceName" -}}
{{- coalesce ( .Values.praefect.serviceName ) .Values.global.praefect.serviceName (include "gitlab.other.fullname" (dict "context" . "chartName" "praefect" )) -}}
{{- end -}}
