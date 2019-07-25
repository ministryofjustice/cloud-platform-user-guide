## Namespace/Container Request Limits

One of the most important tasks of a kubernetes cluster is to [arrange the different workloads][kube-scheduler] we want to run on it as efficiently as possible.

The smallest unit of work we ask the cluster to manage is a container, and in our case, the largest unit is a [namespace]. Scheduling these workloads across the [worker nodes] which comprise the cluster is a classic [packing problem], complicated by the fact that the cluster can't know in advance how much resource (memory and CPU) a container is going to need.

To help with this, we specify **request limits**. This article will use "request" because that's the official kubernetes term, but request is a slightly awkward term here. It might be better to think of "reserving" rather than requesting resources.

Essentially, a request limit says to kubernetes, "this thing is going to need this much memory and this much CPU in order to do its job." So, whenever it encounters a request limit, the [kube-scheduler] sets aside that amount of memory and CPU, and ring-fences it so that it's guaranteed to be available.

The other kind of limit in kubernetes are known as **hard limits**. These are important at runtime, as opposed to request limits, which are important for the scheduling decisions the cluster makes before your workloads start to run. From the name, it sounds as if these are limits that kubernetes will enforce, so that the workload will be terminated if it exceeds them. The reality is a little more nuanced. If the cluster has capacity available on the node where the workload is running, it will allow it to consume more resources than the hard limit specifies. But, it will flag the workload such that, if the node runs out of resources and kubernetes needs to evict pods, the pods from the offending workload will be first in line to be evicted.

For simplicity's sake, you can just think of a hard limit as meaning what it sounds like - the maximum amount your workload will be allowed to consume before bad things start to happen.

For the remainder of this article, we're only going to talk about request limits.

### Memory versus CPU

Memory and CPU are the two types of resources we need to consider, and we're going to pretend, for the rest of this article, as if they're handled in the same way. The truth is that they're not. If a workload tries to consume more memory than is available, it can bring down one or more cluster nodes, and cause significant failures. If a workload tries to consume more CPU than is available, it will simply not receive as much CPU time as it wants, and will be throttled.

This distinction doesn't really matter, for the purposes of this article, so we're going to pretend we can treat memory and CPU exactly the same.

### Namespace request limits

A namespace is the largest "unit of work" that the cluster needs to worry about.

When you create a namespace the [ResourceQuota] defines the request limits and hard limits on its resources. This [file][resource-quotas] defines the defaults we assign to new namespaces. The `requests.cpu` specifies the CPU resources, usually in [millicores] aka millicpus. `requests.memory` specifies the required memory, usually in [mebibytes].

These values represent the amount of CPU and memory that the cluster will **set aside as soon as this namespace is created**, regardless of whether or not those resources are actually being used.

This means it is possible to run out of cluster resources before any work is actually performed, just by requesting (i.e. reserving) capacity.

![Cluster namespace packing](../images/cluster-namespace-packing.png)

For this reason, we need to be conservative when assigned default request limits to namespaces. This won't prevent your namespace from accessing resources that it needs - that's what the hard limits are for - but a lower request limit will help us to use the capacity of the cluster more efficiently, to run everyone's workloads.

### Container request limits

The smallest unit of work the cluster cares about is a container.

Kubernetes workloads are generally defined in terms of [pods], where each pod defines a number of containers. Containers also have request limits and hard limits on the resources that will be set aside for them, or which they shouldn't exceed.

[Here][deployment-yaml] is an example of a deployment file which specifies limits for the container it launches.

Whenever the scheduler tries to schedule a pod, it reserves whatever request limits are specified for each container. If the deployment doesn't specify request limits, the default for the namespace will be used. This default comes from the namespace's [LimitRange]. In our case, the default we apply for new namespaces is specified [here][limit-range].

![Deployment one replica](../images/deployment-one-replica.png)

The diagram above shows a namespace with a deployment consisting of four containers. If the service team wanted to run multiple replicas of this deployment, the scheduler would not allow it, because the capacity set aside for the namespace is not enough to set aside the amount each of the containers say they want.

### Resources Requested versus Resources Used

So far, we've only been talking about what resources we are **requesting**, and it's clear that we can quickly run out of capacity in the cluster if we request too many resources. But, how closely does what we request match what we use?

We have created [this script][namespace-reporter] that you can run to see how your namespace is doing.

Here is the current result (25/07/19) from running the script against the `monitoring` namespace (where things like [prometheus] and [alert-manager] run)

```
$ ./bin/namespace-reporter.rb monitoring

Namespace: monitoring

Request limit:        CPU: 10000,     Memory: 24000
Requested:            CPU: 2215,      Memory: 13115

Num. containers:      58
Req. per-container:   CPU: 125,       Memory: 250

Resources in-use:     CPU: 363,       Memory: 6795

CPU values are in millicores (m). Memory values are in mebibytes (Mi).
```

As you can see, we're doing quite badly in terms of efficient usage of cluster resources. Inside the namespace, we're requesting 2215 millicores of CPU, but only using 363, and we're requesting 13115Mi of memory, but only using 6795Mi.

Worse still, we have a request limit of 10000m CPU and 24000Mi of memory. Those resources have been set aside for the monitoring namespace, and are not available to run any other workloads.

This pattern is repeated across all the namespaces in the cluster, and it's a problem. We can make the cluster bigger to get more capacity, and we have done so several times, but there are knock-on effects. The more cluster nodes we have, the harder the cluster control software has to work, and some functions get slower, or even stop working altogether, so more work has to be done to scale *those* up, and so on.

![Requested versus used](../images/requested-versus-used.png)

For this reason, we're going to do ongoing work to **right-size** both new and existing namespaces and their limit ranges, so that everyone benefits by having the cluster run their workloads efficiently and smoothly.

[namespace]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[kube-scheduler]: https://kubernetes.io/docs/concepts/scheduling/kube-scheduler/
[worker nodes]: https://kubernetes.io/docs/concepts/architecture/nodes/
[packing problem]: https://en.wikipedia.org/wiki/Packing_problems
[ResourceQuota]: https://kubernetes.io/docs/concepts/policy/resource-quotas/
[LimitRange]: https://kubernetes.io/docs/concepts/policy/limit-range/
[resource-quotas]: https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespace-resources/03-resourcequota.yaml
[limit-range]: https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespace-resources/02-limitrange.yaml
[millicores]: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/#meaning-of-cpu
[mebibytes]: https://en.wikipedia.org/wiki/Mebibyte
[pods]: https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/
[deployment-yaml]: https://raw.githubusercontent.com/ministryofjustice/fb-av/6cdba5db4e2feb440c7b6a303f241728b9cee5f8/deploy/fb-av-chart/templates/deployment.yaml
[namespace-reporter]: https://github.com/ministryofjustice/cloud-platform-environments/blob/master/bin/namespace-reporter.rb
[prometheus]: https://prometheus.io/
[alert-manager]: https://prometheus.io/docs/alerting/alertmanager/
