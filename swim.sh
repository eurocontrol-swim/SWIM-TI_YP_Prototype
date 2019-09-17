#!/bin/bash

ROOT_DIR=${PWD}
SERVICES_DIR=${ROOT_DIR}'/services'
SUBSCRIPTION_MANAGER_DIR=${SERVICES_DIR}"/subscription_manager/src"
SWIM_ADSB_DIR=${SERVICES_DIR}"/swim_adsb/src"
SWIM_EXPLORER_DIR=${SERVICES_DIR}"/swim_explorer/src"


clone_repos() {
  echo "Cloning Git repositories..."
  echo -e "============================\n"
  git clone https://antavelos-eurocontrol@bitbucket.org/antavelos-eurocontrol/subscription-manager.git "${SUBSCRIPTION_MANAGER_DIR}"
  git clone https://antavelos-eurocontrol@bitbucket.org/antavelos-eurocontrol/swim-adsb.git "${SWIM_ADSB_DIR}"
  git clone https://antavelos-eurocontrol@bitbucket.org/antavelos-eurocontrol/swim-explorer.git "${SWIM_EXPLORER_DIR}"
  echo ""
}

update_repos() {
  echo "Updating Git repositories..."
  echo -e "============================\n"
  cd "${SUBSCRIPTION_MANAGER_DIR}" || exit
  git pull --rebase origin master
  cd "${SWIM_ADSB_DIR}" || exit
  git pull --rebase origin master
  cd "${SWIM_EXPLORER_DIR}" || exit
  git pull --rebase origin master
  cd "${ROOT_DIR}" || exit
  echo ""
}

data_provision() {
  echo "Data provisioning to Subscription Manager..."
  echo -e "============================================\n"
  docker-compose up -d subscription-manager-provision
  echo ""
}

start_services() {
  echo "Starting up SWIM..."
  echo -e "===================\n"
  docker-compose up -d web-server subscription-manager swim-adsb swim-explorer
  echo ""
}

stop_services_with_clean() {
  echo "Stopping SWIM..."
  echo -e "================\n"
  docker-compose down
  echo ""
}

stop_services() {
  echo "Stopping SWIM..."
  echo -e "================\n"
  docker-compose stop
  echo ""
}

build() {
  echo "Building images..."
  echo -e "==================\n"
  # build the base image upon which the swim services will depend on
  docker build -t swim-base -f ./services/base/Dockerfile ./services/base
  docker build -t swim-base.conda -f ./services/base/Dockerfile.conda ./services/base
  docker-compose build
  echo ""

  echo "Removing obsolete docker images..."
  echo -e "==================================\n"
  docker images|grep none|awk '{print $3}'|xargs -r docker rmi
}

status() {
  docker ps
}

usage() {
  echo -e "Usage: swim.sh [COMMAND] [OPTIONS]\n"
  echo "Commands:"
  echo "    build           Clones/updates the necessary git repositories and builds the involved docker images"
  echo "    provision       Provisions the Subscription Manager with initial data (users)"
  echo "    start           Starts up all the SWIM services"
  echo "    start --prov    Starts up all the SWIM services after Provisioning the Subscription Manager with initial data"
  echo "    stop            Stops all the services"
  echo "    stop --clean    Stops all the services and cleans up the containers"
  echo "    status          Displays the status of the running containers"
  echo ""
}

if [[ $# -lt 1 || $# -gt 2  ]]
then
  usage
  exit 0
fi

ACTION=${1}

case ${ACTION} in
  build)
    # update the repos if they exits othewise clone them
    if [[ -d ${SUBSCRIPTION_MANAGER_DIR} && -d ${SWIM_ADSB_DIR} && -d ${SWIM_EXPLORER_DIR} ]]
    then
      update_repos
    else
      clone_repos
    fi

    # build the images
    build
    ;;
  start)
    if [[ -n ${2} ]]
    then
        EXTRA=${2}

        case ${EXTRA} in
          --prov)
            data_provision
            ;;
          *)
            echo -e "Invalid argument\n"
            usage
            exit 1
            ;;
        esac
    fi

    start_services
    ;;
  stop)
    if [[ -n ${2} ]]
    then
      EXTRA=${2}

      case ${EXTRA} in
          --clean)
            stop_services_with_clean
            ;;
          *)
            echo -e "Invalid argument\n"
            usage
            exit 1
            ;;
        esac
        exit 0
    fi
    stop_services
    ;;
  provision)
    data_provision
    ;;
  status)
    status
    ;;
  help)
    usage
    ;;
  *)
    echo -e "Invalid action\n"
    usage
    exit 1
    ;;
esac
