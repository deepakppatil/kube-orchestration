#!/bin/bash
# ----------------------------------------------------------------------------
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# ----------------------------------------------------------------------------

#============================================================================
#
#title          : kube-manage
#author         : Deepak Patil
#date           : 20191013
#version        : 1.0
#usage          : ./kube-manage -s rolling
#Description    : Kube manage
#============================================================================

function print_header {
cat << "EOF"
 _          _
| | ___   _| |__   ___       _ __ ___   __ _ _ __   __ _  __ _  ___
| |/ / | | | '_ \ / _ \_____| '_ ` _ \ / _` | '_ \ / _` |/ _` |/ _ \
|   <| |_| | |_) |  __/_____| | | | | | (_| | | | | (_| | (_| |  __/
|_|\_\\__,_|_.__/ \___|     |_| |_| |_|\__,_|_| |_|\__,_|\__, |\___|
                                                         |___/

EOF
}


function print_msg {
    _msg="${1:-"what should i print as message?"}"
    if [[ "${2}" -eq 1 ]]; then
        log_type="Error : "
    elif [[ "${2}" -eq 9 ]]; then
        log_type="Fatal : "
    else
        log_type=""
    fi

    if [[ -z ${2} ]]; then
        echo ${log_type}${_msg}
    else
        if [[ -z ${3} ]]; then
            echo "$(tput setaf ${2})${log_type}${_msg}$(tput sgr 0)"
        else
            echo "$(tput bold)$(tput setaf ${2})${log_type}${1}$(tput sgr 0)"
        fi
    fi
}

function help {
    print_header
    print_msg " Cli for managing kube strategies deployment" 6 1
    cat << EOM

$(print_msg "  -s  [strategy] [no/rolling/bluegreen/canray] Sub-commands listed below;" 3 1)$(print_msg "
      log    : show logs for the container.
      help   : Display this help." 6)
EOM
}

function echolog {
    if [ $# -eq 0 ]
    then cat - | while read -r message
            do
                echo "$(date +"[%F %T %Z] -") $message" | tee -a ${log_file}
            done
    else
        echo -n "$(date +'[%F %T %Z]') - " | tee -a ${log_file}
        echo $* | tee -a ${log_file}
    fi
}

OPTIND=1
verbose=0
copy_env=0
force_recreate=0
options=0
while getopts ':hs:' option; do
  (( options++ ))
  case "$option" in
    h) help
       exit 0
       ;;
    s) strategy="$OPTARG"
       ;;
    :) echo "$(tput bold)$(tput setaf ${2})Missing argument for $OPTARG, kube-manage -h for help.$(tput sgr 0)"
       exit 1
       ;;
   \?) echo "$(tput bold)$(tput setaf ${2})Illegal option: $OPTARG, kube-manage -h for help.$(tput sgr 0)"
       exit 1
       ;;
   $@) echo "$(tput bold)$(tput setaf ${2})Illegal option: $OPTARG, kube-manage -h for help.$(tput sgr 0)"
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

[[ "${1:-}" = "--" ]] && shift

if [[ "${options}" -eq 0 ]]; then
    help; exit 0;
fi

function no_strategy {
	print_msg "No strategy is being applied...." 2 1 | echolog;
	kubectl apply -f config/kube.yml
}

function recreate {
	print_msg "Recreate strategy is being applied...." 2 1 | echolog;
	kubectl apply -f config/kube-recreate.yml
	print_msg "Recreate strategy applied!" 3 1 | echolog;
}

function rolling {
	print_msg "Rolling update strategy is being applied..." 2 1 | echolog;
	kubectl apply -f config/kube-rolling.yml
	print_msg "Rolling Update strategy applied!" 3 1 | echolog;
}

function blue_green {
	print_msg "Blue green strategy is being applied..." 2 1 | echolog;
	kubectl apply -f config/kube-deployment-blue-v1.yml
	kubectl apply -f config/kube-service-blue-v1.yml
	kubectl apply -f config/kube-deployment-green-v2.yml
	kubectl apply -f config/kube-service-green-v2.yml
	kubectl apply -f config/kube-deployment-blue-v2.yml
	kubectl apply -f config/kube-service-blue-v2.yml
	kubectl delete deployment.apps/k8s-service-demo-0.0.1 service/k8s-service-demo-green
	print_msg "Blue Green strategy applied!" 3 1 | echolog;
}

function canary {
	print_msg "Canary startegy is being applied..." 2 1 | echolog;
	print_msg "Canary strategy applied!" 3 1 | echolog;
}

#initializing the log is mandatory.
if ! [[ "$strategy" =~ ^(no|rolling|bluegreen|canary)$ ]]; then
	print_msg "Invalid Strategy. Select any one from recreate/rolling/bluegreen/canray" 1 1 | echolog;
fi

case "${strategy}" in
	recreate)   recreate ;;
    rolling)    rolling ;;
    bluegreen)  blue_green ;;
    canary)     canary ;;
    *)       echo "Illegal option -s ${strategy}, kube-manage -h for help."
             exit 1
             ;;
esac
