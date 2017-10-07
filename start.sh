#!/bin/bash

# gitlab-ci-multi-runner data directory
DATA_DIR="/etc/gitlab-runner"
CONFIG_FILE=${CONFIG_FILE:-$DATA_DIR/config.toml}
# custom certificate authority path
CA_CERTIFICATES_PATH=${CA_CERTIFICATES_PATH:-$DATA_DIR/certs/ca.crt}
LOCAL_CA_PATH="/usr/local/share/ca-certificates/ca.crt"

update_ca() {
  echo "Updating CA certificates..."
  cp "${CA_CERTIFICATES_PATH}" "${LOCAL_CA_PATH}"
  update-ca-certificates --fresh >/dev/null
}

if [ -f "${CA_CERTIFICATES_PATH}" ]; then
  # update the ca if the custom ca is different than the current
  cmp --silent "${CA_CERTIFICATES_PATH}" "${LOCAL_CA_PATH}" || update_ca
fi

export CI_USER=gitlab-runner
export WORKING_DIR=/home/${CI_USER}/${HOSTNAME}

# Verify existing configuration
if [[ -f $DATA_DIR/config.toml ]]
then
  gitlab-runner verify --delete --config $DATA_DIR/config.toml
  runner_count=$(($(gitlab-runner list --config $DATA_DIR/config.toml &> .gitlab-runner-list && cat .gitlab-runner-list | wc -l && rm .gitlab-runner-list)-1))
  if [[ $DEBUG ]]
  then
    echo "There is ${runner_count} runner in the config.toml"
  fi
fi

if [[ ! -f $DATA_DIR/config.toml || ${runner_count} -lt 1 ]]
then
  # Register a new register if there is none yet
  export REGISTER_NON_INTERACTIVE=true
  export RUNNER_EXECUTOR=docker
  export RUNNER_TAG_LIST=${RUNNER_EXECUTOR},${RUNNER_TAG_LIST}
  export DOCKER_PRIVILEGED=true
  # Verifying some env var existence
  : "${CI_SERVER_URL:?CI_SERVER_URL has to be set and non-empty}"
  : "${REGISTRATION_TOKEN:?REGISTRATION_TOKEN has to be set and non-empty}"
  : "${DOCKER_IMAGE:?DOCKER_IMAGE has to be set and non-empty}"
  # Setting $RUNNER_NAME if none defined
  export RUNNER_NAME="${RUNNER_NAME:-Running on ${HOSTNAME}}"
  gitlab-runner register -n
  echo "end";
fi

if [ -d "/usr/local/docker_share/config"]
then
  cd /usr/local/docker_share/config
  git pull $REPO_URL
fi

if [ ! -d "/usr/local/docker_share/config"]
then
  cd /usr/local/docker_share/
  git clone $REPO_URL
fi

# launch gitlab-ci-multi-runner passing all arguments
exec gitlab-ci-multi-runner "$@"

if [[ $DEBUG ]]
then
  echo "Printing the config.toml file..."
  cat $DATA_DIR/config.toml
  echo "Printed"
fi
