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

@test "invoking script for stable pipeline" {
  export DIGESTS_FILE='ci.digests.stable.yaml'
  export CI_COMMIT_BRANCH='7-6-stable'

  run scripts/ci/pin_image_digests.sh

  [ "$status" -eq 0 ]
}

# @teardown {
#   rm -f $DIGESTS_FILE
#   unset DIGESTS_FILE
# }
