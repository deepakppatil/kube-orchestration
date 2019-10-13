# Kubernetes Service Example with K8s in Google Kubernetes Engine (GKE)

Table of Contents
=================

   * [Table of Contents](#table-of-contents)
      * [Prerequisite](#prerequisite)
      * [Create Spring Boot app](#create-spring-boot-app)
      * [Create Docker image](#create-docker-image)
      * [Run the Docker image](#run-the-docker-image)
      * [Login to the K8s Cluster](#login-to-the-k8s-cluster)
      * [Kubernetes Commands](#kubernetes-commands)
         * [List Pods](#list-pods)
         * [List Deployments](#list-deployments)
         * [List Services](#list-services)
         * [Deploy an image](#deploy-an-image)
         * [Expose Load Balancer](#expose-load-balancer)
         * [Scale deployments](#scale-deployments)
      * [K8s using YAML](#k8s-using-yaml)
         * [Deployment YML used](#deployment-yml-used)
         * [Service YML used](#service-yml-used)
         * [Commands to Create/Update](#commands-to-createupdate)
         * [Command to retrieve logs](#command-to-retrieve-logs)
      * [Deployment Strategies](#deployment-strategies)
         * [Recreate Strategy](#recreate-strategy)
         * [Rolling Update Strategy](#rolling-update-strategy)
         * [Blue Green Deployment](#blue-green-deployment)
            * [Commands](#commands)
      * [Canary Deployments](#canary-deployments)
         * [Type 1](#type-1)
            * [Commands](#commands-1)
         * [Type 2](#type-2)
            * [Commands](#commands-2)
      * [Project Details](#project-details)
         * [Dependencies](#dependecies)
         * [Configuration](#configuration)
         * [Alternatives](#alternatives)

## Prerequisite
Using gcloud shell, configure following properties


## Login to gcoud

`gcloud auth login`


## Export project id

`export PROJECT_ID=k8s-service-demo`


## Set the project name in glcloud 

`gcloud config set project k8s-service-demo`


## Enable gcloud image registry

`gcloud auth configure-docker`
`gcloud components install docker-credential-gcr`

         
## Create Spring Boot app
You can use the sample project which I have in here.

`git clone https://github.com/deepakppatil/kube-orchestration.git`

## Create Docker image
Command to create docker image using Google JIB plugin

`./mvnw com.google.cloud.tools:jib-maven-plugin:build -Dimage=gcr.io/$PROJECT_ID/k8s-service-demo:0.0.1`

## Run the Docker image
Command to run the docker image which we created in the previous step

`docker run -ti --rm -p 8080:8080 gcr.io/$PROJECT_ID/k8s-service-demo:0.0.1`

## Login to the K8s Cluster
Command to login to the K8s cluster from Cloud Shell

`gcloud container clusters get-credentials k8s-cluster-2 --zone  us-central1-a`

## Kubernetes Commands
### List Pods
`kubectl get pods`

### List Deployments
`kubectl get deployments`

### List Services
`kubectl get services`

### Deploy an image
`kubectl run k8s-service-demo --image=gcr.io/$PROJECT_ID/k8s-service-demo:0.0.1 --port=8080`

### Expose Load Balancer
`kubectl expose deployment k8s-service-demo --type=LoadBalancer --port=8080`

### Scale deployments
`kubectl scale deployment k8s-service-demo --replicas=3`


## K8s using YAML

### Deployment YML used
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-service-demo
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: k8s-service-demo
    spec:
      containers:
        - name: k8s-service-demo
          image: 'gcr.io/k8s-service-demo/kube-orchestration:0.0.1'
          ports:
            - containerPort: 8080
```

### Service YML used
```
apiVersion: v1
kind: Service
metadata:
  name: k8s-service-demo
  labels:
    name: k8s-service-demo
spec:
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  selector:
    app: k8s-service-demo
  type: LoadBalancer
```

### Commands to Create/Update
- `kubectl apply -f deployment.yml`
- `kubectl apply -f service.yml`

### Command to retrieve logs
`kubectl logs <POD_NAME>`
- Pod Name can be retrived using `kubectl get pods`


## Deployment Strategies

There are several different types of deployment strategies you can take advantage of depending on your goal. For example, you may need to roll out changes to a specific environment for more testing, or a subset of users/customers or you may want to do some user testing before making a feature 'Generally Available'. 


### Recreate Strategy

In this type of very simple deployment, all of the old pods are killed all at once and get replaced all at once with the new ones.

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-service-demo
spec:
  replicas: 3
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: k8s-service-demo
    spec:
      containers:
        - name: k8s-service-demo
          image: 'gcr.io/k8s-service-demo/k8s-service-demo:0.0.1'
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: k8s-service-demo
  labels:
    name: k8s-service-demo
spec:
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  selector:
    app: k8s-service-demo
  type: LoadBalancer
```

### Rolling Update Deployment Strategy

The rolling deployment is the standard default deployment to Kubernetes. It works by slowly, one by one, replacing pods of the previous version of your application with pods of the new version without any cluster downtime. 
A rolling update waits for new pods to become ready via your readiness probe before it starts scaling down the old ones. If there is a problem, the rolling update or deployment can be aborted without bringing the whole cluster down. In the YAML definition file for this type of deployment, a new image replaces the old image.


```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
   name: k8s-service-demo
spec:
   replicas: 3
   strategy:
      type: RollingUpdate
      rollingUpdate:
         maxUnavailable: 0
         maxSurge: 1
   template:
      metadata:
         labels:
            app: k8s-service-demo
      spec:
         containers:
         -  name: k8s-service-demo
            image: gcr.io/k8s-service-demo/k8s-service-demo:0.0.1
            ports:
            -  containerPort: 8080
            readinessProbe:
               httpGet:
                  path: /demo
                  port: 8080
               initialDelaySeconds: 5
               periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
   name: k8s-service-demo
   labels:
      name: k8s-service-demo
spec:
   ports:
   -  port: 8080
      targetPort: 8080
      protocol: TCP
   selector:
      app: k8s-service-demo
   type: LoadBalancer
```

### Blue Green Deployment

In a blue/green deployment strategy (sometimes referred to as red/black) the old version of the application (green) and the new version (blue) get deployed at the same time. When both of these are deployed, users only have access to the green; whereas, the blue is available to your QA team for test automation on a separate service or via direct port-forwarding.

- kube-deployment-blue-v1.yml

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-service-demo-v1
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    metadata:
      labels:
        app: k8s-service-demo
        version: "v1"
    spec:
      containers:
        - name: k8s-service-demo
          image: 'gcr.io/k8s-service-demo/k8s-service-demo:0.0.1'
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /demo
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
```
- kube-service-blue-v1.yml

```
apiVersion: v1
kind: Service
metadata:
  name: k8s-service-demo
  labels:
    name: k8s-service-demo
    version: "v1"
spec:
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  selector:
    app: k8s-service-demo
    version: "v1"
  type: LoadBalancer
```

- kube-deployment-green-v2.yml

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-service-demo-v2
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    metadata:
      labels:
        app: k8s-service-demo
        version: "v2"
    spec:
      containers:
        - name: k8s-service-demo
          image: 'gcr.io/k8s-service-demo/k8s-service-demo:0.0.2'
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /demo
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
```
- kube-service-green-v2.yml

```
apiVersion: v1
kind: Service
metadata:
  name: k8s-service-demo-green
  labels:
    name: k8s-service-demo-green
    version: "v2"
spec:
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  selector:
    app: k8s-service-demo
    version: "v2"
  type: LoadBalancer
```

- kube-deployment-blue-v2.yml

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-service-demo-v2
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
  template:
    metadata:
      labels:
        app: k8s-service-demo
        version: "v2"
    spec:
      containers:
        - name: k8s-service-demo
          image: 'gcr.io/k8s-service-demo/k8s-service-demo:0.0.2'
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /demo
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
```

- kube-service-blue-v2.yml

```
apiVersion: v1
kind: Service
metadata:
  name: k8s-service-demo
  labels:
    name: k8s-service-demo
    version: "v2"
spec:
  ports:
    - port: 8080
      targetPort: 8080
      protocol: TCP
  selector:
    app: k8s-service-demo
    version: "v2"
  type: LoadBalancer
```

#### Commands
- `kubectl apply -f kube-deployment-blue-v1.yml`
- `kubectl apply -f kube-service-blue-v1.yml`
- `kubectl apply -f kube-deployment-green-v2.yml`
- `kubectl apply -f kube-service-green-v2.yml`
- `kubectl apply -f kube-deployment-blue-v2.yml`
- `kubectl apply -f kube-service-blue-v2.yml`
- `kubectl delete deployment.apps/k8s-service-demo-v1 service/k8s-service-demo-green`


## Canary Deployments

Canary deployments are a bit like blue/green deployments, but are more controlled and use a more ‘progressive delivery’ phased-in approach. There are a number of strategies that fall under the umbrella of canary including: dark launches, or A/B testing.

A canary is used for when you want to test some new functionality typically on the backend of your application. Traditionally you may have had two almost identical servers: one that goes to all users and another with the new features that gets rolled out to a subset of users and then compared. When no errors are reported, the new version can gradually roll out to the rest of the infrastructure.

While this strategy can be done just using Kubernetes resources by replacing old and new pods, it is much more convenient and easier to implement this strategy with a service mesh like Istio.

As an example, you could have two different manifests checked into Git: a GA tagged 0.1.0 and the canary, tagged 0.2.0. By altering the weights in the manifest of the Istio virtual gateway, the percentage of traffic for both of these deployments is managed.

`Example yaml coming soon`

## Project Details

### Dependencies
- Spring Boot - 2.2.0-M1
- H2 Database - 1.4.197

### Configuration
`spring.main.lazy-initialization` is set to `false` by default. This can be set to `true` to enable Lazy Initialization in the Spring Boot Project.

### Alternatives
- `http://localhost:8080/demo` - Uses `DemoController` and `DemoService` which can be marked manually as `@Demo` for specific Beans