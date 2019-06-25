# Troubleshooting guide
## Overview
This document intends to give you an idea of potential troubleshooting tips and techniques to investigate and resolve application issues on the Cloud Platform. The Kubernetes project also offers a resource on [troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/troubleshooting/) so we will attempt to avoid overlap. 

## Contents

### My pod shows `CreateContainerConfigError` after deployment
#### Scenario
You have deployed an application to the Cloud Platform and its status shows `CreateContainerConfigError` (you can get the status by running `kubect get pods -n <namespace>`). 
#### Cause
There are a number of reasons why this error will appear but the most probable cause is a missing secret or environment variable.
#### Troubleshooting
To investigate this issue you'll want to investigate the events of your pod. Run `kubectl -n <namespace> describe <pod_name>`. In the section titled `Events` you'll have something similar to:
```
Events:
  Type     Reason     Age                    From                                                   Message
  ----     ------     ----                   ----                                                   -------
  Normal   Scheduled  54m                    default-scheduler                                      Successfully assigned myapplication-namespace/myapplication to worker-node
  Warning  Failed     49m (x8 over 53m)      kubelet, worker-node  Error: Couldn't find key postgresUser in Secret myapplication-dev/myapplication
```
*Note* you can also find this out using `kubectl -n <namespace> get events`
#### Solution
Ensure all secrets and environment variables have been defined.  
