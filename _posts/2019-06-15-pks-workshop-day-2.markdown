---
layout: post
title:  "PKS Workshop - Day II"
date: 2019-06-13 17:00
author: "@outofmem0ry"
tags: [beginner, linux, operations, kubernetes, developer, pks]
categories: beginner
terms: 2
---

☸️🏃💪Your cluster is set up and running! ☸️🏃💪

## Getting access to the cluster

- Make sure you are logged into PKS api

  ```shell
  export LABNUM=
  export DOMAIN=
  
  pks login -a pks-$LABNUM.$DOMAIN -u alana \
  --ca-cert /var/tempest/workspaces/default/root_ca_certificate
  
  Password: ********
  API Endpoint: pks-$LABNUM.$DOMAIN
  User: alana
  ```

- Retrieve K8s cluster credentials

  ```shell
  pks get-credentials firstcluster
  
  Fetching credentials for cluster firstcluster.
  Password: ********
  Context set for cluster firstcluster.
  
  You can now switch between clusters by using:
  $kubectl config use-context <cluster-name>
  ```

## Starting with `kubectl`

- `kubectl` is a cli to interact with Kubernetes API
- You can also use the `--kubeconfig` flag to pass a config file
- Example `kubectl get componentstatuses`

  ```shell
  kubectl get componentstatuses
  NAME                 STATUS    MESSAGE             ERROR
  controller-manager   Healthy   ok
  scheduler            Healthy   ok
  etcd-0               Healthy   {"health":"true"}
  ```

## Nodes

Kubernetes nodes are separated into master nodes that contain processes like the K8s API server, controller, etc., which manage the cluster, and worker nodes where your containers will run.

```shell

kubectl get nodes
NAME                                   STATUS   ROLES    AGE    VERSION
6f3404ab-b928-456f-b2b9-219e67e360a3   Ready    <none>   3h3m   v1.12.7
f051c24e-58b1-4e6a-ae09-c293e779ff77   Ready    <none>   3h6m   v1.12.7
```

The node names displayed in the output above are bosh agent ids. You can check this by

```shell
bosh --column="Instance" --column="Agent Id" is --details \
-d service-instance_d9f12855-6247-4f03-b3d8-089882ec0ede

Using environment '10.aaa.bb.cc' as client 'ops_manager'

Task 69. Done

Deployment 'service-instance_d9f12855-6247-4f03-b3d8-089882ec0ede'

Instance                                           Agent ID
apply-addons/2fb2d3bd-eb8f-4ac2-82ac-0f3e515975ee  -
master/de7ecabd-ee23-4135-be81-2ecd38e43a0e        c799288d-7beb-4f67-8f47-7f732931e34d
worker/0c862126-b1e8-40cc-9ae4-45430a899862        6f3404ab-b928-456f-b2b9-219e67e360a3
worker/e33b8ab8-74c1-4594-a96a-43af2c6552fb        f051c24e-58b1-4e6a-ae09-c293e779ff77

4 instances

Succeeded
```

## Pods

- Simplest unit in the Kubernetes object model that you create or deploy
- Single container "one-container-per-Pod” model
- Multiple containers that need to work together ex, kube-dns
- Create and list pods

  ```shell
  kubectl run kuard --image=gcr.io/kuar-demo/kuard-amd64:1
  kubectl run --generator=deployment/apps.v1beta1 is DEPRECATED and will be removed in a future version. Use kubectl create instead.
  deployment.apps/kuard created
  
  kubectl get pods
  NAME                     READY   STATUS    RESTARTS   AGE
  kuard-5c8c4499d4-rvp4h   1/1     Running   0          9s
  ```

- Pods can be deployed using pos manifest that can be yaml or json.
- Get pod `yaml` definition.
  
  ```shell
  apiVersion: v1
  kind: Pod
  metadata:
    name: nginx
    labels:
      name: nginx
  spec:
    containers:
    - name: nginx
      image: nginx
      ports:
      - containerPort: 80
  ```

- Save the above yaml to a file and create pod from the manifest using `kubectl`

  ```shell
  kubectl apply -f nginx.yaml
  pod/nginx created
  ```

- Get pods
  
  ```shell
  kubectl get pods
  NAME                     READY   STATUS    RESTARTS   AGE
  kuard-5c8c4499d4-rvp4h   1/1     Running   0          9m27s
  nginx                    1/1     Running   0          8s
  ```

## Labels and Selectors

- Definition

  >Labels are key/value pairs that are attached to objects, such as pods. Labels are intended to be used to specify identifying attributes of objects that are meaningful and relevant to users, but do not directly imply semantics to the core system
  >Selector - Via a label selector, the client/user can identify a set of objects. The label selector is the core grouping primitive in Kubernetes.

The API currently supports two types of selectors: equality-based and set-based.

- Show labels for existing pods

  ```shell
  kubectl get pods --show-labels
  NAME                     READY   STATUS    RESTARTS   AGE     LABELS
  kuard-5c8c4499d4-rvp4h   1/1     Running   0          15m     pod-template-hash=5c8c4499d4,  run=kuard
  nginx                    1/1     Running   0          5m57s   name=nginx
  ```

- Using selectors
  
  ```shell
  kubectl get pods -l run=kuard
  NAME                     READY   STATUS    RESTARTS   AGE
  kuard-5c8c4499d4-rvp4h   1/1     Running   0          17m
  
  kubectl get pods -l name=nginx
  NAME    READY   STATUS    RESTARTS   AGE
  nginx   1/1     Running   0          8m39s
  ```

