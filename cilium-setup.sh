#!/bin/bash

images="kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f"
cluster_name="cluster0"
config_file="cilium-config.yaml"

setup_clusters=$( kind create cluster --name ${cluster_name} --image ${images} --config ${config_file} )

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
sudo rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}


HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
sudo rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}


cilium=$( 

cilium install  --version 1.18.6  --set kubeProxyReplacement=true \
  --set operator.prometheus.enabled=true \
  --set operator.prometheus.namespace=monitor \
  --set bgpControlPlane.enabled=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set gatewayAPI.enabled=true \
  --set l7Proxy=true 

)


echo "install cilium : $cilium"
echo "setup cluster : $setup_clusters"


while true; do

    check_nodes=$(kubectl get nodes | grep "cluster" | grep "Ready" | awk '{print $1 "  " $2}')

    check_pods=$(kubectl get pods -n kube-system | grep "cilium" | grep "Running" | awk '{print $1 "  " $3}' )  


    if [[  $check_nodes  == *"Ready"*   &&   $check_pods  == *"Running"*  ]]; then
        echo "All nodes are Ready and all pods are Running...."
        break
        else
        echo "Waiting for nodes to be Ready and pods to be Running ...."
        sleep 900  # Wait for 900s  equavalent to 15m  before checking again
    fi


done

# Setup kube-prometheus-stack

create_namespace=$( kubectl create namespace monitor  )
echo "create namespace : $create_namespace"

setup_kube_prometheus_stack=$(

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

)

update_repo=$(

  helm repo update
  
)

echo "update repo : $update_repo"

install_kube_prometheus_stack=$(
  
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version 80.14.3 -n monitor

)

# Output status for kube-prometheus-stack setup

touch output_kube_prometheus_stack.txt

chmod 600 output_kube_prometheus_stack.txt

echo "setup kube-prometheus-stack : $setup_kube_prometheus_stack"  >> output_kube_prometheus_stack.txt

echo "install kube-prometheus-stack : $install_kube_prometheus_stack" >> output_kube_prometheus_stack.txt


while true; do

    monitor_pods=$(kubectl get pods -n monitor | grep "prometheus"| grep "grafana" | grep "Running" | awk '{print $1 "  " $3}' )


    if [[  $monitor_pods  == *"Running"*  ]]; then
        echo "All pods are Running...."
        break
        else
        echo "Waiting for pods to be Running ...."
        sleep 900  # Wait for 900s  equavalent to 15m  before checking again
    fi


done

# Setup Gateway API

setup_gateway_api=$(

  kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml

)

echo "setup gateway api : $setup_gateway_api "

# check gateway api 

check_gateway_api=$( kubectl explain gatewayclass  )

echo "Gateway API  : using the command  with : $check_gateway_api "

# Check Cilium status

cilium_status=$( cilium status --wait  )

echo "Cilium status : $cilium_status "