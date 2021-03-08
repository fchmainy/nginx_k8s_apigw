# export HOSTNAME="$(hostname -f)"
# export CTRL_FQDN=$(echo $ENV_CONTROLLER_URL | awk -F'https://' '{print $2}' | awk -F':8443' '{print $1}')

sleep $(shuf -i 1-10 -n 1)
# Authenticate to controller with credentials in order to get the Session Token
curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -c cookie.txt -X POST --url 'https://'$CTRL_FQDN'/api/v1/platform/login' --header 'Content-Type: application/json' --data '{"credentials": {"type": "BASIC","username": "'"$CTRL_USERNAME"'","password": "'"$CTRL_PASSWORD"'"}}'

# 1. Remove the instance from gateway
curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$SERVICE'/gateways/'$GATEWAY -o update.json
jq '.desiredState.ingress.placement.instanceRefs -= [{"ref": "/infrastructure/locations/'$LOCATION'/instances/'$HOSTNAME'"}]' update.json > $HOSTNAME.json

# cat $HOSTNAME.json

curl --connect-timeout 30 --retry 10 --retry-delay 5 -sk -b cookie.txt -c cookie.txt -X PUT -d @$HOSTNAME.json --header 'Content-Type: application/json' --url 'https://'$CTRL_FQDN'/api/v1/services/environments/'$SERVICE'/gateways/'$GATEWAY

# 2. Remove the instance from infrastructure
sleep $(shuf -i 1-10 -n 1)
curl --connect-timeout 30 --retry 10 --retry-delay 5  -sk -b cookie.txt -c cookie.txt  --header 'Content-Type: application/json' -X DELETE --url 'https://'$CTRL_FQDN'/api/v1/infrastructure/locations/'$LOCATION'/instances/'$HOSTNAME