## Deployment

- Pods do not, by themselves, self-heal 💥. Single pod scheduled to a node that fails is deleted

  ```shell
  kubectl delete pod nginx
  pod "nginx" deleted
  ```

- There are higher level abstractions called Controllers that create and manage multiple pods
handles replication and self healing
- Examples of Controllers: `Deployment`, StatefulSet, DaemonSet
  
  ```shell
  kubectl get deployments
  NAME    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
  kuard   1         1         1            1           28m
  ```

- Delete the `kuard` pod
  
  ```shell
  kubectl delete pod kuard-5c8c4499d4-rvp4h
  pod "kuard-5c8c4499d4-rvp4h" deleted
  ```

- Deployment controller recreates it.

## Replicaset

- Let's increase the number of copies of pod running to `3`
  
  ```shell
  kubectl scale --replicas=3 deployment kuard
  deployment.extensions/kuard scaled
  
  kubectl get pods
  NAME                     READY   STATUS    RESTARTS   AGE
  kuard-5c8c4499d4-5j5vw   1/1     Running   0          6m30s
  kuard-5c8c4499d4-hgl6s   1/1     Running   0          6s
  kuard-5c8c4499d4-n9nnn   1/1     Running   0          6s
  ```

- Replicaset's responsibility is to maintain `n` replica of pods at a given time. Match the current state with the desired state
  
  ```shell
  kubectl get replicasets
  NAME               DESIRED   CURRENT   READY   AGE
  kuard-5c8c4499d4   3         3         3       45m
  ```

## Services

- What if the Pod fails and is in the process of being replaced?
- Agent capable of getting the traffic to the replacement pod(s)
- Service gets traffic from `outside world to a pod` or `from one pod to another`

### Service types

#### ClusterIP

- Default service type
- Only internal access, internally facing IP address
- IPs allocated from `Service Cluster CIDR range`
- Use cases: Internal app traffic, Internally exposed dashboard
- Example
  
  ```shell
  kubectl get service
  NAME         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   10.100.200.1   <none>        443/TCP   22h
  
  kubectl describe service kubernetes
  Name:              kubernetes
  Namespace:         default
  Labels:            component=apiserver
                     provider=kubernetes
  Annotations:       <none>
  Selector:          <none>
  `Type`:              `ClusterIP`
  IP:                10.100.200.1
  Port:              https  443/TCP
  TargetPort:        8443/TCP
  Endpoints:         10.aaa.bb.cc:8443
  Session Affinity:  None
  Events:            <none>
  ```

#### NodePort

- Static IP address accessible to outside world
- Opens a specific port on all the worker nodes
  
  ```shell
  kubectl expose deployment kuard \
  --type=NodePort \
  --port=8080 \
  --target-port=8080
  ```

- Getting the service details 
  
  ```shell
  kubectl get svc
  NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
  kuard        NodePort    10.100.200.141   <none>        8080:30385/TCP   7s
  kubernetes   ClusterIP   10.100.200.1     <none>        443/TCP          22h
  
  kubectl describe svc kuard
  Name:                     kuard
  Namespace:                default
  Labels:                   run=kuard
  Annotations:              <none>
  Selector:                 run=kuard
  Type:                     NodePort
  IP:                       10.100.200.141
  Port:                     <unset>  8080/TCP
  TargetPort:               8080/TCP
  NodePort:                 <unset>  30385/TCP
  Endpoints:                10.200.13.10:8080,10.200.13.11:8080,10.200.54.7:8080
  Session Affinity:         None
  External Traffic Policy:  Cluster
  Events:                   <none>
  ```

- Accessing the service
  - Get node details
  
    ```shell
    kubectl get nodes -o wide
    NAME                                   STATUS   ROLES    AGE   VERSION   INTERNAL-IP        EXTERNAL-IP    OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
    6f3404ab-b928-456f-b2b9-219e67e360a3   Ready    <none>   22h   v1.12.7   10.aaa.bb.cc       10.aaa.bb.cc   Ubuntu 16.04.6 LTS   4.15.0-50-generic   docker://18.6.3
    f051c24e-58b1-4e6a-ae09-c293e779ff77   Ready    <none>   22h   v1.12.7   10.aaa.bb.cc       10.aaa.bb.cc   Ubuntu 16.04.6 LTS   4.15.0-50-generic   docker://18.6.3
    ```

  - Access the service using `External-IP:NodePort`

#### LoadBalancer

- Spread traffic to pods
- Underlying cloud provider should support dynamic LB creation
- On vsphere, possible by using NSX-T

#### ExternalName

- Default service type
- No selectors, ports or endpoints
- Easiest and right way to access external services from your pods
- Use Cases: Access external services like Amazon RDS

## PKS Upgrade

- [Determine your upgrade path](https://docs.pivotal.io/pks/1-4/upgrade-pks.html#upgrade-path)
- [Upgrade precheck](https://docs.pivotal.io/pks/1-4/upgrade-pks.html#prepare)
- [Upgrade to Enterprise PKS v1.4.x](https://docs.pivotal.io/pks/1-4/upgrade-pks.html#upgrade-tile-1-4)
- Post upgrade
  - [Update PKS and Kubernetes CLIs](https://docs.pivotal.io/pks/1-4/upgrade-pks.html#update-clis)
  - [Verify the Upgrade](https://docs.pivotal.io/pks/1-4/upgrade-pks.html#verify-upgrade)
