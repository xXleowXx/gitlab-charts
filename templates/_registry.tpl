{{/* ######### Registry related templates */}}

{{/*
Return the registry certificate secret name
*/}}
{{- define "gitlab.registry.certificate.secret" -}}
{{- default (printf "%s-registry-secret" .Release.Name) .Values.global.registry.certificate.secret | quote -}}
{{- end -}}

{{/*
Return the registry's httpSecert secret name
*/}}
{{- define "gitlab.registry.httpSecret.secret" -}}
{{- default (printf "%s-registry-httpsecret" .Release.Name) .Values.global.registry.httpSecret.secret | quote -}}
{{- end -}}

{{/*
Return the registry's httpSecert secret key
*/}}
{{- define "gitlab.registry.httpSecret.key" -}}
{{- default "secret" .Values.global.registry.httpSecret.key | quote -}}
{{- end -}}

{{/*
Return registry's database username
*/}}
{{- define "gitlab.registry.psql.username" -}}
{{- default "registry" .Values.registry.database.username }}
{{- end -}}

{{/*
Return registry's database name
*/}}
{{- define "gitlab.registry.psql.database" -}}
{{- .Values.registry.database.dbname }}
{{- end -}}

{{/*
Return registry's password secret name
*/}}
{{- define "gitlab.registry.psql.password.secret" -}}
{{- default (include "gitlab.psql.password.secret" .) .Values.registry.database.password.secret | quote -}}
{{- end -}}

{{/*
Return registry's password secret key
*/}}
{{- define "gitlab.registry.psql.password.key" -}}
{{- .Values.registry.database.password.key | quote -}}
{{- end -}}