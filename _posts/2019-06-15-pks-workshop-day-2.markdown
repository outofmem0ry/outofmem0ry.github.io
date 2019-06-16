---
layout: post
title:  "PKS Workshop - Day II"
date: 2019-06-13 17:00
author: "@outofmem0ry"
tags: [beginner, linux, operations, kubernetes, developer, pks]
categories: beginner
terms: 2
---

Your cluster is set up and running!

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

- The node names displayed in the output above are bosh agent ids

## Pods

## Labels

## Deployment

## Replicaset

## Services


#### Creating Naomi persona

This article will help you in [understanding the personas of Alana, Cody and Naomi within Pivotal Container Service (PKS)](https://community.pivotal.io/s/article/understanding-the-personas-of-alana-cody-and-naomi-within-pivotal-container-service-pks). We are going to use this persona to show some workflows related to Naomi later.

