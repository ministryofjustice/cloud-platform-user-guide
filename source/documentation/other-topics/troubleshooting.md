### Troubleshooting guide

#### Overview
This document intends to give you an idea of potential troubleshooting tips and techniques to investigate and resolve application issues on the Cloud Platform. The Kubernetes project also offers a resource on [troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/troubleshooting/) so we will attempt to avoid overlap. 

Throughout this document we will refer to terms such as <pod_name> and <namespace>, it is assumed you'll know how to gather this information using the `kubectl get` commands.

#### Contents

  - [My pod shows 'CreateContainerConfigError' after deployment](#my-pod-shows-createcontainerconfigerror-after-deployment)
  - [My pod shows 'CrashLoopBackOff' after deployment](#my-pod-shows-crashloopbackoff-after-deployment)
  - [My pod shows 'ImagePullBackOff' after deployment](#my-pod-shows-imagepullbackoff-after-deployment)
  - [I get the error 'container is unhealthy, it will be killed and re-created’](#i-get-the-error-39-container-is-unhealthy-it-will-be-killed-and-re-created-39)

#### My pod shows 'CreateContainerConfigError' after deployment

##### Scenario
You have deployed an application to the Cloud Platform and its status shows `CreateContainerConfigError` (you can get the status by running `kubect get pods -n <namespace>`). 

##### Cause
There are a number of reasons why this error will appear but the most probable cause is a missing secret or environment variable.

##### Troubleshooting
To investigate this issue you'll want to look at the events of your pod. Run `kubectl -n <namespace> describe <pod_name>`, in the section titled `Events` you'll have something similar to:

```
Events:
  Type     Reason     Age                    From                                                   Message
  ----     ------     ----                   ----                                                   -------
  Normal   Scheduled  54m                    default-scheduler                                      Successfully assigned myapplication-namespace/myapplication to worker-node
  Warning  Failed     49m (x8 over 53m)      kubelet, worker-node  Error: Couldn't find key postgresUser in Secret myapplication-dev/myapplication
```

> Note: you can also find this out using `kubectl -n <namespace> get events`

##### Solution
Ensure all secrets and environment variables have been defined.

#### My pod shows `CrashLoopBackOff` after deployment

##### Scenario
Following the deployment of your application, you receive a status of `CrashLoopBackOff` when querying the pods in your namespace with `kubectl get pods -n <namespace>`.

##### Cause
A `CrashloopBackOff` means that you have a pod starting, crashing, starting again, and then crashing again.

A PodSpec has a restartPolicy field with possible values Always, OnFailure, and Never which applies to all containers in a pod. The default value is Always and the restartPolicy only refers to restarts of the containers by the kubelet on the same node (so the restart count will reset if the pod is rescheduled in a different node). Failed containers that are restarted by the kubelet are restarted with an exponential back-off delay (10s, 20s, 40s …) capped at five minutes, and is reset after ten minutes of successful execution. This is an example of a PodSpec with the restartPolicy field:

```
apiVersion: v1
kind: Pod
metadata:
  name: dummy-pod
spec:
  containers:
    - name: dummy-pod
      image: ubuntu
  restartPolicy: Always
```

The main causes of `Crashloopback` are:

- The application inside the container keeps crashing.
- Some type of parameters of the pod or container have been configured incorrectly.
- An error has been made when deploying Kubernetes.

##### Troubleshooting
As this issue is quite vague, you'll want to start by checking STDOUT using the command `kubectl -n <namespace> logs <pod_name>`. This should give you a clear understanding of whether the application has crashed. If this is the case please review the application code and the solution will become evident.

##### Solution
Fix application or misconfiguration errors.

#### My pod shows `ImagePullBackOff` after deployment

##### Scenario
You have deployed an application to the Cloud Platform and its status shows `ImagePullBackOff` (you can get the status by running `kubect get pods -n <namespace>`).

##### Cause
This error is caused by a misconfiguration in your deployment, usually an invalid image `tag:`.

##### Troubleshooting
Again, utilising the `kubectl -n <namespace> describe <pod_name>` command you can see that the pod has failed to pull down the correct image:
```
  Normal   Pulling    10m (x4 over 12m)    kubelet, worker-node  pulling image "redis:foobar"
  Warning  Failed     10m (x4 over 12m)    kubelet, worker-node  Error: ErrImagePull
```

##### Solution
This can be corrected by amending the `image` in your deployment.

#### I get the error 'container is unhealthy, it will be killed and re-created'

##### Situation
Your pod appears to be jumping between an `error` and `ready` state. You describe the pod and get an error `container is unhealthy, it will be killed and re-created` 

##### Cause
Kubernetes provides two essential features called Liveness Probes and Readiness Probes. Essentially, Liveness/Readiness Probes will periodically perform an action (e.g. make an HTTP request, open a tcp connection, or run a command in your container) to confirm that your application is working as intended.

If the Liveness Probe fails, Kubernetes will kill your container and create a new one. If the Readiness Probe fails, that Pod will not be available as a Service endpoint, meaning no traffic will be sent to that Pod until it becomes Ready.

##### Troubleshooting
Using the log output (`kubectl -n <namespace> <pod_name>`) you should see the cause of your Probe failure. 

There are likely three possibilities:

  -  Your Probes are now incorrect - Did the health URL change?
  -  Your Probes are too sensitive - Does your application take a while to start or respond?
  -  Your application is no longer responding correctly to the Probe - Is your database misconfigured?

##### Solution
Once a change has been made to either your application or Probe, a fresh deployment should succeed.
