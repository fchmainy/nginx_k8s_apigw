CONTROLLER_FQDN=$(awk -F '"' '/controller_fqdn=/ { print $2 }' install.sh)
echo "${CTRL_IP} ${CONTROLLER_FQDN} ${ENV_CONTROLLER_URL#*//}"
echo "${CTRL_IP} ${CONTROLLER_FQDN} ${ENV_CONTROLLER_URL#*//}" >> /etc/hosts

export HOSTNAME="$(hostname -f)"
export CONTROLLER_URL=https://$CONTROLLER_FQDN

# Authenticate to controller with credentials in order to get the Session Token
curl -sk -c cookie.txt -X POST --url 'https://'$CONTROLLER_FQDN'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$CTRL_USERNAME"'","password": "'"$CTRL_PASSWORD"'"}}'

# First, let's get the APIKey. it will be useful to onboard the instances onto the controller
apikey=$(curl -X GET -b cookie.txt -sk -H "Content-Type: application/json" https://$CONTROLLER_FQDN/api/v1/platform/global | jq .currentStatus.agentSettings.apiKey)
echo "here is my controller API Key: $apikey"

# ------ Install NGINX Controller Agent

export API_KEY=$ENV_CONTROLLER_API_KEY
#export API_KEY=$apikey
echo $API_KEY >>logs.txt
echo $LOCATION >> logs.txt
echo $SERVICE >> logs.txt
echo $CONTROLLER_FQDN >> logs.txt
echo $HOSTNAME >> logs.txt
sleep 5
echo "installing on location $LOCATION for hostname $HOSTNAME"
sh ./install.sh -l $LOCATION -i $HOSTNAME --insecure
service controller-agent stop
sleep 5
sh ./install.sh -l $LOCATION -i $HOSTNAME --insecure



# ------- Register to the Controller

# Create Environment
echo "create environment"
curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt -X POST -d '{"metadata":{"name":"'$SERVICE'"}}' --header 'Content-Type: application/json' --url $CONTROLLER_URL/api/v1/services/environments

sleep $(shuf -i 1-10 -n 1)
curl -sk -c cookie.txt -X POST --url 'https://'$CONTROLLER_FQDN'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$CTRL_USERNAME"'","password": "'"$CTRL_PASSWORD"'"}}'

gwExists=$(curl -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$CONTROLLER_FQDN'/api/v1/services/environments/'$SERVICE'/gateways/'$GATEWAY --write-out '%{http_code}' --silent --output /dev/null)
echo $gwExists

# if the gateway does not exist, we are creating it, otherwise we add the instance reference to the gateway.
if [ $gwExists -ne 200 ]
then
	echo "Gateway does not exist"
	envsubst < gateways.json > gwPayload.json
	cat
else
	echo "Gateway exists... adding instance to gateway"
	curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$CONTROLLER_FQDN'/api/v1/services/environments/'$SERVICE'/gateways/'$GATEWAY -o update.json
	jq '.desiredState.ingress.placement.instanceRefs += [{"ref": "/infrastructure/locations/'$LOCATION'/instances/'$HOSTNAME'"}]' update.json > gwPayload.json

fi
upsertgw=$(curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt -X PUT -d @gwPayload.json --header 'Content-Type: application/json' --url https://$CONTROLLER_FQDN/api/v1/services/environments/$SERVICE/gateways/$GATEWAY)
echo $upsertgw

