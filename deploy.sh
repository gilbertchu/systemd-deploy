#!/bin/bash

source .env

_git_deploy() {
  if [ -n ${1:-''} ]; then
    git -C $remote_repo_path fetch
    git -C $remote_repo_path checkout $1
    if [ $? -ne 0 ]; then
      echo "Invalid branch, aborting deploy"
      return 1
    fi
  fi
  git -C $remote_repo_path rev-parse --abbrev-ref HEAD
  git -C $remote_repo_path pull
}

_systemd_activate() {
  sudo systemctl daemon-reload
  local is_enabled=$(sudo systemctl is-enabled $service_name)
  if [ "$is_enabled" = "disabled" ]; then
    sudo systemctl enable $service_name
  fi
  local is_active=$(sudo systemctl is-active $service_name)
  if [ $is_active = "active" ]; then
    sudo systemctl restart $service_name
  else
    sudo systemctl start $service_name
  fi
  echo "Sleeping 3 sec..."
  sleep 3
  sudo systemctl status $service_name
}

deploy() {
  echo "Updating and deploying"
  # scp -i $ssh_key_path $db_file_path $remote_user@$remote_host:$remote_repo_path
  ssh -T -i $ssh_key_path $remote_user@$remote_host "$(typeset -f _git_deploy); _git_deploy ${1:-'main'}"
}

systemd_activate() {
  echo "Updating service file and activating service"
  scp -i $ssh_key_path ~/repos/discord-craps/deployment/$service_name $remote_user@$remote_host:/etc/systemd/system/
  ssh -T -i $ssh_key_path $remote_user@$remote_host "$(typeset -f _systemd_activate); _systemd_activate"
}

start() {
  echo "Starting"
  ssh -T -i $ssh_key_path $remote_user@$remote_host "sudo systemctl start $service_name"
  ssh -T -i $ssh_key_path $remote_user@$remote_host "sudo systemctl is-active $service_name"
}

stop() {
  echo "Stopping"
  ssh -T -i $ssh_key_path $remote_user@$remote_host "sudo systemctl stop $service_name"
  ssh -T -i $ssh_key_path $remote_user@$remote_host "sudo systemctl is-active $service_name"
}

restart() {
  echo "Restarting"
  ssh -T -i $ssh_key_path $remote_user@$remote_host "sudo systemctl restart $service_name"
  ssh -T -i $ssh_key_path $remote_user@$remote_host "sudo systemctl is-active $service_name"
}

status() {
  ssh -T -i $ssh_key_path $remote_user@$remote_host "sudo systemctl is-active $service_name"
}

case $1 in
  stop) stop ;;
  start) start ;;
  restart) restart ;;
  status) status ;;
  systemd_activate) systemd_activate ;;
  -b) deploy $2 ;;
  *) deploy ;;
esac
