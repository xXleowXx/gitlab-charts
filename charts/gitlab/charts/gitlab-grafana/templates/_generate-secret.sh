namespace={{ .Release.Namespace }}
release={{ .Release.Name }}
env={{ .Values.env }}

pushd $(mktemp -d)

# Args pattern, length
function gen_random(){
  head -c 4096 /dev/urandom | LC_CTYPE=C tr -cd $1 | head -c $2
}

# Args: secretname
function label_secret(){
  local secret_name=$1
{{ if not .Values.global.application.create -}}
  # Remove application labels if they exist
  kubectl --namespace=$namespace label \
    secret $secret_name $(echo '{{ include "gitlab.application.labels" . | replace ": " "=" | replace "\n" " " }}' | sed -E 's/=[^ ]*/-/g')
{{ end }}
  kubectl --namespace=$namespace label \
    --overwrite \
    secret $secret_name {{ include "gitlab.standardLabels" . | replace ": " "=" | replace "\n" " " }}
}

# Args: secretname, args
function generate_secret_if_needed(){
  local secret_args=( "${@:2}")
  local secret_name=$1
  if ! $(kubectl --namespace=$namespace get secret $secret_name > /dev/null 2>&1); then
    kubectl --namespace=$namespace create secret generic $secret_name ${secret_args[@]}
  else
    echo "secret \"$secret_name\" already exists"
  fi;
  label_secret $secret_name
}

{{ if .Values.enabled -}}
# Grafana password
generate_secret_if_needed "gitlab-grafana-initial-password" --from-literal=password=$(gen_random 'a-zA-Z0-9' 64)
{{ end }}
