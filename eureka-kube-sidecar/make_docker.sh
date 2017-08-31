#!/bin/bash
# USAGE:  $1 = docker registry repository prefix - e.g. cypress, qa, etc.
#
NAME_OF_THING=eureka-kube-sidecar
DR_RP=${1:-stevenacoffman}
img="${DR_RP}/${NAME_OF_THING}:latest"
docker build -t ${img} .
docker push ${img}
