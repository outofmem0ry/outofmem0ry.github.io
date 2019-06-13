---
layout: post
title:  "Kubernetes for Beginners"
date:   2017-12-07
author: "@jpetazzo"
tags: [beginner, linux, operations, kubernetes, developer]
categories: beginner
terms: 2
---

*Based on a workshop originally written by [Jérôme Petazzoni](http://container.training/) with contributions from [many others](https://github.com/jpetazzo/container.training/graphs/contributors)*

## Introduction
In this hands-on workshop, you will learn the basic concepts of Kubernetes. You will do that through interacting with Kubernetes through the command line terminals on the right. Ultimately you will deploy the sample applications [Dockercoins](https://github.com/dockersamples/dockercoins) on worker nodes.

## Getting Started

Your cluster is set up!

### What's this application?
* It is a DockerCoin miner! 💰🐳📦🚢

* No, you can't buy coffee with DockerCoins

* How DockerCoins works:

  * `worker` asks to `rng` to generate a few random bytes

  * `worker` feeds these bytes into `hasher`

  * and repeat forever!

  * every second, `worker` updates `redis` to indicate how many loops were done

  * `webui` queries `redis`, and computes and exposes "hashing speed" in your browser

### Getting the application source code
We've created a sample application to run for parts of the workshop. The application is in the [dockercoins](https://github.com/dockersamples/dockercoins) repository.

Let's look at the general layout of the source code:

there is a Compose file `docker-compose.yml` ...

... and 4 other services, each in its own directory:

`rng` = web service generating random bytes

`hasher` = web service computing hash of POSTed data

`worker` = background process using `rng` and `hasher`

`webui` = web interface to watch progress


* We will clone the GitHub repository

* The repository also contains scripts and tools that we will use through the workshop

  ```.term1
  git clone https://github.com/dockersamples/dockercoins
  ```

(You can also fork the repository on GitHub and clone your fork if you prefer that.)

## Kubernetes concepts

* Kubernetes is a container management system

* It runs and manages containerized applications on a cluster

* What does that really mean?

### Basic things we can ask Kubernetes to do

* Start 5 containers using image `atseashop/api:v1.3`

* Place an internal load balancer in front of these containers

* Start 10 containers using image `atseashop/webfront:v1.3`

* Place a public load balancer in front of these containers

* It's Black Friday (or Christmas), traffic spikes, grow our cluster and add containers

* New release! Replace my containers with the new image `atseashop/webfront:v1.4`

* Keep processing requests during the upgrade; update my containers one at a time

### Other things that Kubernetes can do for us

* Basic autoscaling

* Blue/green deployment, canary deployment

* Long running services, but also batch (one-off) jobs

* Overcommit our cluster and evict low-priority jobs

* Run services with stateful data (databases etc.)

* Fine-grained access control defining what can be done by whom on which resources

* Integrating third party services (service catalog)

* Automating complex tasks (operators)

## First contact with `kubectl`

* `kubectl` is (almost) the only tool we'll need to talk to Kubernetes

* It is a rich CLI tool around the Kubernetes API (Everything you can do with `kubectl`, you can do directly with the API)

* You can also use the `--kubeconfig` flag to pass a config file

* Or directly `--server`, `--user`, etc.

* `kubectl` can be pronounced "Cube C T L", "Cube cuttle", "Cube cuddle"...

### `kubectl get`

* Let's look at our Node resources with kubectl get!

* Look at the composition of our cluster:

  ```.term1
  kubectl get node
  ```
* These commands are equivalent

  ```
  kubectl get no
  kubectl get node
  kubectl get nodes
  ```

### Obtaining machine-readable output

* `kubectl get` can output JSON, YAML, or be directly formatted

* Give us more info about the nodes:

  ```.term1
  kubectl get nodes -o wide
  ```

* Let's have some YAML:
  ```.term1
  kubectl get no -o yaml
  ```
  See that kind: List at the end? It's the type of our result!

### (Ab)using `kubectl` and `jq`

* It's super easy to build custom reports

* Show the capacity of all our nodes as a stream of JSON objects:
  ```.term1
  kubectl get nodes -o json |
        jq ".items[] | {name:.metadata.name} + .status.capacity"
  ```

### What's available?

* `kubectl` has pretty good introspection facilities

* We can list all available resource types by running `kubectl get`

* We can view details about a resource with:
  ```
  kubectl describe type/name
  kubectl describe type name
  ```

* We can view the definition for a resource type with:
  ```
  kubectl explain type
  ```

Each time, `type` can be singular, plural, or abbreviated type name.

### Services

* A service is a stable endpoint to connect to "something" (In the initial proposal, they were called "portals")

* List the services on our cluster:

  ```.term1
  kubectl get services
  ```

This would also work:

  ```
    kubectl get svc
  ```

There is already one service on our cluster: the Kubernetes API itself.

### ClusterIP services

* A `ClusterIP` service is internal, available from the cluster only

* This is useful for introspection from within containers

* Try to connect to the API.
  * `-k` is used to skip certificate verification
  * Make sure to replace 10.96.0.1 with the CLUSTER-IP shown by `$ kubectl get svc`

  ```
  curl -k https://10.96.0.1
  ```

The error that we see is expected: the Kubernetes API requires authentication.

### Listing running containers

* Containers are manipulated through pods

* A pod is a group of containers:

  * running together (on the same node)

  * sharing resources (RAM, CPU; but also network, volumes)

* List pods on our cluster:

  ```.term1
  kubectl get pods
  ```
*These are not the pods you're looking for*. But where are they?!?

### Namespaces

* Namespaces allow us to segregate resources

* List the namespaces on our cluster with one of these commands:

  ```.term1
  kubectl get namespaces
  ```

  either of these would work as well:

  ```
  kubectl get namespace
  kubectl get ns
  ```

*You know what ... This `kube-system` thing looks suspicious.*

### Accessing namespaces
* By default, `kubectl` uses the `default` namespace

* We can switch to a different namespace with the `-n` option

* List the pods in the `kube-system` namespace:
  ```.term1
  kubectl -n kube-system get pods
  ```
*Ding ding ding ding ding!*

## Running our first containers on Kubernetes

* First things first: we cannot run a container

* We are going to run a pod, and in that pod there will be a single container

* In that container in the pod, we are going to run a simple ping command

* Then we are going to start additional copies of the pod

### Starting a simple pod with `kubectl run`

* We need to specify at least a name and the image we want to use

* Let's ping `8.8.8.8`, Google's public DNS

  ```.term1
  kubectl run pingpong --image alpine ping 8.8.8.8
  ```

* OK, what just happened?

### Behind the scenes of `kubectl run`

* Let's look at the resources that were created by `kubectl run`

* List most resource types:

  ```.term1
  kubectl get all
  ```

We should see the following things:

* `deploy/pingpong` (the *deployment* that we just created)
* `rs/pingpong-xxxx` (a *replica set* created by the deployment)
* `po/pingpong-yyyy` (a *pod* created by the replica set)

### What are these different things?

* A *deployment* is a high-level construct

  * allows scaling, rolling updates, rollbacks

  * multiple deployments can be used together to implement a [canary deployment](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)

  * delegates pods management to *replica sets*

* A *replica set* is a low-level construct

  * makes sure that a given number of identical pods are running

  * allows scaling

  * rarely used directly

* A *replication controller* is the (deprecated) predecessor of a replica set

### Our `pingpong` deployment

* `kubectl run` created a *deployment*, `deploy/pingpong`

* That deployment created a *replica set*, `rs/pingpong-xxxx`

* That *replica set* created a *pod*, `po/pingpong-yyyy`

* We'll see later how these folks play together for:

  * scaling

  * high availability

  * rolling updates

### Viewing container output

* Let's use the `kubectl logs` command

* We will pass either a *pod name*, or a *type/name*
(E.g. if we specify a deployment or replica set, it will get the first pod in it)

* Unless specified otherwise, it will only show logs of the first container in the pod
(Good thing there's only one in ours!)

* View the result of our ping command:

  ```.term1
  kubectl logs deploy/pingpong
  ```

### Streaming logs in real time
* Just like `docker logs`, `kubectl logs` supports convenient options:

  * `-f/--follow` to stream logs in real time (à la tail `-f`)

  * `--tail` to indicate how many lines you want to see (from the end)

  * `--since` to get logs only after a given timestamp

* View the latest logs of our ping command:

  ```.term1
  kubectl logs deploy/pingpong --tail 1 --follow
  ```

### Scaling our application

* We can create additional copies of our container (or rather our pod) with `kubectl scale`

* Scale our pingpong deployment:

  ```.term1
  kubectl scale deploy/pingpong --replicas 8
  ```

> Note: what if we tried to scale `rs/pingpong-xxxx`? We could! But the *deployment* would notice it right away, and scale back to the initial level.

### Resilience

* The deployment pingpong watches its replica set

* The replica set ensures that the right number of pods are running

* What happens if pods disappear?

* In a separate window, list pods, and keep watching them:
```.term1
kubectl get pods -w
```

  `Ctrl-C` to terminate watching.

* If you wanted to destroy a pod, you would use this pattern where `yyyy` was the identifier of the particular pod:
```
kubectl delete pod pingpong-yyyy
```

### What if we wanted something different?
* What if we wanted to start a "one-shot" container that *doesn't* get restarted?

* We could use `kubectl run --restart=OnFailure` or `kubectl run --restart=Never`

* These commands would create *jobs* or *pods* instead of *deployments*

* Under the hood, `kubectl run` invokes "generators" to create resource descriptions

* We could also write these resource descriptions ourselves (typically in YAML),
and create them on the cluster with `kubectl apply -f` (discussed later)

* With `kubectl run --schedule=`..., we can also create *cronjobs*

### Viewing logs of multiple pods

* When we specify a deployment name, only one single pod's logs are shown

* We can view the logs of multiple pods by specifying a *selector*

* A selector is a logic expression using *labels*

* Conveniently, when `you kubectl run somename`, the associated objects have a `run=somename` label

* View the last line of log from all pods with the `run=pingpong` label:

  ```.term1
  kubectl logs -l run=pingpong --tail 1
  ```

* Unfortunately, `--follow` cannot (yet) be used to stream the logs from multiple containers.

### Clean-up

* Clean up your deployment by deleting `pingpong`

  ```.term1
  kubectl delete deploy/pingpong
  ```

## Exposing containers

* `kubectl expose` creates a *service* for existing pods

* A *service* is a stable address for a pod (or a bunch of pods)

* If we want to connect to our pod(s), we need to create a *service*

* Once a service is created, `kube-dns` will allow us to resolve it by name (i.e. after creating service `hello`, the name `hello` will resolve to something)

* There are different types of services, detailed on the following slides:

`ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`

## Basic service types

* `ClusterIP` (default type)

  a virtual IP address is allocated for the service (in an internal, private range)
  this IP address is reachable only from within the cluster (nodes and pods)
  our code can connect to the service using the original port number

* `NodePort`

  a port is allocated for the service (by default, in the 30000-32768 range)
  that port is made available on all our nodes and anybody can connect to it
  our code must be changed to connect to that new port number

These service types are always available.

Under the hood: `kube-proxy` is using a userland proxy and a bunch of `iptables` rules.

### More service types

* `LoadBalancer`
  * an external load balancer is allocated for the service
  * the load balancer is configured accordingly (e.g.: a `NodePort` service is created, and the load balancer sends traffic to that port)

* `ExternalName`

  * the DNS entry managed by `kube-dns` will just be a `CNAME` to a provided record
  * no port, no IP address, no nothing else is allocated

### Running containers with open ports

* Since ping doesn't have anything to connect to, we'll have to run something else

* Start a bunch of ElasticSearch containers:
```.term1
kubectl run elastic --image=elasticsearch:2 --replicas=4
```

* Watch them being started:

  ```.term1
  kubectl get pods -w
  ```

The `-w` option "watches" events happening on the specified resources.

Note: please DO NOT call the service `search`. It would collide with the TLD.

### Exposing our deployment

* We'll create a default `ClusterIP` service

* Expose the ElasticSearch HTTP API port:

  ```.term1
  kubectl expose deploy/elastic --port 9200
  ```

* Look up which IP address was allocated:

  ```.term1
  kubectl get svc
  ```

### Services are layer 4 constructs

* You can assign IP addresses to services, but they are still *layer 4* (i.e. a service is not an IP address; it's an IP address + protocol + port)

* This is caused by the current implementation of `kube-proxy` (it relies on mechanisms that don't support layer 3)

* As a result: *you have to* indicate the port number for your service

* Running services with arbitrary port (or port ranges) requires hacks (e.g. host networking mode)

### Testing our service

* We will now send a few HTTP requests to our ElasticSearch pods

* Let's obtain the IP address that was allocated for our service, *programatically*:

  {% raw %}
  ```.term1
  IP=$(kubectl get svc elastic -o go-template --template '{{ .spec.clusterIP }}')
  ```
  {% endraw %}

* Send a few requests:

  ```.term1
  curl http://$IP:9200/
  ```

Our requests are load balanced across multiple pods.

### Clean up

* We're done with the `elastic` deployment, so let's clean it up

  ```.term1
  kubectl delete deploy/elastic
  ```

## Our app on Kube

### What's on the menu?
In this part, we will:

  * **build** images for our app,

  * **ship** these images with a registry,

  * **run** deployments using these images,

  * expose these deployments so they can communicate with each other,

  * expose the web UI so we can access it from outside.

### The plan
* Build on our control node (`node1`)

* Tag images so that they are named `$USERNAME/servicename`

* Upload them to a Docker Hub

* Create deployments using the images

* Expose (with a `ClusterIP`) the services that need to communicate

* Expose (with a `NodePort`) the WebUI

### Setup

* In the first terminal, set an environment variable for your [Docker Hub](https://hub.docker.com) user name. It can be the same [Docker Hub](https://hub.docker.com) user name that you used to log in to the terminals on this site.

  ```
  export USERNAME=YourUserName
  ```

* Make sure you're still in the `dockercoins` directory.

  ```.term1
  pwd
  ```

### A note on registries

* For this workshop, we'll use [Docker Hub](https://hub.docker.com). There are a number of other options, including two provided by Docker.

* Docker also provides:
  * [Docker Trusted Registry](https://docs.docker.com/datacenter/dtr/2.4/guides/) which adds in a lot of security and deployment features including security scanning, and role-based access control.
  * [Docker Open Source Registry](https://docs.docker.com/registry/).

### Docker Hub

* [Docker Hub](https://hub.docker.com) is the default registry for Docker.

  * Image names on Hub are just `$USERNAME/$IMAGENAME` or `$ORGANIZATIONNAME/$IMAGENAME`.

  * [Official images](https://docs.docker.com/docker-hub/official_repos/) can be referred to as just `$IMAGENAME`.

  * To use Hub, make sure you have an account. Then type `docker login` in the terminal and login with your username and password.

* Using Docker Trusted Registry, Docker Open Source Registry is very similar.

  * Image names on other registries are `$REGISTRYPATH/$USERNAME/$IMAGENAME` or `$REGISTRYPATH/$ORGANIZATIONNAME/$IMAGENAME`.

  * Login using `docker login $REGISTRYPATH`.

### Building and pushing our images

<!-- TODO: Fix default registry URL to username in dockercoins.yml -->
* We are going to use a convenient feature of Docker Compose

* Go to the `stacks` directory:

  ```.term1
  cd ~/dockercoins/stacks
  ```

* Build and push the images:

  ```.term1
  docker-compose -f dockercoins.yml build
  docker-compose -f dockercoins.yml push
  ```

Let's have a look at the dockercoins.yml file while this is building and pushing.

```
version: "3"
services:
  rng:
    build: dockercoins/rng
    image: ${USERNAME}/rng:${TAG-latest}
    deploy:
      mode: global
  ...
  redis:
    image: redis
  ...
  worker:
    build: dockercoins/worker
    image: ${USERNAME}/worker:${TAG-latest}
    ...
    deploy:
      replicas: 10
```

> Just in case you were wondering ... Docker "services" are not Kubernetes "services".

### Deploying all the things
* We can now deploy our code (as well as a redis instance)

* Deploy `redis`:

  ```.term1
  kubectl run redis --image=redis
  ```

* Deploy everything else:

  ```.term1
  for SERVICE in hasher rng webui worker; do
    kubectl run $SERVICE --image=$USERNAME/$SERVICE -l app=$SERVICE
  done
```

### Is this working?
* After waiting for the deployment to complete, let's look at the logs!

* (Hint: use `kubectl get deploy -w` to watch deployment events)

* Look at some logs:

  ```.term1
  kubectl logs deploy/rng
  kubectl logs deploy/worker
  ```

🤔 `rng` is fine ... But not `worker`.

💡 Oh right! We forgot to `expose`.

### Exposing services

### Exposing services internally

* Three deployments need to be reachable by others: `hasher`, `redis`, `rng`

* `worker` doesn't need to be exposed

* `webui` will be dealt with later

* Expose each deployment, specifying the right port:

  ```.term1
  kubectl expose deployment redis --port 6379
  kubectl expose deployment rng --port 80
  kubectl expose deployment hasher --port 80
  ```

### Is this working yet?
* The `worker` has an infinite loop, that retries 10 seconds after an error

* Stream the worker's logs:

  ```.term1
  kubectl logs deploy/worker --follow
  ```

(Give it about 10 seconds to recover)

* We should now see the `worker`, well, working happily.

### Exposing services for external access

* Now we would like to access the Web UI

* We will expose it with a `NodePort` (just like we did for the registry)

* Create a `NodePort` service for the Web UI:

  ```.term1
  kubectl create service nodeport webui --tcp=80 --node-port=30001
  ```

* Check the port that was allocated:

  ```.term1
  kubectl get svc
  ```

### Accessing the web UI

* We can now connect to *any node*, on the allocated node port, to view the web UI

Click on [this link](/){:data-term=".term2"}{:data-port="30001"}

*Alright, we're back to where we started, when we were running on a single node!*

## Security implications of `kubectl apply`

* When we do `kubectl apply -f <URL>`, we create arbitrary resources

* Resources can be evil; imagine a `deployment` that ...

  * starts bitcoin miners on the whole cluster

  * hides in a non-default namespace

  * bind-mounts our nodes' filesystem

  * inserts SSH keys in the root account (on the node)

  * encrypts our data and ransoms it

  * ☠️☠️☠️

### `kubectl apply` is the new `curl | sh`
* `curl | sh` is convenient

* It's safe if you use HTTPS URLs from trusted sources

* `kubectl apply -f` is convenient

* It's safe if you use HTTPS URLs from trusted sources

* It introduces new failure modes

* Example: the official setup instructions for most pod networks

## Scaling a deployment

* We will start with an easy one: the `worker` deployment

  ```.term1
  kubectl get pods

  kubectl get deployments
  ```

* Now, create more `worker` replicas:

  ```.term1
  kubectl scale deploy/worker --replicas=10
  ```

* After a few seconds, the graph in the web UI should show up. (And peak at 10 hashes/second, just like when we were running on a single one.)