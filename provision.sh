#!/bin/bash

function pre_check() {
  # Enables using colors for stdout.
  if test -t 1; then
      # Now check the _number_ of colors.
      NUM_COLORS=$(tput colors)
      if test -n "${NUM_COLORS}" && test ${NUM_COLORS} -ge 8; then
          NORMAL=$(tput sgr0)
          BOLD=$(tput bold)
          UNDERLINE=$(tput smul)
          REVERSE=$(tput smso)
          BLINK=$(tput blink)
          BLACK=$(tput setaf 0)
          RED=$(tput setaf 1)
          GREEN=$(tput setaf 2)
          YELLOW=$(tput setaf 3)
          BLUE=$(tput setaf 4)
          MAGENTA=$(tput setaf 5)
          CYAN=$(tput setaf 6)
          WHITE=$(tput setaf 7)
      fi
  fi

  if ! command -v jq > /dev/null 2>&1;then
    echo "${RED}pre check failed: ${MAGENTA}jq not found${NORMAL}"
    exit 1
  fi

  if ! command -v ansible > /dev/null 2>&1;then
    echo "${RED}pre check failed: ${MAGENTA}ansible not found${NORMAL}"
    exit 1
  fi

  if ! command -v python3 > /dev/null 2>&1;then
    echo "${RED}pre check failed: ${MAGENTA}python3 not found${NORMAL}"
    exit 1
  fi

  pushd ansible > /dev/null 2>&1
  #ansible workers -m ping > /dev/null 2>&1 
  #test $? -eq 0 || echo "${RED}pre check failed: ${MAGENTA}could not connect to workers${NORMAL}";exit 1
  if ! ansible workers -m ping > /dev/null 2>&1;then
    echo "${RED}pre check failed: ${MAGENTA}could not connect to workers${NORMAL}"
    exit 1
  fi
  popd > /dev/null 2>&1
}

function get_registration_token() {
  api_url='https://xx.xx.xx.xx'
  api_token='token-xxxxxx'
  cluster_name='k8s-1'
  
  cluster_ID=$( curl -s -k -H "Authorization: Bearer ${api_token}" $api_url/v3/clusters | jq -r ".data[] | select(.name == \"$cluster_name\") | .id" )
  
  # nodeCommand
  registration_command=`curl -s -k -H "Authorization: Bearer ${api_token}" $api_url/v3/clusters/${cluster_ID}/clusterregistrationtokens | jq -r .data[].nodeCommand` > /dev/null 2>&1
}

function add_workers() {
  get_registration_token

  if [ "$registration_command" != "" ];then
	pushd ansible > /dev/null 2>&1
	registration_command="${registration_command} "--worker""
	#registration_command="${registration_command} --etcd --controlplane --worker"
	ansible -i xlsx_inventory.py k8s-worker -b --become-method su --become-user sysop -a "${registration_command}"
  	popd > /dev/null 2>&1
  fi
}

function configure_workers() {
  pushd ansible > /dev/null 2>&1
  ansible-playbook -i xlsx_inventory.py prepare-environment.yaml
  popd > /dev/null 2>&1
}

function usage() {
  echo "##############################################################################################"
  echo -e "Usage:\n"
  echo "This script aims to provision rancher worker nodes automatically."
  echo -e "\t${0} -k pre check"
  echo -e "\t${0} -c configure worker nodes(eg: Add system utlization options, install docker, etc.)"
  echo -e "\t${0} -a add workers into rancher cluster"
  echo -e "\t${0} -h usage"

  echo "##############################################################################################"
}

while getopts "khac" opt
do
  case $opt in
    k)
      pre_check
      echo "${GREEN}pre-check succeed.${NORMAL}"
      exit 0
      ;;
    a)
	  # add kubernetes workers 
      pre_check
      add_workers
      exit 0
      ;;
    c)
      pre_check
      configure_workers
      exit 0
      ;;
    h)
      usage
      exit 0
      ;;
    ?)
      usage
      exit 1
      ;;
  esac
done

shift $(($OPTIND - 1))

if [ $# != 1 ];then
  echo "You should specify the runing mode, eg: ${0} -a or -c "
  usage
  exit 1
fi
