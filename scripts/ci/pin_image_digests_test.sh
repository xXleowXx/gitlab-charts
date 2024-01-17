#!/bin/bash
set -e

# This script tests the behavior of the pin_image_digests.sh
# script using bats
#
# Dependencies:
# - skopeo  # from script being tested
# - bats
#
# Usage:
# $ bats scripts/ci/pin_image_digests_test.sh

@test "invoking script on master branch" {
  CHART_FILE='Chart.master.yaml'
  echo 'appVersion: master' > $CHART_FILE

  expected='^master@sha256:[[:xdigit:]]{64}$'

  source scripts/ci/pin_image_digests.sh
  run tag_and_digest 'gitlab-webservice-ee'

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]
}

@test "invoking script with GITLAB_VERSION" {
  skip  # come back to this
  GITLAB_VERSION='v16.8.0-ee'

  expected='^master@sha256:[[:xdigit:]]{64}$'

  source scripts/ci/pin_image_digests.sh
  run tag_and_digest 'gitlab-webservice-ee'

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]
}

@test "invoking script on stable branch" {
  CI_COMMIT_BRANCH='7-8-stable'
  CHART_FILE='Chart.stable.yaml'
  echo 'appVersion: v16.8.0' > $CHART_FILE

  expected='^[0-9]+-[0-9]+-stable@sha256:[[:xdigit:]]{64}$'

  source scripts/ci/pin_image_digests.sh
  run tag_and_digest 'gitlab-webservice-ee'

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]
}

# teardown() {
#   echo
# }
