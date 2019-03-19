## Getting Application Metrics into Prometheus

Prometheus collects metrics from monitored targets by scraping metrics HTTP endpoints on these targets. There are two ways to create a metrics endpoint. The first is when the metrics endpoint is embedded within the application referred to as `instrumentation`. The second is when the metrics endpoint is part of a deployed process that bridges the gap between Prometheus and systems that do not export metrics in the prometheus format, this is called an `exporter`.

The following exporters are installed as part of the Cloud Platform cluster build:

- kubeEtcd
- kubeApiServer
- kubeDns
- kubeControllerManager
- kubeScheduler
- kube-state-metrics
- nodeExporter
- kubelet

Click [here](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exporters.md) for a list of exporters and client libraries listed on the official Prometheus Github repo.


### Instrumentation of The Cloud-Platform Reference Application
The [Cloud Platform Reference Application](https://github.com/ministryofjustice/cloud-platform-reference-app) has `instrumentation` setup using [django-prometheus](https://github.com/korfuri/django-prometheus). The default install steps were followed which created a metrics endpoint.

See screenshot below of how the metrics endpoint looks on a browser:
![Image of metrics](https://raw.githubusercontent.com/ministryofjustice/cloud-platform-user-docs/master/images/metrics-endpoint.png)


### Create a Service to expose Pods

Scraping an exporter or separate metrics port requires a service that targets the Pod(s) of the exporter or application.

Example:

```yaml
kind: Service
apiVersion: v1
metadata:
  name: my-app-service
  labels:
    app: my-app
spec:
  selector:
    app: my-app
  ports:
  - protocol: TCP
    port: 8000
    targetPort: 8000
    name: metrics
  type: NodePort
```

### Create a Service-Monitor
A `ServiceMonitor` is a resource the Prometheus Operator introduces for Kubernetes that describes the set of targets to be monitored by Prometheus

Service Monitor Architecture
![Image of Service-Monitor Architecture](https://raw.githubusercontent.com/ministryofjustice/cloud-platform-user-docs/master/images/service-monitor-arch.png)


Example:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    interval: 15s
```

More detailed information about service-monitors can be found [here](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/running-exporters.md)

### NetworkPolicy for Monitoring Namespace

By default, all connections from outside a namespace are blocked, therefore a network policy is required for the `monitoring` namespace to be able to connect into an application namespace to scrape the metrics endpoint.

Example:

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-prometheus-scraping
  namespace: my-app-namespace
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          component: monitoring
```
You can view your current NetworkPolices with the following command:

```sh
kubectl -n <namespace> get networkpolicies
```

### Advisory note: Applications configured to use multiple processes

If you're using a pre-forking web server (like unicorn or puma for Ruby, or gunicorn for Python) and have it configured to use multiple processes, then you need to use a Prometheus client library which supports exporting metrics from multiple processes. Not all the official clients do that. If you don't use a library which supports this, then requests to `/metrics` could be served by any of the processes, which would mean Prometheus sees inconsistent data on each scrape
