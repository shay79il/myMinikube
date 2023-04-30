#!/usr/bin/env bash
set -e
set -u

function minikube_start () {
  minikube start --driver=kvm2 --cpus=2 --memory=2g --nodes=3
  minikube addons enable ingress
}

function label_nodes () {
  local SELECTOR="!node-role.kubernetes.io/control-plane"
  local node_list
  node_list=$(kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers --selector=$SELECTOR)
  echo "$node_list" | xargs -n1 -I {} kubectl label nodes {} node-role.kubernetes.io/worker=""
}

function install_prometheus () {
  k create ns monitoring
  local VALUES_PATH

  # https://github.com/prometheus-community/helm-charts/issues/2420
  VALUES_PATH="$HOME/.minikube/my_minikube/values.yaml"
  helm install my-prometheus prometheus-community/prometheus -n monitoring -f "$VALUES_PATH"
}

# function remove_docker_images () {
  # minikube ssh -n <node-name>
  # docker images | grep prom | tr -s ' ' | cut -d ' ' -f3 | xargs docker rmi
# }

function deploy_prometheus_ingress () {
  k apply -f "$HOME/.minikube/my_minikube/prometheus_ingress.yaml"
}


minikube_start
label_nodes
install_prometheus
deploy_prometheus_ingress