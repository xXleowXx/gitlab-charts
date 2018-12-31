{{- define "gitlab.configYaml.shell" -}}
path: /home/git/gitlab-shell/
hooks_path: /home/git/gitlab-shell/hooks/
secret_file: /etc/gitlab/shell/.gitlab_shell_secret
upload_pack: true
receive_pack: true
ssh_port: {{ include "gitlab.shell.port" . | int }}
{{- end -}}

{{- define "gitlab.configYaml.rackAttack" -}}
git_basic_auth:
  {{- if .Values.rack_attack.git_basic_auth.enabled }}
{{ toYaml .Values.rack_attack.git_basic_auth | indent 2 }}
  {{- end }}
## Registry Integration
{{- include "gitlab.appConfig.registry.configuration" $ | nindent 6 }}
{{- end -}}

{{- define "gitlab.configYaml.extra" -}}
google_analytics_id: {{ .extra.googleAnalyticsId | quote }}
piwik_url: {{ .extra.piwikUrl | quote }}
piwik_site_id: {{ .extra.piwikSiteId | quote }}
{{- end -}}

{{- define "gitlab.configYaml.gitaly" -}}
client_path: /home/git/gitaly/bin
token: "<%= File.read('/etc/gitlab/gitaly/gitaly_token') %>"
{{- end -}}

{{- define "gitlab.configYaml.repositories" -}}
 storages: # You must have at least a `default` storage path.
{{ include "gitlab.gitaly.storages" . | indent 2 }}
{{- end -}}
