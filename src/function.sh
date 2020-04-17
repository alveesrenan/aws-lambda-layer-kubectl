#!/bin/bash

# include the common-used shortcuts
# source commons.sh

# load .env.config cache and read previously used cluster_name
[ -f /tmp/.env.config ] && cat /tmp/.env.config && source /tmp/.env.config

function handler () {
    EVENT_DATA=$1
    echo "Event data:" $EVENT_DATA

    echo "Getting namespaces from k8s."
    kubectl get ns

    echo "Getting helm repositories."
    helm repo list

    echo "Installing helm chart."
    helm upgrade --install chartmuseum stable/chartmuseum

    RESPONSE="{\"statusCode\": 200, \"body\": \"Hello from Lambda! Version: 2\"}"
    echo $RESPONSE
}