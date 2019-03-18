## Zero Downtime Deployments

### Introduction

Zero Downtime Deployments are a significant feature of the Cloud Platform, that bring a host of advantages.

### Rolling Updates

Rolling updates introduce the ability to update an application without any downtime.

A rolling update works by ensuring there is always one extra Pod than the maximum number stated in the deployment.

The new deployment is applied incrementally, usually one to two Pods at a time until all Pods are running the latest version. How the deployment is rolled out, can be configured by the user. More information about configuring a rolling update can be found [here](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/).

If an application is exposed publicly, traffic will only be routed to the available Pods. However, this is only the case if the user configured `readinessProbes` correctly. This is a large topic, so more information can be found [here](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/).

#### The Major Advantage

Where rolling updates really brings benefit is the enabling of Continuous Integration and Continuous Delivery.

The ability to constantly update your application, with zero downtime, brings a host of benefits.

#### Further Reading

If you'd like to read more in-depth into rolling updates, then Kubernetes has some great documentation [here](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/).

#### Readiness/Liveness probes and SSL in Rails applications

For zero downtime deployments, you will need a readiness probe in your application, so that the cluster knows when your container is ready to receive traffic. You will also need a liveness probe, so that the cluster knows if it needs to restart your container after a crash.

SSL will be terminated outside of your pod, so your probes will need to respond to HTTP requests. However, Ruby on Rails applications are sometimes configured to only respond to HTTPS traffic (by adding `config.force_ssl = true` in the `config/environments/production.rb` file).

In this case, the application will respond to any HTTP request with a redirect status code, asking the requester to resend the request to the equivalent HTTPS URL. This will cause your probes to fail, because the redirect will not be followed.

To fix this, the probe needs to tell the application that it is an HTTPS request, even though it isn't, so that the application will process the request rather than sending a redirect response. You can do this by adding some HTTP headers to your probe definitions like this:

```
readinessProbe:
  httpGet:
    path: /ping.json
    port: 3000
    httpHeaders:
      - name: X-Forwarded-Proto
        value: https
      - name: X-Forwarded-Ssl
        value: "on"
```

This will send an HTTP request to `/ping.json`, but the rails application will respond as if it is HTTPS, and your probe should work as expected. This works for both readiness and liveness probes.

