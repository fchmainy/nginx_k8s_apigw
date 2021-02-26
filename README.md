# nginx_k8s_apigw
Deploying elastic N+ instances in kubernetes with onboarding on the NGINX Controller


## Description
The goal of this deployment model is to create and provide an API Management for microservices applications, leveraging the native Kubernetes mechanisms such as elasticity, rolling upgrades...

Kubernetes Micro-Services (MS) oftenly "consume" other KMS services as an API, whether it is throught RESTful services or using Protobuf (Protocol Buffers) through gRPC. In these case, it is important to have an hollistic API Management solution in order to :
- manage the lifecycle of your APIs, 
- the routing, 
- the service discovery, 
- API composition
- and the security of your MS-2-MS communications. 

<p align="center">
	<img width="200" src="docs/topology.png" alt="V1 logo">
</p>

This same concept (i.e. using the same code) can be applied to:
- shared API Gateways
- Dedicated API Gateways
- Side-Car API Gateways.


## Pre-requisites
- Helmv3 [installed](https://helm.sh/docs/intro/install/)
- a Container image registry (public or private / remote or local)
- a running kubernetes cluster (of course)

## Pre-tasks
### licensing
- get an nginx-repo cert and key and put it in the files directory.
I am very soon changing the build behavior so it gets the license directly from the controller.

### Setting environment variables
<i># Public Fully Qualified Domain Name for the Controller</i>
export TF_VAR_ctrl_fqdn=""
<i># Private IP Address of the Controller, so the instance can communicate locally</i>
export TF_VAR_ctrl_ip=""
<i># API Key for the build of the controller agent on the instance</i>
export TF_VAR_API_KEY=""
<i># Location of the instance in the controller. Should already be created.</i>
export TF_VAR_location=""
<i># Email address of the administrator on the controller to log in to the controller (used for the API)</i>
export TF_VAR_useremail=""
<i># Password of the administrator on the controller.</i>
export TF_VAR_ctrlpassword=""
<i># Environment where the instance gateway will be created</i>
export TF_VAR_ctrl_env=""
<i># Private Registry URL and path</i>
export TF_VAR_PRIVATE_REGISTRY=registry.gitlab.com/path

Note: as you can see, those are TF_VAR_ prefixed variables as i like to use them consistently across other projects (see my other nginx repos).

### Build and push the image to your registry
- build the container image and push it to your registry (see files/build.sh for an example)

<pre>
#!/bin/bash

docker build -t $TF_VAR_PRIVATE_REGISTRY --build-arg CONTROLLER_IP=$TF_VAR_ctrl_ip --build-arg CONTROLLER_URL=https://$TF_VAR_ctrl_fqdn --build-arg API_KEY=$TF_VAR_API_KEY --build-arg STORE_UUID=True --build-arg LOCATION=$TF_VAR_LOCATION .
docker push $TF_VAR_PRIVATE_REGISTRY 
</pre>

## API Gateway creation
using the provided helm chart, you can deploy and automatically onboard your api gateways on your APIM NGINX Controller:

in the following example, we are:
- deploying our API Gateway in the **hello** namespace
- only 1 replica of the pod
- the gitlab registry path, tags and secret of my private container image registry
- private IP\* and credentials of the NGINX Controller
- Environment and Gateway\*\* where the API Gw will be attached.
- ingress class and ingress host so the API Gateway Ingress Service is created with the appropriate Ingress Class.

<pre>
helm install apigw ./microapigw \
--set namespace=hello \
--set replicaCount=1 \
--set image.repository=registry.gitlab.com/<-ContainerImageRegistryPath->/apigw \
--set image.pullPolicy=Always \
--set image.imagePullSecretName=regcred \
--set image.tag=latest \
--set environment.ctrlFQDN=$TF_VAR_ctrl_fqdn \
--set environment.ctrlIP="10.1.1.4" \
--set environment.ctrlLOC=$TF_VAR_location \
--set environment.ctrlUSER=$TF_VAR_useremail \
--set environment.ctrlPASS=$TF_VAR_ctrlpassword \
--set environment.ctrlENV=$TF_VAR_ctrl_env \
--set environment.ctrlGW=apigw \
--set ingress.enable=true \
--set ingress.className=ingressclass1 \
--set ingress.host=apigw.f5demolab.org 

</pre>

<pre>
Notes:
- \*  a private IP is prefered to a public IP in a case of a public cloud as the agent controller install script will try to join the controller publicly known FQDN, so in a case of a public cloud deployment you will have to deal with security concerns by leaving your private realm, getting back through your Internet gateway and pass all the potential Security Groups and ACL checks.
- \*\*The first instance of the API Gateway will first, create the instance in the infrastructure list, then create the **service environment** and the **service gateway**  on the controller. Any new instances created from a **scaling out** events, will only join the existing environment and gateway and pull the latest working configuration.
</pre>



> :warning: This is just an individual proof of concept. Please provide any feedback or comment in the issues section of the repo.
