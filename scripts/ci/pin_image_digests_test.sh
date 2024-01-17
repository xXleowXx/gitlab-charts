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

@test "invoking script for master pipeline" {
  export DIGESTS_FILE='ci.digests.master.yaml'

  expected='^master@sha256:[[:xdigit:]]{64}$'

  source scripts/ci/pin_image_digests.sh
  run tag_and_digest 'kubectl'

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]
}

# @teardown {
#   rm -f $DIGESTS_FILE
#   unset DIGESTS_FILE
# }
