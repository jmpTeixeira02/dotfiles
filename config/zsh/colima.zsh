export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
export DOCKER_HOST="unix://${XDG_CONFIG_HOME}/colima/docker.sock"

colima() {
  if [[ "$1" == "start" ]]; then
    command colima start --memory 8 --disk 200 --cpu 4 --dns 8.8.8.8
  else
    command colima "$@"
  fi
}
