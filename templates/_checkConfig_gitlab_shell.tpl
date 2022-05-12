{{- define "gitlab.checkConfig.gitlabShell.proxyPolicy" -}}
{{- $config := (index .Values "gitlab" "gitlab-shell").config -}}
{{- if and $config.proxyProtocol (eq $config.proxyPolicy "reject") -}}
gitlab-shell:
  gitlab.gitlab-shell.config.proxyProtocol is enabled, but gitlab.gitlab-shell.config.proxyPolicy is set to "reject".
  gitlab-shell will not accept connections since these settings conflict with each other. 
  Either disable proxyProtocol or set proxyPolicy to "use", "require", or "ignore".
{{- end -}}
{{- end -}}
{{/* END "gitlab.checkConfig.gitlabShell.proxyPolicy" */}}
