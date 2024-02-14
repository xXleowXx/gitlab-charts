#!/usr/bin/env bash

# Prints active Helm releases in a given cluster namespace and opens
# the parent pipeline in the browser.
#
# Used to triage installations, specifically those that have not been
# automatically uninstalled after the Review App deadline for various
# reasons (job failure, manual retry, etc.).
#
# Dependencies:
# - helm:   https://helm.sh
# - fzf:    https://github.com/junegunn/fzf
# - yq:     https://github.com/mikefarah/yq
# - column: https://linux.die.net/man/1/column
# - open:   https://linux.die.net/man/1/open
#
# Usage:
# 1. Connect to a Kubernetes cluster in your terminal session.
# 2. Connect to the namespace you want to check (using `kubectl config set-context` or `kubens`, for example).
# 3. Run this script: `./scripts/ci/helm_ci_triage.sh`
# 4. Use the up/down arrows to select a release. You can also type to filter the results.
# 5. Press 'enter' to select the release, which will open the associated pipeline in your browser.
# 6. Run the relevant `stop_review` job(s) from the CI pipeline page.

releases=$(helm ls \
  | tail -n +2 \
  | sort \
  | awk '{print $1 " " $4 " " $5}' \
  | column -t)

release=$(printf "quit\n${releases}" \
  | fzf --header='Active Helm releases (type or select then press "enter" to open parent pipeline)' \
  | awk '{print $1}')

if [ "${release}" = "quit" ]; then
  echo 'No release selected, exiting...'
  exit 1
fi

url=$(helm get values "${release}" | yq .ci.pipeline.url)
open "${url}"
