#!/bin/bash

docker build -t $TF_VAR_PRIVATE_REGISTRY --build-arg CONTROLLER_IP=$TF_VAR_ctrl_ip --build-arg CONTROLLER_URL=https://$TF_VAR_ctrl_fqdn --build-arg API_KEY=$TF_VAR_API_KEY --build-arg STORE_UUID=True --build-arg LOCATION=$TF_VAR_LOCATION .
docker push $TF_VAR_PRIVATE_REGISTRY

