### Simple Kubernetes Example Service and deployment

This is a simple example of a service and deployment.

The Kubernetes service is of type NodePort, and it is randomly assigned a cluster external port in the 30000 - 32767 range.

The deployment will create a replica set, which will have a single pod, and the pod will have two containers, hello-from-kube and eureka-kube-sidecar.

#### hello-from-kube

This runs the minimal (2.5 MB) docker image [crccheck/hello-world](https://hub.docker.com/r/crccheck/hello-world/) but the source code is [provided here](https://github.com/crccheck/docker-hello-world) if you wish to customize it. It is a very minimal, stupid simple web server.

#### eureka-kube-sidecar

This container is an example of the sidecar pattern. It is a simple bash/jq script that will:

 + query the kubernetes API
 + discover the nodeport
 + register the service with Eureka
 + Send application instance heartbeat every 30 seconds

### Create Kubernetes resources

```bash
kubectl create -f ./hello-from-kube.yaml
```

### Replacing Kubernetes resources
```bash
kubectl delete deployments, svc hello-from-kube
sleep 30
kubectl create -f ./hello-from-kube.yaml
```
**NOTE**: If you explicitly set a particular NodePort, it takes some minutes to de-register from Kubernetes so that it can be re-used, even after the service is destroyed.

### Warning

:warning: You must alter the ENVIRONMENT and DOMAIN in the hello-from-kube.yaml to match your environment (test, prod, etc.) and domain name (probably not example.com).
