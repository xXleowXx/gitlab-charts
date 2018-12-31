{{- define "gitlab.shellConfig" -}}
path: /home/git/gitlab-shell/
hooks_path: /home/git/gitlab-shell/hooks/
secret_file: /etc/gitlab/shell/.gitlab_shell_secret
upload_pack: true
receive_pack: true
ssh_port: {{ include "gitlab.shell.port" . | int }}
{{- end -}}
