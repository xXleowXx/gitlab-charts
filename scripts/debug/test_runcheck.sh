#!/usr/bin/env bash

mkdir chart-info

# Usage:
#   test OLD_VERSION OLD_CHART_VERSION NEW_VERSION NEW_CHART_VERSION [SUFFIX]
test_runcheck() {
  echo "${1}" > chart-info/gitlabVersion
  echo "${2}" > chart-info/gitlabChartVersion

  docker run \
    --rm -t \
    -v ${PWD}/templates/_runcheck.tpl:/scripts/runcheck \
    -v ${PWD}/chart-info:/chart-info \
    -e GITLAB_VERSION="${3}" \
    -e CHART_VERSION="${4}" \
    "registry.gitlab.com/gitlab-org/build/cng/gitlab-base:master${5}" \
    /bin/sh /scripts/runcheck > /dev/null && echo 'PASS' || echo 'FAIL'
}

echo "Testing upgrade paths expected to pass"
test_runcheck '16.11.0' '7.11.0' '17.0.0' '8.0.0'
test_runcheck '16.11.1' '7.11.1' '17.0.0' '8.0.0'
test_runcheck '16.11.1' '7.11.1' '17.1.0' '17.1.0'

echo "Testing upgrade paths expected to fail"
test_runcheck '16.10.0' '7.10.0' '17.0.0' '8.0.0'
test_runcheck '16.10.3' '7.10.3' '17.0.0' '8.0.0'
test_runcheck '15.11.0' '6.11.0' '17.0.0' '8.0.0'
test_runcheck '16.11.0' '7.10.0' '17.0.0' '8.0.0'

