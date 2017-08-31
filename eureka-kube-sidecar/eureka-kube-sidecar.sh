#!/bin/bash

APP_NAME=${APP_NAME:-HELLO-FROM-KUBE}
ENVIRONMENT=${ENVIRONMENT:-test}
DOMAIN=${DOMAIN:-example.com}
if [[ -z $HOSTNAME ]]; then
    echo
    echo "HOSTNAME was not set, so going to give up"
    exit 1
fi
HOST_IP_ADDRESS=${HOSTNAME:-PITY_THE_FOOL_WHO_USES_STATIC_IP}
LOWERCASE_APP_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
NAMESPACE_FILE=/var/run/secrets/kubernetes.io/serviceaccount/namespace
if [ ! -f $NAMESPACE_FILE ]; then
    echo "NAMESPACE_FILE File not found!"
else
    echo "NAMESPACE_FILE is found"
fi
NAMESPACE=$(<$NAMESPACE_FILE)

echo "KUBERNETES_SERVICE_HOST: ${KUBERNETES_SERVICE_HOST}"
echo "KUBERNETES_PORT_443_TCP_PO‌​RT: ${KUBERNETES_SERVICE_PORT_HTTPS}"
echo "APP_NAME: ${APP_NAME}"
echo "ENVIRONMENT: ${ENVIRONMENT}"
echo "DOMAIN: ${DOMAIN}"
echo "LOWERCASE_APP_NAME: ${LOWERCASE_APP_NAME}"
echo "NAMESPACE: ${NAMESPACE}"

KUBE_TOKEN_FILE=/var/run/secrets/kubernetes.io/serviceaccount/token

if [ ! -f $KUBE_TOKEN_FILE ]; then
    echo "KUBE_TOKEN File not found!"
else
    echo "KUBE_TOKEN is found"
fi

SERVICE_ACCOUNT_CA_CERT_FILE=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

if [ ! -f $SERVICE_ACCOUNT_CA_CERT_FILE ]; then
    echo "SERVICE_ACCOUNT_CA_CERT_FILE File not found!"
else
    echo "SERVICE_ACCOUNT_CA_CERT_FILE File is found."
fi

KUBE_TOKEN=$(<$KUBE_TOKEN_FILE)

function log_nodeport_request() {
    echo "curl -sS --cacert $SERVICE_ACCOUNT_CA_CERT_FILE -H \"Authorization: Bearer KUBE_TOKEN\" https://${KUBERNETES_SERVICE_HOST}/api/v1/namespaces/${NAMESPACE}/services/$LOWERCASE_APP_NAME | jq '.spec.ports[] | select(.name==\"http\") | .nodePort'"
    curl -S -v --cacert $SERVICE_ACCOUNT_CA_CERT_FILE -H "Authorization: Bearer ${KUBE_TOKEN}" https://${KUBERNETES_SERVICE_HOST}/api/v1/namespaces/${NAMESPACE}/services/$LOWERCASE_APP_NAME
}

function get_nodeport() {
    curl -sS --cacert $SERVICE_ACCOUNT_CA_CERT_FILE -H "Authorization: Bearer ${KUBE_TOKEN}" https://${KUBERNETES_SERVICE_HOST}/api/v1/namespaces/${NAMESPACE}/services/$LOWERCASE_APP_NAME | jq '.spec.ports[] | select(.name=="http") | .nodePort'
}


if [[ -z $APP_EXT_PORT ]]; then
    echo
    echo "Attempting to lookup nodeport"
    echo "$(log_nodeport_request)"
    echo
    APP_EXT_PORT=$(get_nodeport)
fi
echo "Using NODEPORT ${APP_EXT_PORT}"

INSTANCE_ID=$(uuidgen)
echo $INSTANCE_ID $APP_NAME

curl -v -X POST \
-H "Accept: application/xml" \
-H "Content-type: application/xml" \
http://eureka.${ENVIRONMENT}.${DOMAIN}/eureka/v2/apps/${LOWERCASE_APP_NAME} -d @- << EOF
<?xml version="1.0" ?>
<instance>
  <vipAddress>${LOWERCASE_APP_NAME}.${ENVIRONMENT}.${DOMAIN}</vipAddress>
  <leaseInfo>
    <renewalIntervalInSecs>30</renewalIntervalInSecs>
    <evictionDurationInSecs>90</evictionDurationInSecs>
  </leaseInfo>
  <securePort enabled="false">8443</securePort>
  <hostName>${HOSTNAME}</hostName>
  <secureVipAddress/>
  <app>${APP_NAME}</app>
  <homePageUrl>http://${HOST_IP_ADDRESS}:${APP_EXT_PORT}/</homePageUrl>
  <statusPageUrl>http://${HOST_IP_ADDRESS}:${APP_EXT_PORT}/</statusPageUrl>
  <healthCheckUrl>http://${HOST_IP_ADDRESS}:${APP_EXT_PORT}/healthcheck</healthCheckUrl>
  <ipAddr>${HOST_IP_ADDRESS}</ipAddr>
  <status>UP</status>
  <dataCenterInfo>
    <name>MyOwn</name>
  </dataCenterInfo>
  <region>default</region>
  <preferSameZone>False</preferSameZone>
  <port enabled="true">${APP_EXT_PORT}</port>
  <metadata>
      <instanceId>${INSTANCE_ID}</instanceId>
  </metadata>
</instance>
EOF

#Endless loop to maintain Eureka heartbeat
while true
do
  curl -v -X PUT "http://eureka.${ENVIRONMENT}.${DOMAIN}/eureka/v2/apps/${APP_NAME}/${HOSTNAME}:${INSTANCE_ID}"
  sleep 30
done

echo This is supposed to be unreachable by the way
exit 1
